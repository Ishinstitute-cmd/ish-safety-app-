import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_typography.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/language_provider.dart';

class BilingualText extends ConsumerWidget {
  final String textEn;
  final String textUr;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const BilingualText({
    super.key,
    required this.textEn,
    required this.textUr,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final isUrdu = language == AppLanguage.urdu;
    final text = isUrdu ? textUr : textEn;
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();

    return Text(
      text,
      textAlign: textAlign ?? (isUrdu ? TextAlign.right : TextAlign.left),
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTypography.getStyle(
        languageCode: language.code,
        baseEnStyle: baseStyle,
      ),
    );
  }
}
