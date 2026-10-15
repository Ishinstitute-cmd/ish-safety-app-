import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../../shared/widgets/safety_button.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/presentation/concept_card_viewer_dialog.dart';
import '../../quiz/domain/question_model.dart';
import '../data/review_queue_repository.dart';
import '../domain/review_item_model.dart';

class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openConceptCard(String conceptId) async {
    final concepts = await ref.read(conceptCardsProvider(null).future);
    final card = concepts.firstWhere(
      (c) => c.id == conceptId,
      orElse: () => concepts.first,
    );
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => ConceptCardViewerDialog(concept: card),
    );
  }

  void _startSingleQuestionPractice(ReviewItemModel item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SingleQuestionPracticeModal(
        item: item,
        onAnswerSubmitted: (bool isCorrect) async {
          await ref.read(reviewQueueRepositoryProvider).recordAnswer(
                questionId: item.questionId,
                isCorrect: isCorrect,
                currentCorrectCount: item.correctCount,
              );
          ref.invalidate(reviewQueueItemsProvider);
        },
      ),
    );
  }

  void _startDueDrill(List<ReviewItemModel> dueItems) {
    if (dueItems.isEmpty) return;

    int currentIndex = 0;
    void showNextInDrill() {
      if (currentIndex >= dueItems.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: BilingualText(
              textEn: 'Review drill completed! Well done!',
              textUr: 'دہرائی سیشن مکمل ہو گیا! شاباش!',
            ),
            backgroundColor: AppColors.safetyGreen,
          ),
        );
        ref.invalidate(reviewQueueItemsProvider);
        return;
      }

      final item = dueItems[currentIndex];
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (context) => _SingleQuestionPracticeModal(
          item: item,
          drillStep: '${currentIndex + 1}/${dueItems.length}',
          onAnswerSubmitted: (bool isCorrect) async {
            await ref.read(reviewQueueRepositoryProvider).recordAnswer(
                  questionId: item.questionId,
                  isCorrect: isCorrect,
                  currentCorrectCount: item.correctCount,
                );
            currentIndex++;
            if (mounted) {
              Future.microtask(() => showNextInDrill());
            }
          },
        ),
      );
    }

    showNextInDrill();
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isUrdu = currentLang == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemsAsync = ref.watch(reviewQueueItemsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Column(
          crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            BilingualText(
              textEn: 'Spaced Review Queue',
              textUr: 'وقفہ دار دہرائی کی فہرست',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            Text(
              isUrdu ? '1، 3، 7 روزہ سائنسی نظام' : '1, 3, 7 Day Retention System',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: LanguageSwitchButton(isCompact: true),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.safetyYellowDark,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          indicatorColor: AppColors.safetyYellow,
          indicatorWeight: 3,
          tabs: [
            Tab(text: isUrdu ? 'تمام سوالات' : 'All Items'),
            Tab(text: isUrdu ? 'آج واجب الادا' : 'Due Today'),
            Tab(text: isUrdu ? 'آئندہ دہرائی' : 'Upcoming'),
            Tab(text: isUrdu ? 'مکمل مہارت' : 'Graduated'),
          ],
        ),
      ),
      body: itemsAsync.when(
        data: (items) {
          final dueItems = items.where((i) => i.isDue).toList();
          final upcomingItems = items.where((i) => i.isUpcoming).toList();
          final graduatedItems = items.where((i) => i.isMastered).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(reviewQueueItemsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Spaced Repetition Methodology Card
                  _buildAlgorithmBanner(context, isUrdu, isDark),
                  const SizedBox(height: 16),

                  // 2. Metrics Quick Bar
                  _buildMetricsRow(
                    context,
                    total: items.length,
                    due: dueItems.length,
                    upcoming: upcomingItems.length,
                    graduated: graduatedItems.length,
                    isUrdu: isUrdu,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),

                  // 3. Prominent CTA to start due drill
                  if (dueItems.isNotEmpty)
                    SafetyButton(
                      textEn: 'Start Review Drill (${dueItems.length} Due)',
                      textUr: 'دہرائی سیشن شروع کریں (${dueItems.length} باقی)',
                      icon: Icons.play_arrow_rounded,
                      backgroundColor: AppColors.safetyYellow,
                      textColor: Colors.black,
                      onPressed: () => _startDueDrill(dueItems),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.safetyGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(color: AppColors.safetyGreen.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.safetyGreen, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: BilingualText(
                              textEn: 'All caught up! No questions due for review right now.',
                              textUr: 'سب مکمل! فی الحال کوئی سوال دہرائی کے لیے واجب نہیں۔',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.safetyGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 4. Tab Filtered List
                  _buildFilteredList(
                    context,
                    items: _getActiveItems(items, dueItems, upcomingItems, graduatedItems),
                    isUrdu: isUrdu,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.safetyYellow),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text('Error loading review queue: $err'),
          ),
        ),
      ),
    );
  }

  List<ReviewItemModel> _getActiveItems(
    List<ReviewItemModel> all,
    List<ReviewItemModel> due,
    List<ReviewItemModel> upcoming,
    List<ReviewItemModel> graduated,
  ) {
    switch (_activeTabIndex) {
      case 1:
        return due;
      case 2:
        return upcoming;
      case 3:
        return graduated;
      default:
        return all;
    }
  }

  Widget _buildAlgorithmBanner(BuildContext context, bool isUrdu, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.infoBlue.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology_rounded, color: AppColors.infoBlue, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: BilingualText(
                  textEn: 'How Spaced Repetition Works',
                  textUr: 'وقفہ دار دہرائی کیسے کام کرتی ہے؟',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          BilingualText(
            textEn:
                'Wrong answers enter your queue and return in 1 day. Answer correctly twice consecutively to graduate to Mastered!',
            textUr:
                'غلط جوابات اس فہرست میں آتے ہیں اور 1 دن بعد دوبارہ پوچھے جاتے ہیں۔ مسلسل دو بار درست جواب دے کر مکمل مہارت حاصل کریں!',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // Flow steps
          Row(
            children: [
              _buildStepPill('1. Mistake', '1 دن', Colors.red, isUrdu),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
              _buildStepPill('2. Review (3d)', '3 دن', Colors.orange, isUrdu),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
              _buildStepPill('3. Mastered', 'مکمل', AppColors.safetyGreen, isUrdu),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepPill(String titleEn, String titleUr, Color color, bool isUrdu) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            isUrdu ? titleUr : titleEn,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsRow(
    BuildContext context, {
    required int total,
    required int due,
    required int upcoming,
    required int graduated,
    required bool isUrdu,
    required bool isDark,
  }) {
    return Row(
      children: [
        _buildMetricBox('Due Now', 'واجب الادا', '$due', AppColors.dangerRed, isUrdu, isDark),
        const SizedBox(width: 8),
        _buildMetricBox('Upcoming', 'آئندہ', '$upcoming', AppColors.infoBlue, isUrdu, isDark),
        const SizedBox(width: 8),
        _buildMetricBox('Graduated', 'کامیاب', '$graduated', AppColors.safetyGreen, isUrdu, isDark),
      ],
    );
  }

  Widget _buildMetricBox(
    String labelEn,
    String labelUr,
    String value,
    Color color,
    bool isUrdu,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceCard : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            BilingualText(
              textEn: labelEn,
              textUr: labelUr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredList(
    BuildContext context, {
    required List<ReviewItemModel> items,
    required bool isUrdu,
    required bool isDark,
  }) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 56,
              color: AppColors.safetyGreen.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            BilingualText(
              textEn: 'No items in this filter',
              textUr: 'اس کیٹیگری میں کوئی سوال نہیں ہے',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildReviewCard(context, item, isUrdu, isDark);
      },
    );
  }

  Widget _buildReviewCard(
    BuildContext context,
    ReviewItemModel item,
    bool isUrdu,
    bool isDark,
  ) {
    final isDue = item.isDue;
    final isGraduated = item.isMastered;

    Color badgeColor;
    String badgeTextEn;
    String badgeTextUr;

    if (isGraduated) {
      badgeColor = AppColors.safetyGreen;
      badgeTextEn = 'Graduated (Mastered)';
      badgeTextUr = 'مکمل مہارت';
    } else if (isDue) {
      badgeColor = AppColors.dangerRed;
      badgeTextEn = 'Due Today';
      badgeTextUr = 'آج واجب ہے';
    } else {
      badgeColor = AppColors.infoBlue;
      final days = item.nextReviewAt.difference(DateTime.now()).inDays + 1;
      badgeTextEn = 'In $days day${days > 1 ? 's' : ''}';
      badgeTextUr = '$days دن بعد';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isDue
              ? AppColors.dangerRed.withOpacity(0.4)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isDue ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Header: Interval Stage and Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGraduated
                          ? Icons.verified_rounded
                          : (isDue ? Icons.alarm_rounded : Icons.schedule_rounded),
                      color: badgeColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    BilingualText(
                      textEn: badgeTextEn,
                      textUr: badgeTextUr,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Mastery Dots (0/2, 1/2, 2/2)
              Row(
                children: [
                  Text(
                    isUrdu ? 'مسلسل درست:' : 'Consecutive:',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 4),
                  _buildMasteryDot(item.correctCount >= 1),
                  const SizedBox(width: 3),
                  _buildMasteryDot(item.correctCount >= 2),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Question Text
          BilingualText(
            textEn: item.question.questionEn,
            textUr: item.question.questionUr,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons: Concept Card Link & Practice Button
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.menu_book_rounded, size: 16),
                  label: BilingualText(
                    textEn: 'Concept Card',
                    textUr: 'سبق پڑھیں',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  onPressed: () => _openConceptCard(item.conceptId),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: BilingualText(
                    textEn: 'Practice',
                    textUr: 'مشق کریں',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safetyYellow,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  onPressed: () => _startSingleQuestionPractice(item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMasteryDot(bool active) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.safetyGreen : Colors.grey.withOpacity(0.3),
        border: Border.all(
          color: active ? AppColors.safetyGreen : Colors.grey.withOpacity(0.5),
          width: 1,
        ),
      ),
    );
  }
}

class _SingleQuestionPracticeModal extends StatefulWidget {
  final ReviewItemModel item;
  final String? drillStep;
  final Future<void> Function(bool isCorrect) onAnswerSubmitted;

  const _SingleQuestionPracticeModal({
    required this.item,
    this.drillStep,
    required this.onAnswerSubmitted,
  });

  @override
  State<_SingleQuestionPracticeModal> createState() => _SingleQuestionPracticeModalState();
}

class _SingleQuestionPracticeModalState extends State<_SingleQuestionPracticeModal> {
  String? _selectedOption;
  bool _hasAnswered = false;

  void _onSelect(String option) {
    if (_hasAnswered) return;
    setState(() {
      _selectedOption = option;
      _hasAnswered = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final question = widget.item.question;
    final isCorrect = _selectedOption?.toLowerCase() == question.correctOption.toLowerCase();

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (widget.drillStep != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.safetyYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Drill: ${widget.drillStep}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  )
                else
                  const BilingualText(
                    textEn: 'Review Practice',
                    textUr: 'دہرائی کی مشق',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question
            BilingualText(
              textEn: question.questionEn,
              textUr: question.questionUr,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),

            // Options
            _buildOptionTile('a', question.optionAEn, question.optionAUr, isDark),
            _buildOptionTile('b', question.optionBEn, question.optionBUr, isDark),
            _buildOptionTile('c', question.optionCEn, question.optionCUr, isDark),
            _buildOptionTile('d', question.optionDEn, question.optionDUr, isDark),

            // Immediate Feedback & Spaced Repetition notice
            if (_hasAnswered) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? AppColors.safetyGreen.withOpacity(0.12)
                      : AppColors.dangerRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                  border: Border.all(
                    color: isCorrect ? AppColors.safetyGreen : AppColors.dangerRed,
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: isCorrect ? AppColors.safetyGreen : AppColors.dangerRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        BilingualText(
                          textEn: isCorrect
                              ? 'Correct! Interval extended.'
                              : 'Incorrect! Reappearing tomorrow.',
                          textUr: isCorrect
                              ? 'شاندار! وقفہ بڑھا دیا گیا۔'
                              : 'غلط! کل دوبارہ دہرایا جائے گا۔',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isCorrect ? AppColors.safetyGreen : AppColors.dangerRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    BilingualText(
                      textEn: question.explanationEn,
                      textUr: question.explanationUr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SafetyButton(
                textEn: 'Continue',
                textUr: 'آگے بڑھیں',
                backgroundColor: AppColors.safetyYellow,
                textColor: Colors.black,
                onPressed: () async {
                  Navigator.of(context).pop();
                  await widget.onAnswerSubmitted(isCorrect);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String key, String textEn, String textUr, bool isDark) {
    final isSelected = _selectedOption == key;
    final isTargetCorrect = key.toLowerCase() == widget.item.question.correctOption.toLowerCase();

    Color border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    Color bg = isDark ? AppColors.darkSurfaceCard : Colors.white;

    if (_hasAnswered) {
      if (isTargetCorrect) {
        border = AppColors.safetyGreen;
        bg = AppColors.safetyGreen.withOpacity(0.12);
      } else if (isSelected) {
        border = AppColors.dangerRed;
        bg = AppColors.dangerRed.withOpacity(0.12);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _onSelect(key),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: border, width: isSelected || (_hasAnswered && isTargetCorrect) ? 1.5 : 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.safetyYellow : Colors.grey.withOpacity(0.2),
                ),
                child: Text(
                  key.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BilingualText(
                  textEn: textEn,
                  textUr: textUr,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
