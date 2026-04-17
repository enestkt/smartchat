import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor(context),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: isDark ? null : AppTheme.appBarGradient,
            color: isDark ? const Color(0xFF151520) : null,
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              "Ayarlar",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // ─── PROFILE CARD ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: auth.profilePicture == null
                            ? AppTheme.avatarGradient(auth.username ?? "U")
                            : null,
                      ),
                      child: ClipOval(
                        child: auth.profilePicture != null
                            ? Image.network(
                                "${ApiService.baseUrl}/${auth.profilePicture}",
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(
                                    AppTheme.initials(auth.username ?? "U"),
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  AppTheme.initials(auth.username ?? "U"),
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.username ?? "Kullanıcı",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textColor(context),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            auth.about ?? "Merhaba, SmartChat kullanıyorum!",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.secondaryTextColor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.secondaryTextColor(context),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── GENEL AYARLAR ──
          _sectionHeader(context, "Genel"),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  // Dark Mode
                  _settingsTile(
                    context: context,
                    icon: Icons.dark_mode_rounded,
                    iconColor: const Color(0xFF6366F1),
                    title: "Karanlık Mod",
                    subtitle: themeProvider.isDarkMode ? "Açık" : "Kapalı",
                    trailing: Switch.adaptive(
                      value: themeProvider.isDarkMode,
                      activeColor: AppTheme.primaryTeal,
                      onChanged: (_) => themeProvider.toggleTheme(),
                    ),
                  ),
                  _divider(),

                  // Bildirimler
                  _settingsTile(
                    context: context,
                    icon: Icons.notifications_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: "Bildirimler",
                    subtitle: "Mesaj ve arama bildirimleri",
                    onTap: () {
                      _showComingSoon(context);
                    },
                  ),
                  _divider(),

                  // Gizlilik
                  _settingsTile(
                    context: context,
                    icon: Icons.lock_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: "Gizlilik",
                    subtitle: "Son görülme, profil fotoğrafı",
                    onTap: () {
                      _showComingSoon(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── SOHBET AYARLARI ──
          _sectionHeader(context, "Sohbet"),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  _settingsTile(
                    context: context,
                    icon: Icons.chat_bubble_rounded,
                    iconColor: AppTheme.primaryTeal,
                    title: "Sohbet Ayarları",
                    subtitle: "Tema, duvar kağıdı, yazı boyutu",
                    onTap: () {
                      _showComingSoon(context);
                    },
                  ),
                  _divider(),
                  _settingsTile(
                    context: context,
                    icon: Icons.auto_awesome_rounded,
                    iconColor: AppTheme.accentCyan,
                    title: "AI Asistan Ayarları",
                    subtitle: "Akıllı yanıt, mesaj önerisi",
                    onTap: () {
                      _showComingSoon(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── HAKKINDA ──
          _sectionHeader(context, "Uygulama"),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  _settingsTile(
                    context: context,
                    icon: Icons.info_outline_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    title: "Hakkında",
                    subtitle: "SmartChat v1.0.0",
                  ),
                  _divider(),
                  _settingsTile(
                    context: context,
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF06B6D4),
                    title: "Yardım",
                    subtitle: "SSS ve destek",
                    onTap: () {
                      _showComingSoon(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // ─── ÇIKIŞ YAP ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: AppTheme.softShadow,
              ),
              child: _settingsTile(
                context: context,
                icon: Icons.logout_rounded,
                iconColor: AppTheme.negative,
                title: "Çıkış Yap",
                titleColor: AppTheme.negative,
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.cardColor(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Text("Çıkış Yap",
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      content: Text("Hesabınızdan çıkış yapmak istediğinize emin misiniz?",
                          style: GoogleFonts.inter()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text("İptal", style: GoogleFonts.inter(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.negative,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text("Çıkış Yap",
                              style: GoogleFonts.inter(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && context.mounted) {
                    const storage = FlutterSecureStorage();
                    await storage.deleteAll();

                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      "/login",
                      (route) => false,
                    );
                  }
                },
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.secondaryTextColor(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _settingsTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    Color? titleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusM),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppTheme.textColor(context),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing
            else if (onTap != null)
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.secondaryTextColor(context),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(height: 1, indent: 60, endIndent: 16, color: Colors.grey.withOpacity(0.15));
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Yakında eklenecek!", style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.primaryTeal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
