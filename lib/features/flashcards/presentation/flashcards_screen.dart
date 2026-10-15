import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../../shared/widgets/safety_button.dart';
import '../data/flashcard_repository.dart';
import '../domain/flashcard_model.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'all';
  List<FlashcardModel> _cards = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  bool _showBack = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

  final List<Map<String, String>> _categoriesFilter = [
    {'id': 'all', 'name_en': 'All Topics', 'name_ur': 'تمام موضوعات'},
    {'id': '11111111-1111-1111-1111-111111111101', 'name_en': 'NEBOSH', 'name_ur': 'نیبوش'},
    {'id': '11111111-1111-1111-1111-111111111105', 'name_en': 'Fire Safety', 'name_ur': 'آگ سے حفاظت'},
    {'id': '11111111-1111-1111-1111-111111111104', 'name_en': 'First Aid', 'name_ur': 'ابتدائی طبی امداد'},
    {'id': '11111111-1111-1111-1111-111111111108', 'name_en': 'Construction', 'name_ur': 'تعمیراتی حفاظت'},
  ];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _loadFlashcards();
  }

  Future<void> _loadFlashcards() async {
    setState(() => _isLoading = true);
    final repo = ref.read(flashcardRepositoryProvider);
    final fetched = await repo.getFlashcards(
      categoryId: _selectedCategory == 'all' ? null : _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _cards = fetched;
        _currentIndex = 0;
        _showBack = false;
        _isLoading = false;
      });
      _flipController.reset();
    }
  }

  void _flipCard() {
    if (_flipController.isAnimating) return;
    if (_showBack) {
      _flipController.reverse();
      setState(() => _showBack = false);
    } else {
      _flipController.forward();
      setState(() => _showBack = true);
    }
  }

  void _nextCard({required bool mastered}) {
    if (_currentIndex < _cards.length - 1) {
      _flipController.reset();
      setState(() {
        _cards[_currentIndex].isMastered = mastered;
        _currentIndex++;
        _showBack = false;
      });
    } else {
      // Completed deck
      setState(() {
        _cards[_currentIndex].isMastered = mastered;
        _currentIndex++;
      });
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final isUrdu = language == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = !_isLoading && _cards.isNotEmpty && _currentIndex >= _cards.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: BilingualText(
          textEn: 'Safety Flashcards',
          textUr: 'سیفٹی فلیش کارڈز',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
            // Category Filter Chip Carousel
            Container(
              height: 46,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _categoriesFilter.length,
                itemBuilder: (context, index) {
                  final cat = _categoriesFilter[index];
                  final isSelected = _selectedCategory == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      selectedColor: AppColors.safetyYellow,
                      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
                      label: Text(
                        isUrdu ? cat['name_ur']! : cat['name_en']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                          fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = cat['id']!);
                          _loadFlashcards();
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            if (_isLoading) ...[
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.safetyYellow),
                  ),
                ),
              ),
            ] else if (_cards.isEmpty) ...[
              Expanded(
                child: Center(
                  child: BilingualText(
                    textEn: 'No flashcards available for this topic yet.',
                    textUr: 'اس موضوع کے لیے فی الحال کوئی کارڈز دستیاب نہیں۔',
                  ),
                ),
              ),
            ] else if (isCompleted) ...[
              // Deck Completed View
              Expanded(
                child: _buildCompletionView(isUrdu, isDark),
              ),
            ] else ...[
              // Progress Tracker Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.safetyYellow.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isUrdu
                          ? 'کارڈ ${_currentIndex + 1} از ${_cards.length}'
                          : 'Card ${_currentIndex + 1} of ${_cards.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                    Text(
                      _cards[_currentIndex].categoryTitleEn,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // Central Interactive 3D Flip Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GestureDetector(
                    onTap: _flipCard,
                    child: AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        final angle = _flipAnimation.value * pi;
                        final isUnder = angle > (pi / 2);

                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001) // perspective
                            ..rotateY(angle),
                          alignment: Alignment.center,
                          child: isUnder
                              ? Transform(
                                  transform: Matrix4.identity()..rotateY(pi),
                                  alignment: Alignment.center,
                                  child: _buildCardBack(
                                    _cards[_currentIndex],
                                    language,
                                    isUrdu,
                                    isDark,
                                  ),
                                )
                              : _buildCardFront(
                                  _cards[_currentIndex],
                                  language,
                                  isUrdu,
                                  isDark,
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Bottom Control Buttons (Need Review vs Mastered)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    // Need Review (Red)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _nextCard(mastered: false),
                        icon: const Icon(Icons.replay_rounded, color: AppColors.dangerRed),
                        label: BilingualText(
                          textEn: 'Need Review',
                          textUr: 'دوبارہ دہرائیں',
                          style: const TextStyle(
                            color: AppColors.dangerRed,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                          side: const BorderSide(color: AppColors.dangerRed, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Mastered (Green)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _nextCard(mastered: true),
                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                        label: BilingualText(
                          textEn: 'Mastered',
                          textUr: 'یاد ہو گیا',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.safetyGreen,
                          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- Front of the Flashcard ---
  Widget _buildCardFront(
    FlashcardModel card,
    AppLanguage language,
    bool isUrdu,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.safetyYellow.withOpacity(0.6),
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.safetyYellow.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Topic Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.safetyYellow.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              isUrdu ? card.categoryTitleUr : card.categoryTitleEn,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD97706),
              ),
            ),
          ),

          // Central Term
          Column(
            children: [
              const Icon(Icons.psychology_alt_rounded, size: 54, color: AppColors.safetyYellow),
              const SizedBox(height: 20),
              Text(
                card.getTerm(language),
                textAlign: TextAlign.center,
                textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: isUrdu ? 1.8 : 1.3,
                  fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                ),
              ),
            ],
          ),

          // Flip instruction prompt
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.touch_app_rounded, size: 16, color: Colors.grey),
              const SizedBox(width: 6),
              BilingualText(
                textEn: 'Tap card to reveal definition',
                textUr: 'تعریف دیکھنے کے لیے کارڈ پر ٹیپ کریں',
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Back of the Flashcard ---
  Widget _buildCardBack(
    FlashcardModel card,
    AppLanguage language,
    bool isUrdu,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.safetyGreen,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.safetyGreen.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment:
            isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.safetyGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isUrdu ? 'تعریف اور وضاحت' : 'DEFINITION & EXPLANATION',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.safetyGreen,
                  ),
                ),
              ),
              const Icon(Icons.check_circle_outline, color: AppColors.safetyGreen, size: 18),
            ],
          ),

          // Definition Body
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  card.getDefinition(language),
                  textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 15,
                    height: isUrdu ? 1.9 : 1.5,
                    fontWeight: FontWeight.w600,
                    fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                  ),
                ),
                if (card.getExample(language) != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.safetyYellow.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.safetyYellow.withOpacity(0.5)),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUrdu ? 'عملی مثال:' : 'Workplace Example:',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.getExample(language)!,
                          textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 12,
                            height: isUrdu ? 1.8 : 1.4,
                            fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Flip back prompt
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flip_to_front_rounded, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                BilingualText(
                  textEn: 'Tap to flip back',
                  textUr: 'واپس پلٹنے کے لیے ٹیپ کریں',
                  style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Completion View ---
  Widget _buildCompletionView(bool isUrdu, bool isDark) {
    final masteredCount = _cards.where((c) => c.isMastered).length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.safetyGreen.withOpacity(0.15),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 64,
                color: AppColors.safetyGreen,
              ),
            ),
            const SizedBox(height: 20),
            BilingualText(
              textEn: 'Flashcard Deck Completed!',
              textUr: 'فلیش کارڈز کا سیٹ مکمل ہو گیا!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isUrdu
                  ? 'آپ نے ${_cards.length} میں سے $masteredCount کارڈز پر مہارت حاصل کی'
                  : 'You mastered $masteredCount out of ${_cards.length} cards.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 28),
            SafetyButton(
              text: isUrdu ? 'دوبارہ مشق کریں' : 'Review Again',
              icon: Icons.refresh_rounded,
              backgroundColor: AppColors.safetyYellow,
              textColor: Colors.black,
              onPressed: () {
                setState(() {
                  _currentIndex = 0;
                  _showBack = false;
                });
                _flipController.reset();
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
              ),
              child: BilingualText(
                textEn: 'Back to Courses',
                textUr: 'کورسز پر واپس جائیں',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
