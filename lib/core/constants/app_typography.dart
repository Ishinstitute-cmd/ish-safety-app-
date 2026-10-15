import 'package:flutter/material.dart';

class AppTypography {
  static const String urduFontFamily = 'NotoNastaliqUrdu';

  // English Styles
  static const TextStyle enDisplay = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle enTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle enSubtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  static const TextStyle enBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle enCaption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    height: 1.4,
  );

  // Urdu Styles (tuned for Noto Nastaliq Urdu)
  static const TextStyle urDisplay = TextStyle(
    fontFamily: urduFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.8,
  );

  static const TextStyle urTitle = TextStyle(
    fontFamily: urduFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.9,
  );

  static const TextStyle urSubtitle = TextStyle(
    fontFamily: urduFontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.9,
  );

  static const TextStyle urBody = TextStyle(
    fontFamily: urduFontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 2.0,
  );

  static const TextStyle urCaption = TextStyle(
    fontFamily: urduFontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.8,
  );

  /// Helper to return appropriate TextStyle based on language code
  static TextStyle getStyle({
    required String languageCode,
    required TextStyle baseEnStyle,
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) {
    final bool isUrdu = languageCode == 'ur';
    return baseEnStyle.copyWith(
      fontFamily: isUrdu ? urduFontFamily : null,
      height: isUrdu ? (baseEnStyle.height != null ? baseEnStyle.height! * 1.3 : 1.9) : baseEnStyle.height,
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize != null ? (isUrdu ? fontSize * 0.95 : fontSize) : null,
    );
  }
}
