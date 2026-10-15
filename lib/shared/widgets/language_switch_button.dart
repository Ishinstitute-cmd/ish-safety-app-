import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/localization/app_locale.dart';
import '../../core/localization/language_provider.dart';

class LanguageSwitchButton extends ConsumerWidget {
  final bool isCompact;

  const LanguageSwitchButton({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(languageProvider);
    final isUrdu = currentLang == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'Switch Language between English and Urdu',
      child: InkWell(
        onTap: () {
          ref.read(languageProvider.notifier).toggleLanguage();
        },
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10.0 : 14.0,
            vertical: isCompact ? 6.0 : 8.0,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: AppColors.safetyYellow,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.language,
                size: isCompact ? 16 : 18,
                color: AppColors.safetyYellow,
              ),
              const SizedBox(width: 6),
              // English Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: !isUrdu ? AppColors.safetyYellow : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'EN',
                  style: TextStyle(
                    fontSize: isCompact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: !isUrdu ? Colors.black : (isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '|',
                style: TextStyle(
                  color: isDark ? Colors.white38 : Colors.black26,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              // Urdu Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isUrdu ? AppColors.safetyYellow : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'اردو',
                  style: TextStyle(
                    fontFamily: 'NotoNastaliqUrdu',
                    fontSize: isCompact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                    color: isUrdu ? Colors.black : (isDark ? Colors.white70 : Colors.black54),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
