import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../../shared/widgets/mastery_progress_bar.dart';
import '../../../shared/widgets/safety_button.dart';
import '../../quiz/data/quiz_repository.dart';
import '../../quiz/domain/question_model.dart';
import '../../quiz/presentation/quiz_screen.dart';
import '../data/categories_repository.dart';
import '../domain/category_model.dart';
import '../domain/concept_card_model.dart';
import '../../flashcards/presentation/flashcards_screen.dart';
import 'concept_card_viewer_dialog.dart';

class CategoryDetailScreen extends ConsumerStatefulWidget {
  final CategoryModel category;

  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends ConsumerState<CategoryDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return AppColors.safetyYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final isUrdu = language == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _hexToColor(widget.category.colorHex);
    final conceptCardsAsync = ref.watch(conceptCardsListProvider(widget.category.id));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: BilingualText(
          textEn: widget.category.titleEn,
          textUr: widget.category.titleUr,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.style_rounded),
            tooltip: 'Flashcards',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FlashcardsScreen(),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: LanguageSwitchButton(isCompact: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card with Category Mastery
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.shield_outlined, color: catColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isUrdu
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          BilingualText(
                            textEn: widget.category.titleEn,
                            textUr: widget.category.titleUr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          BilingualText(
                            textEn: widget.category.descriptionEn,
                            textUr: widget.category.descriptionUr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Mastery Bar
                MasteryProgressBar(
                  percentage: widget.category.masteryPercentage,
                  height: 8.0,
                  showLabel: true,
                  label: isUrdu ? 'اس شعبے میں مجموعی مہارت' : 'Category Overall Mastery',
                ),
              ],
            ),
          ),

