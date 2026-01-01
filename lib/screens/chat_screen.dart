import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int senderId;
  final int receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  Timer? _pollingTimer;

  Map<String, dynamic>? _analysis;      // 🔥 yeni eklendi
  Timer? _typingTimer;                  // 🔥 yeni eklendi

  Map<String, dynamic>? _aiSuggestion; // /complete sonucu
  bool _aiLoading = false;


  Color get _turquoise => const Color(0xFF008F9C);

  @override
  void initState() {
    super.initState();
    _loadMessages();

    // POLLING
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _checkNewMessages(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // LOAD MESSAGES
  // ----------------------------------------------------------
  Future<void> _loadMessages() async {
    final data = await ChatService()
        .fetchMessages(widget.senderId, widget.receiverId);

    setState(() {
      _messages = data.map<Map<String, dynamic>>((m) {
        return {
          "text": m["content"],
          "image": m["image_url"],
          "isMe": m["sender_id"] == widget.senderId,
          "time": _formatTime(m["created_at"]),
        };
      }).toList();
    });

    _scrollToBottom();
  }

  Future<void> _checkNewMessages() async {
    final latest = await ChatService()
        .fetchMessages(widget.senderId, widget.receiverId);

    final formatted = latest.map<Map<String, dynamic>>((m) {
      return {
        "text": m["content"],
         "image": m["image_url"], 
        "isMe": m["sender_id"] == widget.senderId,
        "time": _formatTime(m["created_at"]),
      };
    }).toList();

    if (formatted.length != _messages.length) {
      setState(() => _messages = formatted);
      _scrollToBottom();
    }
  }

  // ----------------------------------------------------------
  // TIME FORMAT
  // ----------------------------------------------------------
  String _formatTime(String? raw) {
    if (raw == null) return "";
    try {
      final dt = DateTime.parse(raw);
      return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }
  void _handleTyping(String text) {
    if (_typingTimer != null) {
      _typingTimer!.cancel();
    }

    _typingTimer = Timer(const Duration(seconds: 1), () async {
      if (text.trim().isEmpty) {
        setState(() => _analysis = null);
        return;
      }

      try {
        final result = await ApiService().predictMessage(
          text: text,
          senderId: widget.senderId,      // ✅ DOĞRU
          receiverId: widget.receiverId,  // ✅ DOĞRU
        );

        setState(() {
          _analysis = result;
        });
      } catch (e) {
        print("PREDICT ERROR: $e");
      }
    });
  }

  Future<void> _testComplete() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _aiLoading = true;
      _aiSuggestion = null;
    });

    try {
      final res = await ApiService().completeMessage(
        text: text,
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        receiverUsername: widget.receiverName,
      );

      debugPrint("COMPLETE RESPONSE => $res");

      setState(() {
        _aiSuggestion = res;
      });
    } catch (e) {
      debugPrint("COMPLETE ERROR => $e");
    } finally {
      setState(() => _aiLoading = false);
    }
  }



  // ----------------------------------------------------------
  // SEND MESSAGE
  // ----------------------------------------------------------
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // 🔥 AI panelini temizle
    setState(() {
      _analysis = null;
    });

    // Mesajı ekrana ekle
    setState(() {
      _messages.add({
        "text": text,
        "isMe": true,
        "time": _formatTime(DateTime.now().toString()),
      });
    });

    _messageController.clear();
    _scrollToBottom();

    await ChatService().sendMessage(
      widget.senderId,
      widget.receiverId,
      text,
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ----------------------------------------------------------
  // MESSAGE BUBBLE
  // ----------------------------------------------------------
  Widget _bubble(Map<String, dynamic> msg) {
    final isMe = msg["isMe"];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xffdcf8c6) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
              ),
            ),
            child: msg["image"] !=null
              ? Image.network(
                msg["image"],
                width: 200,
                fit:BoxFit.cover,
                )
                  : Text(msg["text"], style: const TextStyle(fontSize: 16)),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 12),
            child: Text(msg["time"], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          )
        ],
      ),
    );
  }

  // ----------------------------------------------------------

  // BUILD
  // ----------------------------------------------------------

  // TEXT OR IMAGE LOGIC
  // ----------------------------------------------------------
  Widget _buildMessageContent(Map<String, dynamic> msg) {
    if (msg["mediaType"] == "image" && msg["mediaUrl"] != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          msg["mediaUrl"],
          width: 220,
          height: 220,
          fit: BoxFit.cover,
        ),
      );
    }

    return Text(
      msg["text"] ?? "",
      style: const TextStyle(fontSize: 16),
    );
  }

  // ----------------------------------------------------------
