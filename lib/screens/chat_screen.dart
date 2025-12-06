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

  Color get _turquoise => const Color(0xFF008F9C);

  @override
  void initState() {
    super.initState();
    _loadMessages();

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
  // FETCH MESSAGES
  // ----------------------------------------------------------
  Future<void> _loadMessages() async {
    final data = await ChatService()
        .fetchMessages(widget.senderId, widget.receiverId);

    setState(() {
      _messages = data.map<Map<String, dynamic>>((m) {
        return {
          "text": m["content"],
          "mediaUrl": m["media_url"],
          "mediaType": m["media_type"],
          "isMe": m["sender_id"] == widget.senderId,
          "time": _formatTime(m["created_at"]),
        };
      }).toList();
    });

    _scrollToBottom();
  }

  Future<void> _checkNewMessages() async {
    final data = await ChatService()
        .fetchMessages(widget.senderId, widget.receiverId);

    final formatted = data.map<Map<String, dynamic>>((m) {
      return {
        "text": m["content"],
        "mediaUrl": m["media_url"],
        "mediaType": m["media_type"],
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
    // Önceki timer çalışıyorsa iptal et
    if (_typingTimer != null) {
      _typingTimer!.cancel();
    }

    // 1 saniye bekleyip /predict çağır
    _typingTimer = Timer(const Duration(seconds: 1), () async {
      if (text.trim().isEmpty) {
        setState(() => _analysis = null);
        return;
      }

      try {
        final result = await ApiService().predictMessage(text);

        setState(() {
          _analysis = result; // Gelen AI analizini state'e yaz
        });
      } catch (e) {
        print("PREDICT ERROR: $e");
      }
    });
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
        "mediaUrl": null,
        "mediaType": null,
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

  // ----------------------------------------------------------
  // SCROLL
  // ----------------------------------------------------------
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
  // BUBBLE
  // ----------------------------------------------------------
  Widget _bubble(Map<String, dynamic> msg) {
    final isMe = msg["isMe"];

    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xffdcf8c6) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: _buildMessageContent(msg),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 12),
            child: Text(
              msg["time"],
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
            Text(
              widget.receiverName,
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, i) => _bubble(_messages[i]),
            ),
          ),

          // 🔥 AI FEEDBACK PANEL
          if (_analysis != null) _aiPanel(),

          // INPUT BAR
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
          IconButton(
            icon: Icon(Icons.add, color: _turquoise),
            onPressed: _openMediaSheet,
          ),

          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: "Message",
                  border: InputBorder.none,
                ),
                onChanged: _handleTyping,
              ),
            ),
          ),

          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              backgroundColor: _turquoise,
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // MEDIA PICKER SHEET
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
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
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
  // IMAGE PICK LOGIC
  // ----------------------------------------------------------
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final ok = await ChatService().uploadMedia(
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      filePath: picked.path,
      mediaType: "image",
    );

    if (ok) _loadMessages();
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    final ok = await ChatService().uploadMedia(
      senderId: widget.senderId,
      receiverId: widget.receiverId,
      filePath: picked.path,
      mediaType: "image",
    );

    if (ok) _loadMessages();
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
          Text(
            "AI Analysis",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "• Style: ${_analysis!["style"]} "
                "(${(_analysis!["style_confidence"] * 100).toStringAsFixed(1)}%)",
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            "• Sentiment: ${_analysis!["sentiment"]} "
                "(${(_analysis!["sentiment_confidence"] * 100).toStringAsFixed(1)}%)",
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            "• Fixed: ${_analysis!["punctuation_fixed"]}",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

}
