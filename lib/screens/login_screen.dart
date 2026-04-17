import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),

            // ─── HEADER ──────────────────────────────
            FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SmartChat",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Tekrar Hoş Geldin 👋",
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ─── FORM CARD ──────────────────────────
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusXL),
                    topRight: Radius.circular(AppTheme.radiusXL),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: SingleChildScrollView(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          const SizedBox(height: 30),

                          // ── EMAIL INPUT ──
                          _buildInputField(
                            controller: emailC,
                            hintText: "E-Posta Adresi",
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 20),

                          // ── PASSWORD INPUT ──
                          _buildInputField(
                            controller: passC,
                            hintText: "Şifre",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 40),

                          // ── LOGIN BUTTON ──
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusL + 6),
                              gradient: AppTheme.buttonGradient,
                              boxShadow: AppTheme.buttonShadow,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppTheme.radiusL + 6),
                                ),
                              ),
                              onPressed: auth.isLoading
                                  ? null
                                  : () async {
                                      final ok = await context
                                          .read<AuthProvider>()
                                          .login(
                                            emailC.text.trim(),
                                            passC.text.trim(),
                                          );

                                      if (!mounted) return;

                                      if (ok) {
                                        Navigator.pushReplacementNamed(
                                            context, '/chats');
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                                "Geçersiz e-posta veya şifre!"),
                                            backgroundColor:
                                                AppTheme.negative,
                                            behavior:
                                                SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 25,
                                      height: 25,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      "Giriş Yap",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ── SIGNUP LINK ──
                          TextButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/signup'),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(
                                  color: Colors.grey.shade600,
                                  fontSize: 15,
                                ),
                                children: [
                                  const TextSpan(
                                      text: "Hesabınız yok mu? "),
                                  TextSpan(
                                    text: "Kayıt Ol",
                                    style: TextStyle(
                                      color: AppTheme.primaryTeal,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: GoogleFonts.inter(fontSize: 16),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.grey.shade500),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                )
              : null,
        ),
      ),
    );
  }
}