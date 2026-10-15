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
import '../domain/question_model.dart';

class QuizResultScreen extends ConsumerWidget {
  final int score;
  final int totalQuestions;
  final List<QuestionModel> missedQuestions;
  final String? categoryId;
  final String categoryTitleEn;
  final String categoryTitleUr;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.missedQuestions,
    this.categoryId,
    required this.categoryTitleEn,
    required this.categoryTitleUr,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final isUrdu = language == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double percentage = totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;
    final bool passed = percentage >= 70;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: BilingualText(
            textEn: 'Quiz Results',
            textUr: 'کوئز کے نتائج',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: LanguageSwitchButton(isCompact: true),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score Hero Card
              Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: passed ? AppColors.safetyGreen : AppColors.safetyYellow,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (passed ? AppColors.safetyGreen : AppColors.safetyYellow)
                          .withOpacity(0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (passed ? AppColors.safetyGreen : AppColors.safetyYellow)
                            .withOpacity(0.15),
                      ),
                      child: Icon(
                        passed ? Icons.emoji_events_rounded : Icons.psychology_rounded,
                        size: 54,
                        color: passed ? AppColors.safetyGreen : AppColors.safetyYellow,
                      ),
                    ),
                    const SizedBox(height: 14),
                    BilingualText(
                      textEn: passed ? 'Excellence in Safety!' : 'Keep Learning!',
                      textUr: passed ? 'شاندار کارکردگی!' : 'مزید مطالعہ جاری رکھیں!',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    BilingualText(
                      textEn: categoryTitleEn,
                      textUr: categoryTitleUr,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: passed ? AppColors.safetyGreen : AppColors.safetyYellow,
                          ),
                        ),
                        Text(
                          ' / $totalQuestions',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${percentage.toInt()}% Accuracy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Weak Concepts & Spaced Repetition Notice
              if (missedQuestions.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.safetyYellow.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.safetyYellow, width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.repeat_rounded, color: AppColors.safetyYellow, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: BilingualText(
                              textEn: 'Added to Spaced Repetition Queue',
                              textUr: 'دہرائی کی فہرست (Spaced Repetition) میں شامل',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.safetyYellow,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      BilingualText(
                        textEn:
                            'These concepts will reappear after 1, 3, and 7 days until answered correctly twice.',
                        textUr:
                            'یہ سوالات 1، 3 اور 7 دنوں بعد دوبارہ دہرائے جائیں گے جب تک آپ مسلسل دو بار درست جواب نہ دیں۔',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Section Title: Missed Questions
                BilingualText(
                  textEn: 'Review Weak Concepts (${missedQuestions.length})',
                  textUr: 'کمزور تصورات کی دہرائی (${missedQuestions.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),

                ...missedQuestions.map((q) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        BilingualText(
                          textEn: q.questionEn,
                          textUr: q.questionUr,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.safetyGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: AppColors.safetyGreen, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Correct: ${_getCorrectText(q, language)}',
                                  textDirection:
                                      isUrdu ? TextDirection.rtl : TextDirection.ltr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.safetyGreen,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (q.conceptId != null) ...[
                          TextButton.icon(
                            onPressed: () {
                              final conceptsAsync = ref.read(
                                conceptCardsListProvider(q.categoryId),
                              );
                              conceptsAsync.whenData((list) {
                                final concept = list.firstWhere(
                                  (c) => c.id == q.conceptId,
                                  orElse: () => list.first,
                                );
                                ConceptCardViewerDialog.show(context, concept);
                              });
                            },
                            icon: const Icon(Icons.menu_book_rounded,
                                size: 16, color: AppColors.safetyYellow),
                            label: BilingualText(
                              textEn: 'Open Concept Card Lesson',
                              textUr: 'متعلقہ سبق کا کارڈ پڑھیں',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.safetyYellow,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.safetyGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.safetyGreen, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: AppColors.safetyGreen, size: 36),
                      const SizedBox(width: 14),
                      Expanded(
                        child: BilingualText(
                          textEn: 'Flawless! All 10 concepts answered correctly.',
                          textUr: 'بے مثال! تمام 10 سوالات کے بالکل درست جواب دیے۔',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Done Button
              SafetyButton(
                text: isUrdu ? 'واپس ڈیش بورڈ پر جائیں' : 'Back to Dashboard',
                icon: Icons.home_rounded,
                backgroundColor: AppColors.safetyYellow,
                textColor: Colors.black,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getCorrectText(QuestionModel q, AppLanguage lang) {
    switch (q.correctOption) {
      case 'a':
        return q.getOptionA(lang);
      case 'b':
        return q.getOptionB(lang);
      case 'c':
        return q.getOptionC(lang);
      case 'd':
      default:
        return q.getOptionD(lang);
    }
  }
}
