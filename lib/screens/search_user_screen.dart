import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  State<SearchUserScreen> createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final TextEditingController searchC = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool isLoading = false;
  String? error;
  Map<String, dynamic>? foundUser;

  @override
  void initState() {
    super.initState();
    // Arama alanına otomatik odaklan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    searchC.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final username = searchC.text.trim();

    if (username.isEmpty) {
      setState(() {
        foundUser = null;
        error = "Lütfen kullanıcı adı girin";
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
        error = "Kullanıcı bulunamadı";
      } else {
        foundUser = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final senderId = context.read<AuthProvider>().userId!;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(gradient: AppTheme.appBarGradient),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "Kişi Ara",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔍 SEARCH BOX
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: AppTheme.cardShadow,
              ),
              child: TextField(
                controller: searchC,
                focusNode: _focusNode,
                onSubmitted: (_) => _searchUser(),
                style: GoogleFonts.inter(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Kullanıcı adı ile ara...",
                  hintStyle: GoogleFonts.inter(color: AppTheme.textHint),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search_rounded,
                      color: AppTheme.primaryTeal),
                  suffixIcon: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: Colors.white),
                    ),
                    onPressed: _searchUser,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ⏳ LOADING
            if (isLoading)
              const CircularProgressIndicator(color: AppTheme.primaryTeal),

            // ❌ ERROR
            if (!isLoading && error != null)
              Padding(
                padding: const EdgeInsets.only(top: 50),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_search_rounded,
                          size: 48, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      error!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // 👤 FOUND USER CARD
            if (!isLoading && foundUser != null) _userCard(foundUser!, senderId),
          ],
        ),
      ),
    );
  }

  Widget _userCard(Map<String, dynamic> user, int currentUser) {
    final String username = user["username"] ?? "Unknown";

    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  senderId: currentUser,
                  receiverId: user["id"],
                  receiverName: username,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppTheme.avatarGradient(username),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryTeal.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      AppTheme.initials(username),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 14),

                // İsim
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        username,
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Sohbet başlatmak için dokun",
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chat ikonu
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.chat_rounded,
                      color: AppTheme.primaryTeal, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}