import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/utils/hierarchy_of_controls.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../../shared/widgets/safety_button.dart';
import '../domain/hazard_model.dart';

class HazardBottomSheet extends ConsumerWidget {
  final HazardModel hazard;
  final VoidCallback onContinue;

  const HazardBottomSheet({
    super.key,
    required this.hazard,
    required this.onContinue,
  });

  static void show(
    BuildContext context, {
    required HazardModel hazard,
    required VoidCallback onContinue,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => HazardBottomSheet(
        hazard: hazard,
        onContinue: onContinue,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final isUrdu = language == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final control = hazard.controlLevel;

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppColors.safetyGreen.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Top Bar with Found Badge & Language Switcher
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.safetyGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.safetyGreen, width: 1.2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 16, color: AppColors.safetyGreen),
                      const SizedBox(width: 6),
                      BilingualText(
                        textEn: 'Hazard Identified!',
                        textUr: 'خطرہ کامیابی سے تلاش کر لیا گیا!',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.safetyGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const LanguageSwitchButton(isCompact: true),
              ],
            ),
            const SizedBox(height: 14),

            // Hazard Name
            BilingualText(
              textEn: hazard.nameEn,
              textUr: hazard.nameUr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),

            // 1. Danger Box: Why it is hazardous
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.dangerRed.withOpacity(0.4), width: 1),
              ),
              child: Column(
                crossAxisAlignment:
                    isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 18, color: AppColors.dangerRed),
                      const SizedBox(width: 8),
                      BilingualText(
                        textEn: 'Why this is dangerous:',
                        textUr: 'یہ کیوں جان لیوا اور خطرناک ہے:',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dangerRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  BilingualText(
                    textEn: hazard.reasonEn,
                    textUr: hazard.reasonUr,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Control Measure Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded,
                          size: 18, color: AppColors.safetyGreen),
                      const SizedBox(width: 8),
                      BilingualText(
                        textEn: 'Required Control Measure:',
                        textUr: 'لازمی حفاظتی تدارک (کنٹرول):',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.safetyGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  BilingualText(
                    textEn: hazard.controlEn,
                    textUr: hazard.controlUr,
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 3. Hierarchy of Controls Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: control.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: control.color, width: 1.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: control.color,
                    child: Text(
                      '${control.rank}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hierarchy of Controls: ${control.getName(language)}',
                          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: control.color,
                            fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                          ),
                        ),
                        Text(
                          control.getDescription(language),
                          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Continue Button
            SafetyButton(
              text: isUrdu ? 'معائنہ جاری رکھیں' : 'Continue Inspection',
              icon: Icons.play_arrow_rounded,
              backgroundColor: AppColors.safetyYellow,
              textColor: Colors.black,
              onPressed: () {
                Navigator.pop(context);
                onContinue();
              },
            ),
          ],
        ),
      ),
    );
  }
}