          // 3 Tabs (Learn / Practice / Test)
          Container(
            color: isDark ? AppColors.darkSurface : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.safetyYellow,
              unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
              indicatorColor: AppColors.safetyYellow,
              indicatorWeight: 3.0,
              tabs: [
                Tab(
                  icon: const Icon(Icons.menu_book_rounded, size: 20),
                  text: isUrdu ? 'سیکھیں (Learn)' : 'Learn',
                ),
                Tab(
                  icon: const Icon(Icons.fitness_center_rounded, size: 20),
                  text: isUrdu ? 'مشق (Practice)' : 'Practice',
                ),
                Tab(
                  icon: const Icon(Icons.quiz_rounded, size: 20),
                  text: isUrdu ? 'امتحان (Test)' : 'Test',
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. LEARN TAB (Concept Cards)
                _buildLearnTab(conceptCardsAsync, catColor, isUrdu, isDark),

                // 2. PRACTICE TAB (Casual questions with lesson prompt)
                _buildPracticeTab(conceptCardsAsync, catColor, isUrdu, isDark),

                // 3. TEST TAB (Timed exam launcher)
                _buildTestTab(catColor, isUrdu, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. LEARN TAB ---
  Widget _buildLearnTab(
    AsyncValue<List<ConceptCardModel>> conceptsAsync,
    Color catColor,
    bool isUrdu,
    bool isDark,
  ) {
    return conceptsAsync.when(
      data: (concepts) {
        if (concepts.isEmpty) {
          return Center(
            child: BilingualText(
              textEn: 'No lessons available for this topic yet.',
              textUr: 'اس شعبے کے لیے اسباق جلد شامل کیے جائیں گے۔',
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: concepts.length,
          itemBuilder: (context, index) {
            final concept = concepts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: InkWell(
                onTap: () => ConceptCardViewerDialog.show(context, concept, color: catColor),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: catColor.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.timer_outlined, size: 13, color: catColor),
                                const SizedBox(width: 4),
                                Text(
                                  isUrdu
                                      ? '${concept.readTimeMinutes} منٹ کا مطالعہ'
                                      : '${concept.readTimeMinutes} min lesson',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: catColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isUrdu
                                ? Icons.arrow_back_ios_rounded
                                : Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: isDark ? Colors.white38 : Colors.black26,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      BilingualText(
                        textEn: concept.titleEn,
                        textUr: concept.titleUr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      BilingualText(
                        textEn: concept.bodyEn,
                        textUr: concept.bodyUr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.touch_app_outlined,
                              size: 15, color: AppColors.safetyYellow),
                          const SizedBox(width: 6),
                          BilingualText(
                            textEn: 'Tap to open full lesson card',
                            textUr: 'مکمل سبق پڑھنے کے لیے ٹیپ کریں',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.safetyYellow,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.safetyYellow),
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  // --- 2. PRACTICE TAB ---
  Widget _buildPracticeTab(
    AsyncValue<List<ConceptCardModel>> conceptsAsync,
    Color catColor,
    bool isUrdu,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment:
            isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // "Read Lesson First" prompt banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.safetyYellow.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.safetyYellow, width: 1.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: AppColors.safetyYellow, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      BilingualText(
                        textEn: 'Read the lesson first!',
                        textUr: 'پہلے سبق کو لازمی پڑھیں!',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      BilingualText(
                        textEn: 'Understanding the concept gives you genuine recall rather than guessing.',
                        textUr: 'کانسیپٹ کو سمجھنے سے تکے لگانے کے بجائے پائیدار یادداشت بنتی ہے۔',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _tabController.animateTo(0);
                  },
                  child: BilingualText(
                    textEn: 'Open',
                    textUr: 'کھولیں',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Interactive Practice MCQ Item
          _InteractivePracticeQuestion(
            categoryId: widget.category.id,
            onOpenLesson: (conceptId) {
              conceptsAsync.whenData((concepts) {
                final found = concepts.firstWhere(
                  (c) => c.id == conceptId,
                  orElse: () => concepts.first,
                );
                ConceptCardViewerDialog.show(context, found, color: catColor);
              });
            },
          ),
        ],
      ),
    );
  }

  // --- 3. TEST TAB ---
  Widget _buildTestTab(Color catColor, bool isUrdu, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.safetyYellow.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.timer_rounded, size: 48, color: AppColors.safetyYellow),
                ),
                const SizedBox(height: 16),
                BilingualText(
                  textEn: '10-Question Timed Safety Test',
                  textUr: '10 سوالات پر مشتمل وقتی سیفٹی ٹیسٹ',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                BilingualText(
                  textEn: 'Test your exam readiness under time pressure.',
                  textUr: 'امتحانی ماحول میں وقت کے ساتھ اپنی تیاری کی جانچ کریں۔',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Rules
                _buildRuleItem(
                  icon: Icons.access_time_rounded,
                  titleEn: '20 Seconds per Question',
                  titleUr: 'ہر سوال کے لیے 20 سیکنڈ',
                  isUrdu: isUrdu,
                ),
                _buildRuleItem(
                  icon: Icons.question_answer_rounded,
                  titleEn: 'Instant Feedback with Explanation',
                  titleUr: 'ہر جواب کے بعد فوری تفصیلی وضاحت',
                  isUrdu: isUrdu,
                ),
                _buildRuleItem(
                  icon: Icons.repeat_rounded,
                  titleEn: 'Wrong answers go to Review Queue (1, 3, 7 days)',
                  titleUr: 'غلط جوابات خودکار دہرائی کی فہرست میں شامل ہوں گے',
                  isUrdu: isUrdu,
                ),
                const SizedBox(height: 24),

                // Start Test Button
                SafetyButton(
                  text: isUrdu ? 'امتحان شروع کریں' : 'Start Timed Test',
                  icon: Icons.play_arrow_rounded,
                  backgroundColor: AppColors.safetyYellow,
                  textColor: Colors.black,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QuizScreen(
                          categoryId: widget.category.id,
                          categoryTitleEn: widget.category.titleEn,
                          categoryTitleUr: widget.category.titleUr,
                          quizType: 'test',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem({
    required IconData icon,
    required String titleEn,
    required String titleUr,
    required bool isUrdu,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.safetyGreen),
          const SizedBox(width: 10),
          Expanded(
            child: BilingualText(
              textEn: titleEn,
              textUr: titleUr,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Interactive Single Practice Question with immediate feedback and concept link
class _InteractivePracticeQuestion extends ConsumerStatefulWidget {
  final String categoryId;
  final void Function(String? conceptId) onOpenLesson;

  const _InteractivePracticeQuestion({
    required this.categoryId,
    required this.onOpenLesson,
  });

  @override
  ConsumerState<_InteractivePracticeQuestion> createState() =>
      _InteractivePracticeQuestionState();
}

class _InteractivePracticeQuestionState
    extends ConsumerState<_InteractivePracticeQuestion> {
  String? _selectedOption;
  bool _hasAnswered = false;

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final isUrdu = language == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Load practice question
    final quizRepo = ref.watch(quizRepositoryProvider);

    return FutureBuilder<List<QuestionModel>>(
      future: quizRepo.getQuestions(categoryId: widget.categoryId, limit: 1),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final q = snapshot.data!.first;
        final isCorrect = _selectedOption == q.correctOption;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment:
                isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.infoBlue.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: BilingualText(
                      textEn: 'Practice Question',
                      textUr: 'مشقی سوال',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.infoBlue,
                      ),
                    ),
                  ),
                  Text(
                    q.difficulty.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BilingualText(
                textEn: q.questionEn,
                textUr: q.questionUr,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              // Options A, B, C, D
              _buildOptionTile('a', q.getOptionA(language), q.correctOption, isUrdu, isDark),
              _buildOptionTile('b', q.getOptionB(language), q.correctOption, isUrdu, isDark),
              _buildOptionTile('c', q.getOptionC(language), q.correctOption, isUrdu, isDark),
              _buildOptionTile('d', q.getOptionD(language), q.correctOption, isUrdu, isDark),

              // Instant Feedback & Explanation Box
              if (_hasAnswered) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? AppColors.safetyGreen.withOpacity(0.12)
                        : AppColors.dangerRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCorrect ? AppColors.safetyGreen : AppColors.dangerRed,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCorrect ? Icons.check_circle : Icons.cancel,
                            color: isCorrect ? AppColors.safetyGreen : AppColors.dangerRed,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          BilingualText(
                            textEn: isCorrect
                                ? 'Correct Answer!'
                                : 'Incorrect! Learn from this mistake:',
                            textUr: isCorrect
                                ? 'شاباش! بالکل درست جواب'
                                : 'غلط جواب! اس سے سیکھیں:',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: isCorrect ? AppColors.safetyGreen : AppColors.dangerRed,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      BilingualText(
                        textEn: q.explanationEn,
                        textUr: q.explanationUr,
                        style: const TextStyle(fontSize: 12, height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      // Button: Link to Related Concept Card
                      ElevatedButton.icon(
                        onPressed: () => widget.onOpenLesson(q.conceptId),
                        icon: const Icon(Icons.menu_book_rounded, size: 16, color: Colors.black),
                        label: BilingualText(
                          textEn: 'Review Related Concept Card',
                          textUr: 'متعلقہ سبق کا کارڈ دیکھیں',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.safetyYellow,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(38),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(
    String optionKey,
    String text,
    String correctOption,
    bool isUrdu,
    bool isDark,
  ) {
    final isSelected = _selectedOption == optionKey;
    final isCorrectOption = optionKey == correctOption;

    Color borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    Color bgColor = isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.01);

    if (_hasAnswered) {
      if (isCorrectOption) {
        borderColor = AppColors.safetyGreen;
        bgColor = AppColors.safetyGreen.withOpacity(0.15);
      } else if (isSelected) {
        borderColor = AppColors.dangerRed;
        bgColor = AppColors.dangerRed.withOpacity(0.15);
      }
    } else if (isSelected) {
      borderColor = AppColors.safetyYellow;
      bgColor = AppColors.safetyYellow.withOpacity(0.15);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: _hasAnswered
            ? null
            : () {
                setState(() {
                  _selectedOption = optionKey;
                  _hasAnswered = true;
                });
              },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 13,
                backgroundColor: isSelected ? AppColors.safetyYellow : Colors.grey.withOpacity(0.2),
                child: Text(
                  optionKey.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                    fontSize: 13,
                    height: isUrdu ? 1.8 : 1.3,
                    fontWeight: FontWeight.w500,
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
