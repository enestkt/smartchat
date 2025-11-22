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
  bool isLoading = false;
  String? error;
  Map<String, dynamic>? foundUser;

  Future<void> _searchUser() async {
    final username = searchC.text.trim();

    if (username.isEmpty) {
      setState(() {
        foundUser = null;
        error = "Please enter a username.";
      });
      return;
    }

    setState(() {
      isLoading = true;
      error = null;
      foundUser = null;
    });

    final result = await ChatService().searchUser(username);

    setState(() {
      isLoading = false;
      if (result == null) {
        error = "No user found.";
      } else {
        foundUser = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final senderId = context.read<AuthProvider>().userId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[900],
        title: const Text(
          "Search User",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔍 Search Box
            TextField(
              controller: searchC,
              onSubmitted: (_) => _searchUser(),
              decoration: InputDecoration(
                hintText: "Enter username...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUser,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ⏳ Loading
            if (isLoading)
              const CircularProgressIndicator(),

            // ❌ Error message
            if (!isLoading && error != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),

            // 👤 User card
            if (!isLoading && foundUser != null)
              _userCard(foundUser!, senderId!),
          ],
        ),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user, int currentUser) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          radius: 24,
          child: Icon(Icons.person),
        ),
        title: Text(
          user["username"],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text("ID: ${user['id']}"),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                senderId: currentUser,
                receiverId: user["id"],
                receiverName: user["username"],
              ),
            ),
          );
        },
      ),
    );
  }
}
