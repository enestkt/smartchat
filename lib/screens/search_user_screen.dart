import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController searchC = TextEditingController();

  Map<String, dynamic>? foundUser; // backend’den gelen kullanıcı

  bool isLoading = false;

  Future<void> _searchUser() async {
    final username = searchC.text.trim();
    if (username.isEmpty) return;

    setState(() => isLoading = true);

    final result = await ChatService().searchUser(username);

    setState(() {
      foundUser = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final senderId = context.read<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search User"),
        backgroundColor: Colors.orange[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: searchC,
              decoration: InputDecoration(
                hintText: "Enter username…",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  onPressed: _searchUser,
                  icon: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (isLoading)
              const CircularProgressIndicator(),

            if (!isLoading && foundUser != null)
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(foundUser!["username"]),
                subtitle: Text("ID: ${foundUser!["id"]}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        senderId: senderId!,
                        receiverId: foundUser!["id"],
                        receiverName: foundUser!["username"],
                      ),
                    ),
                  );
                },
              ),

            if (!isLoading && foundUser == null)
              const Text("No user found"),
          ],
        ),
      ),
    );
  }
}
