import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/color_helper.dart';
import 'group_info_screen.dart';
import '../services/socket_service.dart';

class ChatScreen extends StatefulWidget {
  final int senderId;
  final int receiverId;
  final String receiverName;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SocketService _socketService  = SocketService();

  bool _isOtherUserTyping = false;
  Timer? _stopTypingTimer;

  List<Map<String, dynamic>> _messages = [];

  Map<String, dynamic>? _analysis;      // 🔥 yeni eklendi
  Timer? _typingTimer;                  // 🔥 yeni eklendi

  Map<String, dynamic>? _aiSuggestion; // /complete sonucu
  bool _aiLoading = false;


  Color get _turquoise => const Color(0xFF008F9C);

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupSocket();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _stopTypingTimer?.cancel();
    _socketService.removeListeners();
    _socketService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  // ----------------------------------------------------------
  // LOAD MESSAGES
  // ----------------------------------------------------------
  Map<String, dynamic> _formatMessage(Map<String, dynamic> m) {
    final imagePath = m["file_path"] ?? m["image_url"];
    final timestamp = m["timestamp"] ?? m["created_at"];

    return {
      "sender_username": m["sender_username"],
      "text": m["content"] ?? "",
      "image": imagePath,
      "isMe": m["sender_id"] == widget.senderId,
      "time": _formatTime(timestamp?.toString()),
    };
  }

  Future<void> _loadMessages() async {
    final data = await ChatService().fetchMessages(
      widget.senderId,
      widget.isGroup ? 0 : widget.receiverId,
      groupId: widget.isGroup ? widget.receiverId : null,
    );

    setState(() {
      _messages = data.map<Map<String, dynamic>>((m) => _formatMessage(m)).toList();
    });

    _scrollToBottom();
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
    if (!widget.isGroup && text.trim().isNotEmpty) {
      _socketService.sendTyping(
        senderId: widget.senderId,
        receiverId: widget.receiverId,
      );
    }

    _typingTimer?.cancel();

    _typingTimer = Timer(const Duration(seconds: 1), () async {
      if (text.trim().isEmpty) {
        setState(() => _analysis = null);
        return;
      }

      try {
        final result = await ApiService().predictMessage(
          text: text,
          senderId: widget.senderId,
          receiverId: widget.receiverId,
        );

        setState(() {
          _analysis = result;
        });
      } catch (e) {
        print("PREDICT ERROR: $e");
      }
    });
  }

