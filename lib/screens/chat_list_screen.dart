import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool isLoading = true;
  List<dynamic> partners = [];

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;

    if (userId == null) return;

    final data = await ChatService().getChatPartners(userId);

    setState(() {
      isLoading = false;
      partners = data;
    });
  }

  // 🔥 LOGOUT
  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      "/login",
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF008F9C),
        title: const Text(
          "SmartChat",
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          )
        ],
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : partners.isEmpty
              ? const Center(
                  child: Text(
                    "No conversations yet.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: partners.length,
                  itemBuilder: (context, i) {
                    final user = partners[i];

                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person),
                        radius: 24,
                      ),
                      title: Text(
                        user["username"] ?? "Unknown",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        user["last_message"] ?? "No messages yet.",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        user["last_time"] ?? "",
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              senderId: context.read<AuthProvider>().userId!,
                              receiverId: user["user_id"],
                              receiverName: user["username"],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