// BUILD
// ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffefeae2),
      appBar: AppBar(
        backgroundColor: _turquoise,
        title: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            const SizedBox(width: 10),
            Text(widget.receiverName, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: Column(
        children: [
          // -------------------------------
          // MESSAGES
          // -------------------------------
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, i) => _bubble(_messages[i]),
            ),
          ),

          // -------------------------------
          // 1️⃣ AI TYPING ANALYSIS (/predict)
          // -------------------------------
          if (_analysis != null) _aiPanel(),

          // -------------------------------
          // 2️⃣ AI MESSAGE SUGGESTION (/complete)
          // -------------------------------
          if (_aiLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),

          if (_aiSuggestion != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "AI Message Suggestion",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),

                  // 🔹 Tap → input’a yaz (ACCEPT sayılmaz)
                  GestureDetector(
                    onTap: () {
                      final text = _aiSuggestion!["completion"];
                      _messageController.text = text;
                      _messageController.selection = TextSelection.fromPosition(
                        TextPosition(offset: text.length),
                      );
                    },
                    child: Text(
                      _aiSuggestion!["completion"] ?? "",
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 🔹 ACCEPT / REJECT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await ApiService().updateSuggestionStatus(
                            suggestionId: _aiSuggestion!["suggestion_id"],
                            accepted: false,
                          );
                          setState(() => _aiSuggestion = null);
                        },
                        child: const Text("Reject"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final text = _aiSuggestion!["completion"];

                          // 1️⃣ Input alanına yaz
                          _messageController.text = text;
                          _messageController.selection = TextSelection.fromPosition(
                            TextPosition(offset: text.length),
                          );

                          // 2️⃣ DB’ye ACCEPT gönder
                          await ApiService().updateSuggestionStatus(
                            suggestionId: _aiSuggestion!["suggestion_id"],
                            accepted: true,
                          );

                          // 3️⃣ Paneli kapat
                          setState(() => _aiSuggestion = null);
                        },
                        child: const Text("Accept"),
                      ),

                    ],
                  ),
                ],
              ),
            ),

          // -------------------------------
          // INPUT BAR
          // -------------------------------
          _inputBar(),
        ],
      ),
    );
  }




  // ----------------------------------------------------------
  // INPUT BAR
  // ----------------------------------------------------------
  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          // ➕ MEDIA
          IconButton(
            icon: Icon(Icons.add, color: _turquoise),
            onPressed: _openMediaSheet,
          ),

          // ✍️ TEXT INPUT
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: "Message",
                  border: InputBorder.none,
                ),
                onChanged: _handleTyping,
              ),
            ),
          ),

          // 🤖 AI TEST BUTTON (/complete)
          IconButton(
            icon: const Icon(Icons.smart_toy),
            color: _turquoise,
            onPressed: _aiLoading ? null : _testComplete,
          ),

          // 📤 SEND
          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              backgroundColor: _turquoise,
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }


  // ----------------------------------------------------------
  // MEDIA SHEET
  // ----------------------------------------------------------
  void _openMediaSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _mediaOption(Icons.camera_alt, "Camera", Colors.cyan, _captureImage),
              _mediaOption(Icons.photo, "Gallery", Colors.purple, _pickImage),
            ],
          ),
        );
      },
    );
  }

  Widget _mediaOption(
      IconData icon, String label, Color color, Future<void> Function() onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () async {
            Navigator.pop(context);
            await onTap();
          },
          child: CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 26),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ----------------------------------------------------------
  // IMAGE PICK
  // ----------------------------------------------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    // Önce ekranda hemen göster (local path)
    setState(() {
      _messages.add({
        "text": "",
        "image": picked.path,  // 🔥 TEMP DEĞİL → gerçek local dosya yolu
        "isMe": true,
        "time": _formatTime(DateTime.now().toString())
      });
    });

    _scrollToBottom();

    // Sonra backend’e yükle
    await ChatService().uploadMedia(
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      filePath: picked.path,
      mediaType: "image",
    );

  // Backend URL geldikten sonra doğru URL ile yeniden yükle
  _loadMessages();
}

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);

    if (picked == null) return;

      setState(() {
        _messages.add({
          "text": "",
          "image": picked.path,
          "isMe": true,
          "time": _formatTime(DateTime.now().toString())
        });
      });

      _scrollToBottom();

    await ChatService().uploadMedia(
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      filePath: picked.path,
      mediaType: "image",
    );

    _loadMessages();
  }


  Widget _aiPanel() {
    if (_analysis == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI Analysis",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          // 🔥 MESAJ STİLİ (ANLIK)
          if (_analysis!["style"] != null)
            Text(
              "• Message style: ${_analysis!["style"]}",
              style: const TextStyle(fontSize: 14),
            ),

          // 🔥 İLİŞKİ STİLİ (KARAR)
          if (_analysis!["relationship_style"] != null)
            Text(
              "• Conversation style: ${_analysis!["relationship_style"]}",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

          // ✅ SENTIMENT
          if (_analysis!["sentiment"] != null &&
              _analysis!["sentiment_confidence"] != null)
            Text(
              "• Sentiment: ${_analysis!["sentiment"]} "
                  "(${(_analysis!["sentiment_confidence"] * 100).toStringAsFixed(1)}%)",
              style: const TextStyle(fontSize: 14),
            ),

          // ✅ PUNCTUATION
          if (_analysis!["punctuation_fixed"] != null)
            Text(
              "• Fixed: ${_analysis!["punctuation_fixed"]}",
              style: const TextStyle(fontSize: 14),
            ),
        ],
      ),
    );
  }





}