  void _setupSocket() {
  _socketService.connect();

  if (!widget.isGroup) {
    _socketService.joinPrivateRoom(widget.senderId, widget.receiverId);
  }

  _socketService.onNewMessage((data) {
    if (!mounted || data == null) return;

    final incomingSenderId = data["sender_id"];
    final incomingReceiverId = data["receiver_id"];
    final incomingGroupId = data["group_id"];

    final isCurrentPrivateChat = !widget.isGroup &&
        ((incomingSenderId == widget.senderId && incomingReceiverId == widget.receiverId) ||
         (incomingSenderId == widget.receiverId && incomingReceiverId == widget.senderId));

    final isCurrentGroupChat =
        widget.isGroup && incomingGroupId == widget.receiverId;

    if (!isCurrentPrivateChat && !isCurrentGroupChat) return;

    final newMessage = {
      "sender_username": data["sender_username"],
      "text": data["content"] ?? "",
      "image": data["file_path"] ?? data["image_url"],
      "isMe": incomingSenderId == widget.senderId,
      "time": _formatTime(
        data["timestamp"]?.toString() ?? DateTime.now().toIso8601String(),
      ),
    };

    setState(() {
      final alreadyExists = _messages.any((m) =>
          m["text"] == newMessage["text"] &&
          m["time"] == newMessage["time"] &&
          m["isMe"] == newMessage["isMe"]);

      if (!alreadyExists) {
        _messages.add(newMessage);
      }
    });

    _scrollToBottom();
  });

  _socketService.onTyping((data) {
    if (!mounted || data == null) return;

    if (data["sender_id"] == widget.senderId) return;

    setState(() {
      _isOtherUserTyping = true;
    });

    _stopTypingTimer?.cancel();
    _stopTypingTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isOtherUserTyping = false;
      });
    });
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

    setState(() {
      _analysis = null;
    });

    final localMessage = {
      "text": text,
      "isMe": true,
      "time": _formatTime(DateTime.now().toString()),
    };

    setState(() {
      _messages.add(localMessage);
    });

    _messageController.clear();
    _scrollToBottom();

    if (widget.isGroup) {
      _socketService.socket?.emit("send_message", {
        "sender_id": widget.senderId,
        "group_id": widget.receiverId,
        "content": text,
      });
    } else {
      _socketService.sendPrivateMessage(
        senderId: widget.senderId,
        receiverId: widget.receiverId,
        content: text,
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.isGroup && !isMe && msg["sender_username"] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      msg["sender_username"],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorHelper.getPastelColor(msg["sender_username"]),
                      ),
                    ),
                  ),
                msg["image"] != null
                    ? _buildImageWidget(msg["image"] as String)
                    : Text(msg["text"], style: const TextStyle(fontSize: 16)),
              ]
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 12),
            child: Text(msg["time"], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          )
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imagePath) {
    final isHttp = imagePath.startsWith("http://") || imagePath.startsWith("https://");
    final isDocs = imagePath.startsWith("docs/");

    if (isHttp || isDocs) {
      final url = isHttp ? imagePath : "${ChatService.baseUrl}/$imagePath";
      return Image.network(
        url,
        width: 200,
        fit: BoxFit.cover,
      );
    }

    return Image.file(
      File(imagePath),
      width: 200,
      fit: BoxFit.cover,
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
      resizeToAvoidBottomInset: true, // Klavyenin alanı daraltmasını sağlar
      backgroundColor: const Color(0xffefeae2),
      appBar: AppBar(
        backgroundColor: _turquoise,
        elevation: 1,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            if (widget.isGroup) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupInfoScreen(
                    groupId: widget.receiverId,
                    groupName: widget.receiverName,
                  ),
                ),
              ).then((_) => _loadMessages());
            }
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(widget.isGroup ? Icons.group : Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.isGroup 
                    ? "Tap for group info" 
                    : (_isOtherUserTyping ? "Yazıyor..." : "Çevrimiçi"),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),

      body: Column(
        children: [
          // 1. ÜST KISIM: Mesajlar ve üzerine binen AI Panelleri
          Expanded(
            child: Stack(
              children: [
                // Mesaj Listesi
                ListView.builder(
                  controller: _scrollController,
                  // ÖNEMLİ: AI Paneli açıkken mesajlar arkada kalmasın diye alt boşluk veriyoruz
                  padding: EdgeInsets.only(
                    bottom: (_analysis != null || _aiSuggestion != null) ? 180 : 12,
                    top: 12,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final msg = _messages[i];
                    return _bubble(msg);
                  },
                ),

                // 2. YÜZER AI PANELLERİ (Positioned ile listenin en altına sabitliyoruz)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // AI Analiz Paneli
                      if (_analysis != null) _aiPanel(),

                      // AI Yükleniyor Göstergesi
                      if (_aiLoading)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(),
                        ),

                      // AI Öneri Paneli
                      if (_aiSuggestion != null) _buildAiSuggestionFloatingPanel(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. ALT KISIM: Giriş Çubuğu (Yeri hiç değişmez, klavye kapanmaz)

          _inputBar(),
        ],
      ),
    );
  }

  // AI Öneri panelini temiz görünmesi için ayrı bir widget olarak tanımladım
  Widget _buildAiSuggestionFloatingPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50.withOpacity(0.98), // Hafif saydam ve şık
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, -2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AI Message Suggestion", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              final text = _aiSuggestion!["completion"];
              _messageController.text = text;
              _messageController.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
            },
            child: Text(_aiSuggestion!["completion"] ?? "", style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  await ApiService().updateSuggestionStatus(suggestionId: _aiSuggestion!["suggestion_id"], accepted: false);
                  setState(() => _aiSuggestion = null);
                },
                child: const Text("Reject"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final text = _aiSuggestion!["completion"];
                  _messageController.text = text;
                  await ApiService().updateSuggestionStatus(suggestionId: _aiSuggestion!["suggestion_id"], accepted: true);
                  setState(() => _aiSuggestion = null);
                },
                child: const Text("Accept"),
              ),
            ],
          ),
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
      receiverId: widget.isGroup ? 0 : widget.receiverId,
      groupId: widget.isGroup ? widget.receiverId : null,
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
      receiverId: widget.isGroup ? 0 : widget.receiverId,
      groupId: widget.isGroup ? widget.receiverId : null,
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