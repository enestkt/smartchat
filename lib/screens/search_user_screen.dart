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

  Color get _primary => const Color(0xFF008F9C);

  Future<void> _searchUser() async {
    final username = searchC.text.trim();

    if (username.isEmpty) {
      setState(() {
        foundUser = null;
        error = "Please enter a username";
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
        error = "No user found";
      } else {
        foundUser = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final senderId = context.read<AuthProvider>().userId!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _primary,
        title: const Text(
          "Search User",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔍 SEARCH BOX (KART GİBİ)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchC,
                onSubmitted: (_) => _searchUser(),
                decoration: InputDecoration(
                  hintText: "Search by username",
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: _primary),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: _searchUser,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ⏳ LOADING
            if (isLoading)
              const CircularProgressIndicator(),

            // ❌ ERROR
            if (!isLoading && error != null)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // 👤 FOUND USER CARD
            if (!isLoading && foundUser != null)
              _userCard(foundUser!, senderId),
          ],
        ),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user, int currentUser) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: _primary.withOpacity(0.15),
          child: Icon(Icons.person, color: _primary),
        ),
        title: Text(
          user["username"],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text("Tap to start chat"),
        trailing: Icon(Icons.chat, color: _primary),
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
