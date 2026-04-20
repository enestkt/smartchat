import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SmartChat Design System
/// Tüm renk, tipografi ve stil sabitleri burada tanımlıdır.
class AppTheme {
  AppTheme._();

  // ─── RENKLER ───────────────────────────────────────────────
  static const Color primaryColor = Color(0xFF4F46E5); // Indigo
  static const Color darkColor = Color(0xFF312E81); // Deep Indigo
  static const Color accentColor = Color(0xFF8B5CF6); // Violet
  static const Color lightColor = Color(0xFFA78BFA); // Soft Violet

  // Surfaces
  static const Color surface = Color(0xFFF0F4F8);
  static const Color chatBackground = Color(0xFFE8EDF2);
  static const Color cardWhite = Colors.white;

  // Mesaj balonları
  static const Color sentBubble = Color(0xFFD4F5E9);
  static const Color sentBubbleDark = Color(0xFFA8E6CF);
  static const Color receivedBubble = Colors.white;

  // Metin renkleri
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);

  // Durumlar
  static const Color online = Color(0xFF22C55E);
  static const Color positive = Color(0xFF22C55E);
  static const Color negative = Color(0xFFEF4444);
  static const Color neutral = Color(0xFFF59E0B);

  // ─── GRADİENTLER ──────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkColor, primaryColor, lightColor],
  );

  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkColor, primaryColor],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [primaryColor, darkColor],
  );

  // ─── GÖLGELER ─────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryColor.withOpacity(0.35),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];

  // ─── BORDER RADIUS ────────────────────────────────────────
  static const double radiusS = 12.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 50.0;

  // ─── AVATAR ───────────────────────────────────────────────
  /// Kullanıcı adından gradient renkleri oluşturur
  static LinearGradient avatarGradient(String name) {
    int hash = name.hashCode;
    if (hash < 0) hash = -hash;
    final double hue1 = (hash % 360).toDouble();
    final double hue2 = ((hash * 7 + 120) % 360).toDouble();
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        HSLColor.fromAHSL(1.0, hue1, 0.65, 0.55).toColor(),
        HSLColor.fromAHSL(1.0, hue2, 0.55, 0.65).toColor(),
      ],
    );
  }

  /// Kullanıcı adının baş harflerini döndürür
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  // ─── TEMA ─────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: primaryColor,
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  // ─── DARK THEME ───────────────────────────────────────────
  static const Color darkSurface = Color(0xFF121218);
  static const Color darkCard = Color(0xFF1E1E2A);
  static const Color darkChatBg = Color(0xFF0B0B10);
  static const Color darkSentBubble = Color(0xFF005C54);
  static const Color darkReceivedBubble = Color(0xFF1E1E2A);
  static const Color darkTextPrimary = Color(0xFFE8E8EE);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: primaryColor,
      scaffoldBackgroundColor: darkSurface,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF151520),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusL),
          ),
          elevation: 0,
        ),
      ),
      cardTheme: const CardThemeData(
        color: darkCard,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2A2A3A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      dividerColor: Colors.white12,
    );
  }

  /// Dark mode'a göre doğru rengi döndüren yardımcılar
  static Color surfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSurface : surface;
  }

  static Color cardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkCard : cardWhite;
  }

  static Color chatBgColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkChatBg : chatBackground;
  }

  static Color sentBubbleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkSentBubble : sentBubble;
  }

  static Color receivedBubbleColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkReceivedBubble : receivedBubble;
  }

  static Color textColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : textPrimary;
  }

  static Color secondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : textSecondary;
  }

  // ─── ZAMAN FORMATI (AKILLI) ────────────────────────────────
  /// "5dk önce", "Dün", "14:30" gibi akıllı zaman formatlaması
  static String smartTime(String? raw) {
    if (raw == null || raw.isEmpty) return "";
    try {
      final dt = DateTime.parse(raw);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return "Şimdi";
      if (diff.inMinutes < 60) return "${diff.inMinutes}dk";
      if (diff.inHours < 24 && dt.day == now.day) {
        return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
      }
      if (diff.inHours < 48) return "Dün";
      if (diff.inDays < 7) {
        const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
        return days[dt.weekday - 1];
      }
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return "";
    }
  }
}
