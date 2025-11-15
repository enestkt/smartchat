// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final data = await ChatService()
        .fetchMessages(widget.senderId, widget.receiverId);

    setState(() {
      _messages = data.map<Map<String, dynamic>>((m) {
        return {
          "text": m["content"],
          "isMe": m["sender_id"] == widget.senderId,
          "time": m["created_at"],
        };
      }).toList();
    });

    await Future.delayed(const Duration(milliseconds: 300));
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // UI tarafında göster
    setState(() {
      _messages.add({
        "text": text,
        "isMe": true,
        "time": "now",
      });
    });

    // Scroll
    Future.delayed(const Duration(milliseconds: 150), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    _messageController.clear();

    // BACKEND’E GÖNDER
    await ChatService().sendMessage(
      widget.senderId,
      widget.receiverId,
      text,
    );
  }

  Widget _bubble(Map<String, dynamic> msg) {
    final isMe = msg["isMe"];
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.orange : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          msg["text"],
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        backgroundColor: Colors.orange[900],
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

          _inputBar(),
        ],
      ),
    );
  }

  Widget _inputBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "Type a message…",
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}
