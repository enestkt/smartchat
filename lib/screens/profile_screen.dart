import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Profil Fotoğrafı",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoOption(Icons.camera_alt_rounded, "Kamera",
                    AppTheme.accentCyan, () => Navigator.pop(ctx, ImageSource.camera)),
                _photoOption(Icons.photo_library_rounded, "Galeri",
                    AppTheme.primaryTeal, () => Navigator.pop(ctx, ImageSource.gallery)),
              ],
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploading = true);

    await context.read<AuthProvider>().updateProfilePicture(picked.path);

    if (mounted) setState(() => _uploading = false);
  }

  Widget _photoOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.secondaryTextColor(context))),
      ],
    );
  }

  Future<void> _editAbout() async {
    final auth = context.read<AuthProvider>();
    final controller = TextEditingController(text: auth.about ?? "");

    final newAbout = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Hakkımda", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: controller,
          maxLength: 140,
          maxLines: 3,
          style: GoogleFonts.inter(),
          decoration: InputDecoration(
            hintText: "Bir şeyler yaz...",
            hintStyle: GoogleFonts.inter(color: AppTheme.textHint),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("İptal", style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Kaydet", style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );

    if (newAbout != null && newAbout.isNotEmpty) {
      await auth.updateAbout(newAbout);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
            title: Text("Profil", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // ─── PROFILE PHOTO ──
            GestureDetector(
              onTap: _pickAndUploadPhoto,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: auth.profilePicture == null
                          ? AppTheme.avatarGradient(auth.username ?? "U")
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryTeal.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: auth.profilePicture != null
                          ? Image.network(
                              "${ApiService.baseUrl}/${auth.profilePicture}",
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _defaultAvatar(auth.username),
                            )
                          : _defaultAvatar(auth.username),
                    ),
                  ),

                  // Upload indicator
                  if (_uploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        ),
                      ),
                    ),

                  // Camera badge
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.surfaceColor(context), width: 3),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text(
              auth.username ?? "Kullanıcı",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              auth.email ?? "",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.secondaryTextColor(context),
              ),
            ),

            const SizedBox(height: 32),

            // ─── INFO CARDS ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: BorderRadius.circular(AppTheme.radiusM),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  children: [
                    _infoTile(
                      icon: Icons.person_outline_rounded,
                      label: "Kullanıcı Adı",
                      value: auth.username ?? "-",
                    ),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                    _infoTile(
                      icon: Icons.email_outlined,
                      label: "E-Posta",
                      value: auth.email ?? "-",
                    ),
                    Divider(height: 1, color: Colors.grey.withOpacity(0.15)),
                    _infoTile(
                      icon: Icons.info_outline_rounded,
                      label: "Hakkımda",
                      value: auth.about ?? "Merhaba, SmartChat kullanıyorum!",
                      onTap: _editAbout,
                      trailing: Icon(Icons.edit_rounded, size: 18, color: AppTheme.primaryTeal),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(String? name) {
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Text(
          AppTheme.initials(name ?? "U"),
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryTeal, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.secondaryTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
