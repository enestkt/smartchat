import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool isLoading = true;
  List<dynamic> partners = [];
  String? errorMessage;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPartners();
    });
  }

  Future<void> _loadPartners() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.userId;

    if (userId == null) {
      setState(() {
        isLoading = false;
        errorMessage = "Oturum bulunamadı. Lütfen tekrar giriş yap.";
      });
      return;
    }

    try {
      final data = await ChatService().getChatPartners(userId);

      if (!mounted) return;

      setState(() {
        isLoading = false;
        partners = data;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = "Sohbet listesi yüklenemedi: $e";
      });
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    await _loadPartners();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF008F9C),
        title: Text(
          auth.userId != null
              ? "SmartChat"
              : "SmartChat - Oturum Yok",
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () async {
              await Navigator.pushNamed(context, "/search");
              if (!mounted) return;
              await _refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                )
              : partners.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        children: const [
                          SizedBox(height: 180),
                          Center(
                            child: Text(
                              "No conversations yet.",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        itemCount: partners.length,
                        itemBuilder: (context, i) {
                          final user = partners[i] as Map<String, dynamic>;

                          final int? receiverId = user["user_id"] is int
                              ? user["user_id"]
                              : int.tryParse(user["user_id"]?.toString() ?? "");

                          final String receiverName =
                              user["username"]?.toString() ?? "Unknown";

                          final String lastMessage =
                              user["last_message"]?.toString() ??
                                  user["content"]?.toString() ??
                                  "No messages yet.";

                          final String lastTime =
                              user["last_time"]?.toString() ??
                                  user["timestamp"]?.toString() ??
                                  "";

                          return ListTile(
                            leading: const CircleAvatar(
                              radius: 24,
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              receiverName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Text(
                              lastTime,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onTap: receiverId == null
                                ? null
                                : () {
                                    final senderId =
                                        context.read<AuthProvider>().userId;

                                    if (senderId == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Oturum bulunamadı. Tekrar giriş yap.",
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ChatScreen(
                                          senderId: senderId,
                                          receiverId: receiverId,
                                          receiverName: receiverName,
                                        ),
                                      ),
                                    );
                                  },
                          );
                        },
                      ),
                    ),
    );
  }
}