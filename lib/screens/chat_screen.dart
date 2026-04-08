import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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

  Map<String, dynamic>? _analysis; // 🔥 yeni eklendi
  Timer? _typingTimer; // 🔥 yeni eklendi

  Map<String, dynamic>? _aiSuggestion; // /complete sonucu
  bool _aiLoading = false;
  bool _loadingMessages = true;

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
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ----------------------------------------------------------
  // LOAD MESSAGES
  // ----------------------------------------------------------
  Future<void> _loadMessages() async {
    try {
      final data = await ChatService().fetchMessages(
        widget.senderId,
        widget.receiverId,
      );

      final formatted = data.map<Map<String, dynamic>>((m) {
        return {
          "text": m["content"]?.toString() ?? "",
          "image": m["image_url"]?.toString() ?? m["file_path"]?.toString(),
          "isMe": m["sender_id"] == widget.senderId,
          "time": _formatTime(
            m["created_at"]?.toString() ?? m["timestamp"]?.toString(),
          ),
          "mediaType": m["media_type"]?.toString(),
          "mediaUrl": m["image_url"]?.toString() ?? m["file_path"]?.toString(),
        };
      }).toList();

      if (!mounted) return;

      setState(() {
        _messages = formatted;
        _loadingMessages = false;
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loadingMessages = false;
      });

      debugPrint("LOAD MESSAGES ERROR => $e");
    }
  }

  Future<void> _checkNewMessages() async {
    try {
      final latest = await ChatService().fetchMessages(
        widget.senderId,
        widget.receiverId,
      );

      final formatted = latest.map<Map<String, dynamic>>((m) {
        return {
          "text": m["content"]?.toString() ?? "",
          "image": m["image_url"]?.toString() ?? m["file_path"]?.toString(),
          "isMe": m["sender_id"] == widget.senderId,
          "time": _formatTime(
            m["created_at"]?.toString() ?? m["timestamp"]?.toString(),
          ),
          "mediaType": m["media_type"]?.toString(),
          "mediaUrl": m["image_url"]?.toString() ?? m["file_path"]?.toString(),
        };
      }).toList();

      if (!mounted) return;

      if (formatted.length != _messages.length) {
        setState(() => _messages = formatted);
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("CHECK NEW MESSAGES ERROR => $e");
    }
  }

  // ----------------------------------------------------------
  // TIME FORMAT
  // ----------------------------------------------------------
  String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    try {
      final dt = DateTime.parse(raw);
      return "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return raw;
    }
  }

  void _handleTyping(String text) {
    if (_typingTimer != null) {
      _typingTimer!.cancel();
    }

    _typingTimer = Timer(const Duration(seconds: 1), () async {
      if (text.trim().isEmpty) {
        if (!mounted) return;
        setState(() => _analysis = null);
        return;
      }

      try {
        final result = await ApiService().predictMessage(
          text: text,
          senderId: widget.senderId, // ✅ DOĞRU
          receiverId: widget.receiverId, // ✅ DOĞRU
        );

        if (!mounted) return;

        setState(() {
          _analysis = result;
        });
      } catch (e) {
        debugPrint("PREDICT ERROR: $e");
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

      if (!mounted) return;

      setState(() {
        _aiSuggestion = res;
      });
    } catch (e) {
      debugPrint("COMPLETE ERROR => $e");
    } finally {
      if (!mounted) return;
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
      _aiSuggestion = null;
    });

    // Mesajı ekrana ekle
    setState(() {
      _messages.add({
        "text": text,
        "isMe": true,
        "time": _formatTime(DateTime.now().toIso8601String()),
        "image": null,
        "mediaType": null,
        "mediaUrl": null,
      });
    });

    _messageController.clear();
    _scrollToBottom();

    final ok = await ChatService().sendMessage(
      widget.senderId,
      widget.receiverId,
      text,
    );

    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Message could not be sent.")),
      );
    }

    await _loadMessages();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
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
    final isMe = msg["isMe"] == true;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xffdcf8c6) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft:
                    isMe ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight:
                    isMe ? const Radius.circular(4) : const Radius.circular(16),
              ),
            ),
            child: _buildMessageContent(msg),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 12),
            child: Text(
              msg["time"]?.toString() ?? "",
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          )
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // TEXT OR IMAGE LOGIC
  // ----------------------------------------------------------
  Widget _buildMessageContent(Map<String, dynamic> msg) {
    final imagePath = msg["image"]?.toString();
    final mediaUrl = msg["mediaUrl"]?.toString();

    if ((msg["mediaType"] == "image" || imagePath != null) &&
        (mediaUrl != null || imagePath != null)) {
      final source = mediaUrl ?? imagePath!;

      if (source.startsWith("http://") || source.startsWith("https://")) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            source,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox(
              width: 220,
              height: 220,
              child: Center(child: Text("Image failed to load")),
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(source),
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox(
            width: 220,
            height: 220,
            child: Center(child: Text("Image failed to load")),
          ),
        ),
      );
    }

    return Text(
      msg["text"]?.toString() ?? "",
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
        title: Row(
          children: [
            const CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
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
                const Text(
                  "online",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
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
                if (_loadingMessages)
                  const Center(child: CircularProgressIndicator())
                else
                  ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    // ÖNEMLİ: AI Paneli açıkken mesajlar arkada kalmasın diye alt boşluk veriyoruz
                    padding: EdgeInsets.only(
                      bottom:
                          (_analysis != null || _aiSuggestion != null) ? 180 : 12,
                      top: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final msg = _messages[_messages.length - 1 - i];
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
                      if (_aiSuggestion != null)
                        _buildAiSuggestionFloatingPanel(),
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
    final completion = _aiSuggestion?["completion"]?.toString() ??
        _aiSuggestion?["suggested_text"]?.toString() ??
        "";

    final suggestionId = _aiSuggestion?["suggestion_id"];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50.withOpacity(0.98), // Hafif saydam ve şık
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI Message Suggestion",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              _messageController.text = completion;
              _messageController.selection = TextSelection.fromPosition(
                TextPosition(offset: completion.length),
              );
            },
            child: Text(completion, style: const TextStyle(fontSize: 15)),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: suggestionId == null
                    ? () => setState(() => _aiSuggestion = null)
                    : () async {
                        await ApiService().updateSuggestionStatus(
                          suggestionId: suggestionId,
                          accepted: false,
                        );
                        if (!mounted) return;
                        setState(() => _aiSuggestion = null);
                      },
                child: const Text("Reject"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  _messageController.text = completion;

                  if (suggestionId != null) {
                    await ApiService().updateSuggestionStatus(
                      suggestionId: suggestionId,
                      accepted: true,
                    );
                  }

                  if (!mounted) return;
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
              _mediaOption(
                Icons.camera_alt,
                "Camera",
                Colors.cyan,
                _captureImage,
              ),
              _mediaOption(
                Icons.photo,
                "Gallery",
                Colors.purple,
                _pickImage,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _mediaOption(
    IconData icon,
    String label,
    Color color,
    Future<void> Function() onTap,
  ) {
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
        "image": picked.path, // 🔥 TEMP DEĞİL → gerçek local dosya yolu
        "isMe": true,
        "time": _formatTime(DateTime.now().toIso8601String()),
        "mediaType": "image",
        "mediaUrl": picked.path,
      });
    });

    _scrollToBottom();

    // Sonra backend’e yükle
    final ok = await ChatService().uploadMedia(
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      filePath: picked.path,
      mediaType: "image",
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image upload failed.")),
      );
    }

    // Backend URL geldikten sonra doğru URL ile yeniden yükle
    await _loadMessages();
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
        "time": _formatTime(DateTime.now().toIso8601String()),
        "mediaType": "image",
        "mediaUrl": picked.path,
      });
    });

    _scrollToBottom();

    final ok = await ChatService().uploadMedia(
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      filePath: picked.path,
      mediaType: "image",
    );

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Camera image upload failed.")),
      );
    }

    await _loadMessages();
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