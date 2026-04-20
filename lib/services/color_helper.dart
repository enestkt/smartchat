import 'package:flutter/material.dart';

class ColorHelper {
  static Color getPastelColor(String seedStr) {
    int hash = seedStr.hashCode;
    if (hash < 0) hash = -hash;
    double hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.8).toColor();
  }

  /// Sentiment rengini döndürür
  static Color sentimentColor(String? sentiment) {
    switch (sentiment?.toLowerCase()) {
      case 'positive':
        return const Color(0xFF22C55E);
      case 'negative':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  /// Sentiment ikonunu döndürür
  static IconData sentimentIcon(String? sentiment) {
    switch (sentiment?.toLowerCase()) {
      case 'positive':
        return Icons.sentiment_satisfied_alt;
      case 'negative':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }
}
