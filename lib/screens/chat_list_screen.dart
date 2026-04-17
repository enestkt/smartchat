import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  List<dynamic> partners = [];
  bool _fabExpanded = false;

  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _loadPartners();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
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

  void _toggleFab() {
    setState(() {
      _fabExpanded = !_fabExpanded;
      if (_fabExpanded) {
        _fabAnimController.forward();
      } else {
        _fabAnimController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(gradient: AppTheme.appBarGradient),
              child: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  "SmartChat",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                onPressed: () async {
                  await Navigator.pushNamed(context, "/search");
                  if (!mounted) return;
                  _loadPartners();
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) {
                  if (value == 'settings') {
                    Navigator.pushNamed(context, '/settings');
                  } else if (value == 'logout') {
                    _logout();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings_rounded, color: AppTheme.primaryTeal, size: 20),
                        SizedBox(width: 12),
                        Text("Ayarlar"),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppTheme.negative, size: 20),
                        SizedBox(width: 12),
                        Text("Çıkış Yap"),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryTeal),
              )
            : partners.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: AppTheme.primaryTeal,
                    onRefresh: _loadPartners,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 100),
                      itemCount: partners.length,
                      itemBuilder: (context, i) {
                        final user = partners[i];
                        return _chatCard(user, i);
                      },
                    ),
                  ),
      ),

      // ─── FAB ───
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Grup oluştur mini FAB
          AnimatedSlide(
            offset: _fabExpanded ? Offset.zero : const Offset(0, 0.5),
            duration: const Duration(milliseconds: 200),
            child: AnimatedOpacity(
              opacity: _fabExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Text("Grup Oluştur",
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: "group",
                      backgroundColor: AppTheme.accentCyan,
                      onPressed: () async {
                        _toggleFab();
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreateGroupScreen()));
                        if (!mounted) return;
                        _loadPartners();
                      },
                      child: const Icon(Icons.group_add_rounded, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Kişi arama mini FAB
          AnimatedSlide(
            offset: _fabExpanded ? Offset.zero : const Offset(0, 0.5),
            duration: const Duration(milliseconds: 250),
            child: AnimatedOpacity(
              opacity: _fabExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Text("Yeni Sohbet",
                          style: GoogleFonts.inter(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton.small(
                      heroTag: "contact",
                      backgroundColor: AppTheme.primaryTeal,
                      onPressed: () async {
                        _toggleFab();
                        await Navigator.pushNamed(context, "/search");
                        if (!mounted) return;
                        _loadPartners();
                      },
                      child:
                          const Icon(Icons.person_add_alt_1_rounded, size: 22),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Ana FAB
          FloatingActionButton(
            heroTag: "main",
            backgroundColor: AppTheme.primaryTeal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onPressed: _toggleFab,
            child: AnimatedRotation(
              turns: _fabExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.add_rounded, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ──────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: AppTheme.primaryTeal,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Henüz sohbet yok",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Yeni bir sohbet başlatmak için\naşağıdaki + butonuna dokun",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── CHAT CARD ────────────────────────────────────────────
  Widget _chatCard(dynamic user, int index) {
    final String name = user["username"] ?? "Unknown";
    final String lastMsg = user["last_message"] ?? "Henüz mesaj yok";
    final String? lastTime = user["last_time"];
    final bool isGroup = user["is_group"] == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  senderId: context.read<AuthProvider>().userId!,
                  receiverId: user["user_id"],
                  receiverName: name,
                  isGroup: isGroup,
                ),
              ),
            ).then((_) => _loadPartners());
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                // ─── AVATAR ──
                _buildAvatar(name, isGroup),

                const SizedBox(width: 14),

                // ─── MIDDLE ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // İsim
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Son mesaj
                      Text(
                        lastMsg,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ─── SAĞ: ZAMAN ──
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppTheme.smartTime(lastTime),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textHint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── AVATAR WIDGET ────────────────────────────────────────
  Widget _buildAvatar(String name, bool isGroup) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: isGroup
            ? const LinearGradient(
                colors: [AppTheme.accentCyan, AppTheme.primaryTeal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : AppTheme.avatarGradient(name),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryTeal.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: isGroup
            ? const Icon(Icons.group_rounded, color: Colors.white, size: 24)
            : Text(
                AppTheme.initials(name),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}