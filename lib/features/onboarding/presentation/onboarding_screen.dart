import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../../shared/widgets/safety_button.dart';
import '../../auth/presentation/login_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _slides = [
    OnboardingItem(
      icon: Icons.menu_book_rounded,
      iconColor: AppColors.safetyYellow,
      badgeEn: 'LEARN FIRST',
      badgeUr: 'پہلے سیکھیں',
      titleEn: 'Learn Safety Concepts First',
      titleUr: 'پہلے بنیادی تصورات سیکھیں',
      descEn:
          'Bite-sized 2-minute visual lessons mapped to international NEBOSH, IOSH & OSHA curricula. Read the lesson before testing your knowledge.',
      descUr:
          'نیبوش، آئی او ایس ایچ اور اوشا کے نصاب کے مطابق 2 منٹ کے تصویری اسباق۔ پریکٹس یا امتحان سے پہلے کانسیپٹ کو اچھی طرح سمجھیں۔',
      highlightBadgeEn: 'Learn  →  Practice  →  Test',
      highlightBadgeUr: 'سیکھیں  ←  مشق  ←  امتحان',
    ),
    OnboardingItem(
      icon: Icons.search_rounded,
      iconColor: AppColors.safetyGreen,
      badgeEn: 'HAZARD HUNT',
      badgeUr: 'ہیزرڈ ہنٹ گیم',
      titleEn: 'Spot Hazards in Real Scenes',
      titleUr: 'سائٹ کے مناظر میں خطرات تلاش کریں',
      descEn:
          'Interactive construction site simulation. Find missing PPE, unsecured ladders, and scaffold defects against the clock while mastering the Hierarchy of Controls.',
      descUr:
          'تعمیراتی سائٹ کا متحرک منظر! نامکمل پی پی ای، غیر محفوظ سیڑھی اور کرین کے خطرات وقت کے اندر تلاش کریں اور کنٹرولز کا درجہ بندی نظام سیکھیں۔',
      highlightBadgeEn: 'Hierarchy of Controls Integrated',
      highlightBadgeUr: 'کنٹرول کے درجہ بندی نظام کے ساتھ',
    ),
    OnboardingItem(
      icon: Icons.record_voice_over_rounded,
      iconColor: AppColors.infoBlue,
      badgeEn: 'INTERVIEW READINESS',
      badgeUr: 'جاب انٹرویو گائیڈ',
      titleEn: 'Ace Your HSE Job Interview',
      titleUr: 'جاب انٹرویو کی مکمل تیاری کریں',
      descEn:
          'Scenario-based questions for HSE Officers and Safety Supervisors with expert model answers. Build confident professional knowledge for Gulf & local jobs.',
      descUr:
          'سیفٹی آفیسرز اور سپروائزرز کے لیے منظرناموں پر مبنی سوالات اور ماڈل جوابات۔ خلیجی ممالک اور لوکل جاب انٹرویو کے لیے خود کو تیار کریں۔',
      highlightBadgeEn: 'HSE Officer & Supervisor Q&A',
      highlightBadgeUr: 'ماڈل جوابات اور تکنیکی نکات',
    ),
  ];

  void _onFinishOnboarding() async {
    final box = Hive.box(HiveBoxes.settings);
    await box.put('has_completed_onboarding', true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isUrdu = currentLang == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Language Switcher in top right
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: LanguageSwitchButton(isCompact: true),
          ),
          if (!isLastPage)
            TextButton(
              onPressed: () {
                _pageController.animateToPage(
                  _slides.length - 1,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                );
              },
              child: BilingualText(
                textEn: 'Skip',
                textUr: 'چھوڑیں',
                style: TextStyle(
                  color: isDark ? Colors.white60 : Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Page Slider
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Central Visual Icon Circle
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: slide.iconColor.withOpacity(0.12),
                            border: Border.all(
                              color: slide.iconColor.withOpacity(0.35),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: slide.iconColor.withOpacity(0.2),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              slide.icon,
                              size: 70,
                              color: slide.iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Highlight Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: slide.iconColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                            border: Border.all(color: slide.iconColor, width: 1.2),
                          ),
                          child: BilingualText(
                            textEn: slide.badgeEn,
                            textUr: slide.badgeUr,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: slide.iconColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        BilingualText(
                          textEn: slide.titleEn,
                          textUr: slide.titleUr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Description
                        BilingualText(
                          textEn: slide.descEn,
                          textUr: slide.descUr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Feature Tag Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield_outlined, size: 16, color: slide.iconColor),
                              const SizedBox(width: 8),
                              BilingualText(
                                textEn: slide.highlightBadgeEn,
                                textUr: slide.highlightBadgeUr,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Language Selector Card (on slide 1 or throughout)
            if (_currentPage == 0) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      BilingualText(
                        textEn: 'Preferred App Language / ایپ کی زبان',
                        textUr: 'ایپ کی زبان منتخب کریں / Preferred Language',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _LanguageOptionCard(
                              label: 'English',
                              subLabel: 'Left to Right',
                              isSelected: currentLang == AppLanguage.english,
                              onTap: () {
                                ref.read(languageProvider.notifier).setLanguage(AppLanguage.english);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _LanguageOptionCard(
                              label: 'اردو',
                              subLabel: 'نستعلیق رسم الخط',
                              isUrduFont: true,
                              isSelected: currentLang == AppLanguage.urdu,
                              onTap: () {
                                ref.read(languageProvider.notifier).setLanguage(AppLanguage.urdu);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Bottom Navigation Bar with Dots & Next/Get Started
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Page Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final bool isSelected = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: isSelected ? 24.0 : 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.safetyYellow
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  SafetyButton(
                    text: isLastPage
                        ? (isUrdu ? 'شروع کریں' : 'Get Started')
                        : (isUrdu ? 'اگلا' : 'Next'),
                    icon: isLastPage
                        ? Icons.check_circle_outline
                        : (isUrdu ? Icons.arrow_back : Icons.arrow_forward),
                    backgroundColor: AppColors.safetyYellow,
                    textColor: Colors.black,
                    onPressed: () {
                      if (isLastPage) {
                        _onFinishOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  final String label;
  final String subLabel;
  final bool isSelected;
  final bool isUrduFont;
  final VoidCallback onTap;

  const _LanguageOptionCard({
    required this.label,
    required this.subLabel,
    required this.isSelected,
    this.isUrduFont = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.safetyYellow.withOpacity(0.18)
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.safetyYellow
                : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.safetyYellow : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: isUrduFont ? 'NotoNastaliqUrdu' : null,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isSelected
                          ? (isDark ? AppColors.safetyYellow : Colors.black)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  Text(
                    subLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingItem {
  final IconData icon;
  final Color iconColor;
  final String badgeEn;
  final String badgeUr;
  final String titleEn;
  final String titleUr;
  final String descEn;
  final String descUr;
  final String highlightBadgeEn;
  final String highlightBadgeUr;

  OnboardingItem({
    required this.icon,
    required this.iconColor,
    required this.badgeEn,
    required this.badgeUr,
    required this.titleEn,
    required this.titleUr,
    required this.descEn,
    required this.descUr,
    required this.highlightBadgeEn,
    required this.highlightBadgeUr,
  });
}
