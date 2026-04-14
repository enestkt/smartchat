import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final usernameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();

  final Color _primaryTeal = const Color(0xFF008F9C);
  final Color _darkTeal = const Color(0xFF005C66);

  @override
  void dispose() {
    usernameC.dispose();
    emailC.dispose();
    passC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _darkTeal,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _darkTeal,
              _primaryTeal,
              const Color(0xFF4DD0E1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            Padding(
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
                    "Hemen Aramıza Katıl",
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    topRight: Radius.circular(50),
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
                            borderRadius: BorderRadius.circular(30),
                            gradient: LinearGradient(
                              colors: [_primaryTeal, _darkTeal],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _primaryTeal.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
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
                                        const SnackBar(content: Text("Kayıt başarılı, giriş yapabilirsiniz.")),
                                      );
                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                            content: Text(provider.lastError ?? "Kayıt başarısız")),
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
                                    "Kayıt Ol",
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

                        /// LOGIN LINK
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/login'),
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 15),
                              children: [
                                const TextSpan(text: "Zaten hesabınız var mı? "),
                                TextSpan(
                                  text: "Giriş Yap",
                                  style: TextStyle(
                                    color: _primaryTeal,
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
        border: Border.all(color: Colors.grey.shade200, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.inter(fontSize: 16),
        decoration: InputDecoration(
          icon: Icon(icon, color: Colors.grey.shade500),
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
          border: InputBorder.none,
        ),
      ),
    );
  }
}