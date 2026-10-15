import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../../shared/widgets/safety_button.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/presentation/concept_card_viewer_dialog.dart';
import '../domain/hazard_model.dart';

class HazardHuntRecapDialog extends ConsumerWidget {
  final bool isVictory;
  final int score;
  final int stars;
  final int timeRemaining;
  final List<HazardModel> hazards;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const HazardHuntRecapDialog({
    super.key,
    required this.isVictory,
    required this.score,
    required this.stars,
    required this.timeRemaining,
    required this.hazards,
    required this.onRetry,
    required this.onExit,
  });

  static void show(
    BuildContext context, {
    required bool isVictory,
    required int score,
    required int stars,
    required int timeRemaining,
    required List<HazardModel> hazards,
    required VoidCallback onRetry,
    required VoidCallback onExit,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => HazardHuntRecapDialog(
        isVictory: isVictory,
        score: score,
        stars: stars,
        timeRemaining: timeRemaining,
        hazards: hazards,
        onRetry: onRetry,
        onExit: onExit,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final isUrdu = language == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final foundHazards = hazards.where((h) => h.isDiscovered).toList();
    final missedHazards = hazards.where((h) => !h.isDiscovered).toList();

    return Dialog(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Language Switcher
              Align(
                alignment: isUrdu ? Alignment.centerLeft : Alignment.centerRight,
                child: const LanguageSwitchButton(isCompact: true),
              ),
              const SizedBox(height: 8),

              // Status Icon & Title
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isVictory ? AppColors.safetyGreen : AppColors.dangerRed)
                        .withOpacity(0.15),
                  ),
                  child: Icon(
                    isVictory ? Icons.verified_user_rounded : Icons.report_problem_rounded,
                    size: 54,
                    color: isVictory ? AppColors.safetyGreen : AppColors.dangerRed,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              BilingualText(
                textEn: isVictory
                    ? 'Site Inspection Cleared!'
                    : 'Inspection Halted! Safety Compromised',
                textUr: isVictory
                    ? 'سائٹ کا معائنہ کامیاب رہا!'
                    : 'معائنہ منسوخ! حفاظتی پروٹوکول ٹوٹ گیا',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Star Rating
              if (isVictory) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isEarned = index < stars;
                    return Icon(
                      Icons.star_rounded,
                      size: 38,
                      color: isEarned ? const Color(0xFFF59E0B) : Colors.grey.withOpacity(0.3),
                    );
                  }),
                ),
                const SizedBox(height: 12),
              ],

              // Score Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol(
                      labelEn: 'Score',
                      labelUr: 'اسکور',
                      value: '$score',
                      color: AppColors.safetyYellow,
                    ),
                    _buildStatCol(
                      labelEn: 'Found',
                      labelUr: 'تلاش شدہ',
                      value: '${foundHazards.length}/${hazards.length}',
                      color: AppColors.safetyGreen,
                    ),
                    _buildStatCol(
                      labelEn: 'Time Left',
                      labelUr: 'باقی وقت',
                      value: '${timeRemaining}s',
                      color: AppColors.infoBlue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Recap of Hazards Discovered
              BilingualText(
                textEn: 'Site Hazard Inspection Log',
                textUr: 'سائٹ کے خطرات کی لاگ بک',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),

              ...hazards.map((h) {
                final isFound = h.isDiscovered;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isFound
                          ? AppColors.safetyGreen.withOpacity(0.5)
                          : AppColors.dangerRed.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFound ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: isFound ? AppColors.safetyGreen : AppColors.dangerRed,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: BilingualText(
                          textEn: h.nameEn,
                          textUr: h.nameUr,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (h.conceptId != null) ...[
                        InkWell(
                          onTap: () {
                            final conceptsAsync = ref.read(
                              conceptCardsListProvider('11111111-1111-1111-1111-111111111108'),
                            );
                            conceptsAsync.whenData((list) {
                              final concept = list.firstWhere(
                                (c) => c.id == h.conceptId,
                                orElse: () => list.first,
                              );
                              ConceptCardViewerDialog.show(context, concept);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.safetyYellow.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 14,
                              color: AppColors.safetyYellow,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Action Buttons
              SafetyButton(
                text: isVictory
                    ? (isUrdu ? 'دوبارہ مشق کریں' : 'Inspect Again')
                    : (isUrdu ? 'دوبارہ کوشش کریں' : 'Try Again'),
                icon: Icons.refresh_rounded,
                backgroundColor: AppColors.safetyYellow,
                textColor: Colors.black,
                onPressed: () {
                  Navigator.pop(context);
                  onRetry();
                },
              ),
              const SizedBox(height: 10),

              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onExit();
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  ),
                ),
                child: BilingualText(
                  textEn: 'Exit to Dashboard',
                  textUr: 'ڈیش بورڈ پر واپس جائیں',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol({
    required String labelEn,
    required String labelUr,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        BilingualText(
          textEn: labelEn,
          textUr: labelUr,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}
