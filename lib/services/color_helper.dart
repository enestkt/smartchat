import 'package:flutter/material.dart';

class ColorHelper {
  static Color getPastelColor(String seedStr) {
    int hash = seedStr.hashCode;
    if (hash < 0) hash = -hash;
    double hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.8).toColor();
  }
}