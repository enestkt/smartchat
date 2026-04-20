import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final usernameC = TextEditingController();
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
    usernameC.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.darkColor,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
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
                        color: AppTheme.cardColor(context),
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Hemen Aramıza Katıl 🚀",
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
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppTheme.radiusXL),
                    topRight: Radius.circular(AppTheme.radiusXL),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textColor(context).withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
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
                          
                          /// USERNAME INPUT
                          _buildInputField(
                            controller: usernameC,
                            hintText: "Kullanıcı Adı",
                            icon: Icons.person_outline,
                          ),
                          const SizedBox(height: 20),

                          /// EMAIL INPUT
                          _buildInputField(
                            controller: emailC,
                            hintText: "E-Posta Adresi",
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 20),

                          /// PASSWORD INPUT
                          _buildInputField(
                            controller: passC,
                            hintText: "Şifre",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          const SizedBox(height: 40),

                          /// SIGNUP BUTTON
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.radiusL + 6),
                              gradient: AppTheme.buttonGradient,
                              boxShadow: AppTheme.buttonShadow,
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.radiusL + 6),
                                ),
                              ),
                              onPressed: auth.isLoading
                                  ? null
                                  : () async {
                                      final provider = context.read<AuthProvider>();

                                      final ok = await provider.signup(
                                        usernameC.text.trim(),
                                        emailC.text.trim(),
                                        passC.text.trim(),
                                      );

                                      if (!mounted) return;

                                      if (ok) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: const Text("Kayıt başarılı! Giriş yapabilirsiniz."),
                                            backgroundColor: AppTheme.positive,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                        Navigator.pop(context);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(provider.lastError ?? "Kayıt başarısız"),
                                            backgroundColor: AppTheme.negative,
                                            behavior: SnackBarBehavior.floating,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              child: auth.isLoading
                                  ? SizedBox(
                                      width: 25,
                                      height: 25,
                                      child: CircularProgressIndicator(
                                        color: AppTheme.cardColor(context),
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : Text(
                                      "Kayıt Ol",
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.cardColor(context),
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          /// LOGIN LINK
                          TextButton(
                            onPressed: () => Navigator.pushNamed(context, '/login'),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(color: AppTheme.secondaryTextColor(context), fontSize: 15),
                                children: [
                                  const TextSpan(text: "Zaten hesabınız var mı? "),
                                  TextSpan(
                                    text: "Giriş Yap",
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
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
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2A2A3A) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.grey.shade200, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _obscurePassword : false,
        style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textColor(context)),
        decoration: InputDecoration(
          icon: Icon(icon, color: AppTheme.secondaryTextColor(context)),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: AppTheme.secondaryTextColor(context)),
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: AppTheme.secondaryTextColor(context),
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
