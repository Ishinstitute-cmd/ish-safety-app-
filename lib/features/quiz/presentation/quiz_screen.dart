import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/utils/spaced_repetition.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../../shared/widgets/safety_button.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/presentation/concept_card_viewer_dialog.dart';
import '../data/quiz_repository.dart';
import '../domain/question_model.dart';
import 'quiz_result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String categoryTitleEn;
  final String categoryTitleUr;
  final String quizType; // 'daily' | 'test' | 'practice'

  const QuizScreen({
    super.key,
    this.categoryId,
    this.categoryTitleEn = 'Daily Safety Drill',
    this.categoryTitleUr = 'روزانہ سیفٹی ڈرل',
    this.quizType = 'test',
  });

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<QuestionModel> _questions = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _selectedOption;
  bool _hasAnswered = false;
  int _score = 0;
  final List<QuestionModel> _missedQuestions = [];

  // 20-Second Countdown Timer
  Timer? _countdownTimer;
  int _secondsLeft = 20;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final repo = ref.read(quizRepositoryProvider);
    final fetched = await repo.getQuestions(
      categoryId: widget.categoryId,
      limit: widget.quizType == 'daily' ? 5 : 10,
    );

    if (mounted) {
      setState(() {
        _questions = fetched;
        _isLoading = false;
      });
      _startTimer();
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _secondsLeft = 20;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        // Time ran out!
        timer.cancel();
        _onTimeExpired();
      }
    });
  }

  void _onTimeExpired() {
    if (_hasAnswered) return;

    final currentQuestion = _questions[_currentIndex];
    setState(() {
      _secondsLeft = 0;
      _hasAnswered = true;
      _missedQuestions.add(currentQuestion);
    });

    // Save to spaced repetition queue
    _saveToReviewQueue(currentQuestion);
  }

  void _selectOption(String option) {
    if (_hasAnswered) return;
    _countdownTimer?.cancel();

    final currentQuestion = _questions[_currentIndex];
    final isCorrect = option.toLowerCase() == currentQuestion.correctOption.toLowerCase();

    setState(() {
      _selectedOption = option;
      _hasAnswered = true;
      if (isCorrect) {
        _score++;
      } else {
        _missedQuestions.add(currentQuestion);
      }
    });

    if (!isCorrect) {
      _saveToReviewQueue(currentQuestion);
    }
  }

  void _saveToReviewQueue(QuestionModel question) async {
    final nextReview = SpacedRepetitionHelper.calculateNextReview(
      consecutiveCorrect: 0,
      isAnswerCorrect: false,
    );

    await LocalCacheService.addToReviewQueue(question.id, {
      'question_id': question.id,
      'concept_id': question.conceptId,
      'correct_count': 0,
      'incorrect_count': 1,
      'status': 'review',
      'next_review_at': nextReview.toIso8601String(),
      'last_reviewed_at': DateTime.now().toIso8601String(),
    });
  }

  void _goToNextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _hasAnswered = false;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() async {
    _countdownTimer?.cancel();

    // Submit score to Supabase
    final repo = ref.read(quizRepositoryProvider);
    await repo.submitScore(
      categoryId: widget.categoryId,
      score: _score,
      totalQuestions: _questions.length,
      quizType: widget.quizType,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => QuizResultScreen(
          score: _score,
          totalQuestions: _questions.length,
          missedQuestions: _missedQuestions,
          categoryId: widget.categoryId,
          categoryTitleEn: widget.categoryTitleEn,
          categoryTitleUr: widget.categoryTitleUr,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final isUrdu = language == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: BilingualText(
            textEn: widget.categoryTitleEn,
            textUr: widget.categoryTitleUr,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.safetyYellow),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: BilingualText(
            textEn: widget.categoryTitleEn,
            textUr: widget.categoryTitleUr,
          ),
        ),
        body: Center(
          child: BilingualText(
            textEn: 'No questions available for this drill yet.',
            textUr: 'اس ڈرل کے لیے فی الحال کوئی سوالات موجود نہیں۔',
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentIndex];
    final bool isCorrect = _selectedOption == currentQuestion.correctOption;
    final double timerPercent = _secondsLeft / 20.0;
    final Color timerColor = _secondsLeft <= 5
        ? AppColors.dangerRed
        : (_secondsLeft <= 10 ? AppColors.safetyYellow : AppColors.safetyGreen);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: BilingualText(
          textEn: widget.categoryTitleEn,
          textUr: widget.categoryTitleUr,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: LanguageSwitchButton(isCompact: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress & Timer Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Question Counter Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.safetyYellow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isUrdu
                          ? 'سوال ${_currentIndex + 1} از ${_questions.length}'
                          : 'Question ${_currentIndex + 1} of ${_questions.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ),

                  // Circular 20-Second Countdown Timer
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: timerPercent,
                              strokeWidth: 3.0,
                              backgroundColor: isDark ? Colors.white12 : Colors.black12,
                              valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                            ),
                            Text(
                              '$_secondsLeft',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: timerColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isUrdu ? 'سیکنڈ' : 'sec',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Question & Options
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment:
                      isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Question text
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: BilingualText(
                        textEn: currentQuestion.questionEn,
                        textUr: currentQuestion.questionUr,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Options A, B, C, D
                    _buildOptionTile('a', currentQuestion.getOptionA(language), currentQuestion.correctOption, isUrdu, isDark),
                    _buildOptionTile('b', currentQuestion.getOptionB(language), currentQuestion.correctOption, isUrdu, isDark),
                    _buildOptionTile('c', currentQuestion.getOptionC(language), currentQuestion.correctOption, isUrdu, isDark),
                    _buildOptionTile('d', currentQuestion.getOptionD(language), currentQuestion.correctOption, isUrdu, isDark),

                    // Instant Feedback Box (Appears immediately after tap or time-out)
                    if (_hasAnswered) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppColors.safetyGreen.withOpacity(0.12)
                              : AppColors.dangerRed.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCorrect ? AppColors.safetyGreen : AppColors.dangerRed,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment:
                              isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                  color: isCorrect ? AppColors.safetyGreen : AppColors.dangerRed,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: BilingualText(
                                    textEn: isCorrect
                                        ? 'Correct Answer! Well done'
                                        : (_secondsLeft == 0 ? 'Time Expired!' : 'Incorrect!'),
                                    textUr: isCorrect
                                        ? 'شاباش! بالکل درست جواب'
                                        : (_secondsLeft == 0 ? 'وقت ختم ہو گیا!' : 'غلط جواب!'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: isCorrect ? AppColors.safetyGreen : AppColors.dangerRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            BilingualText(
                              textEn: currentQuestion.explanationEn,
                              textUr: currentQuestion.explanationUr,
                              style: const TextStyle(fontSize: 13, height: 1.5),
                            ),
                            const SizedBox(height: 14),

                            // Link to Concept Card
                            if (currentQuestion.conceptId != null) ...[
                              ElevatedButton.icon(
                                onPressed: () {
                                  final conceptsAsync = ref.read(
                                    conceptCardsListProvider(currentQuestion.categoryId),
                                  );
                                  conceptsAsync.whenData((list) {
                                    final concept = list.firstWhere(
                                      (c) => c.id == currentQuestion.conceptId,
                                      orElse: () => list.first,
                                    );
                                    ConceptCardViewerDialog.show(context, concept);
                                  });
                                },
                                icon: const Icon(Icons.menu_book_rounded,
                                    size: 16, color: Colors.black),
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
                                  minimumSize: const Size.fromHeight(40),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Continue Action
            if (_hasAnswered) ...[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SafetyButton(
                  text: _currentIndex < _questions.length - 1
                      ? (isUrdu ? 'اگلا سوال' : 'Next Question')
                      : (isUrdu ? 'نتائج دیکھیں' : 'View Results'),
                  icon: _currentIndex < _questions.length - 1
                      ? (isUrdu ? Icons.arrow_back : Icons.arrow_forward)
                      : Icons.assessment_rounded,
                  backgroundColor: AppColors.safetyYellow,
                  textColor: Colors.black,
                  onPressed: _goToNextQuestion,
                ),
              ),
            ],
          ],
        ),
      ),
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
    final isCorrectOption = optionKey.toLowerCase() == correctOption.toLowerCase();

    Color borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    Color bgColor = isDark ? AppColors.darkSurfaceCard : Colors.white;

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
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: _hasAnswered ? null : () => _selectOption(optionKey),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: isSelected
                    ? AppColors.safetyYellow
                    : (isDark ? Colors.white12 : Colors.black.withOpacity(0.06)),
                child: Text(
                  optionKey.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  style: TextStyle(
                    fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                    fontSize: 14,
                    height: isUrdu ? 1.9 : 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (_hasAnswered) ...[
                if (isCorrectOption)
                  const Icon(Icons.check_circle_rounded, color: AppColors.safetyGreen, size: 22)
                else if (isSelected)
                  const Icon(Icons.cancel_rounded, color: AppColors.dangerRed, size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
