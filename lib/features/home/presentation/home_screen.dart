import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../../shared/widgets/mastery_progress_bar.dart';
import '../../auth/data/auth_repository.dart';
import '../../categories/data/categories_repository.dart';
import '../../categories/domain/category_model.dart';
import '../../categories/presentation/category_detail_screen.dart';
import '../../flashcards/presentation/flashcards_screen.dart';
import '../../hazard_hunt/presentation/hazard_hunt_screen.dart';
import '../../interview_prep/presentation/interview_prep_screen.dart';
import '../../leaderboard/presentation/leaderboard_screen.dart';
import '../../profile/presentation/profile_screen.dart';
import '../../quiz/presentation/quiz_screen.dart';
import '../../review_queue/presentation/review_queue_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;

  IconData _getCategoryIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'award':
        return Icons.emoji_events_rounded;
      case 'briefcase':
        return Icons.business_center_rounded;
      case 'shield-check':
        return Icons.verified_user_rounded;
      case 'plus-circle':
        return Icons.medical_services_rounded;
      case 'flame':
        return Icons.local_fire_department_rounded;
      case 'hard-hat':
        return Icons.construction_rounded;
      case 'alert-triangle':
        return Icons.warning_amber_rounded;
      case 'hammer':
        return Icons.hardware_rounded;
      default:
        return Icons.health_and_safety_rounded;
    }
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

  void _onCategoryTapped(CategoryModel category) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CategoryDetailScreen(category: category),
      ),
    );
  }

  void _onDailyDrillTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const QuizScreen(
          quizType: 'daily',
          categoryTitleEn: 'Daily Safety Drill',
          categoryTitleUr: 'روزانہ سیفٹی ڈرل',
        ),
      ),
    );
  }

  void _onHazardHuntTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const HazardHuntScreen(),
      ),
    );
  }

  void _onFlashcardsTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FlashcardsScreen(),
      ),
    );
  }

  void _onInterviewPrepTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InterviewPrepScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isUrdu = currentLang == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authRepo = ref.watch(authRepositoryProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: _buildAppBar(context, isUrdu, isDark),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomeDashboard(context, isUrdu, isDark, authRepo, categoriesAsync),
          _buildCoursesTab(context, isUrdu, isDark, categoriesAsync),
          const ReviewQueueScreen(),
          const LeaderboardScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) {
          setState(() => _currentNavIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: isUrdu ? 'ہوم' : 'Home',
          ),
          NavigationDestination(
            icon: const Icon(Icons.school_outlined),
            selectedIcon: const Icon(Icons.school_rounded),
            label: isUrdu ? 'کورسز' : 'Courses',
          ),
          NavigationDestination(
            icon: const Icon(Icons.repeat_rounded),
            selectedIcon: const Icon(Icons.repeat_on_rounded),
            label: isUrdu ? 'دہرائی' : 'Review',
          ),
          NavigationDestination(
            icon: const Icon(Icons.leaderboard_outlined),
            selectedIcon: const Icon(Icons.leaderboard_rounded),
            label: isUrdu ? 'رینکنگ' : 'Rankings',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: isUrdu ? 'پروفائل' : 'Profile',
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context, bool isUrdu, bool isDark) {
    if (_currentNavIndex >= 2) return null;

    if (_currentNavIndex == 1) {
      return AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Column(
          crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            const BilingualText(
              textEn: 'Safety Courses',
              textUr: 'سیفٹی کورسز اور مضامین',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            Text(
              '8 Professional Courses • 24 Core Concepts',
              style: TextStyle(
                fontSize: 10,
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
      );
    }

    return AppBar(
      elevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.safetyYellow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: Colors.black,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BilingualText(
                textEn: 'ISH Institute',
                textUr: 'آئی ایس ایچ انسٹیٹیوٹ',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              Text(
                'ishinstitutes.org',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Streak Counter Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(color: Colors.orange, width: 1.2),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🔥', style: TextStyle(fontSize: 14)),
              SizedBox(width: 4),
              Text(
                '5',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.deepOrange,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        // Language Switcher
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0),
          child: LanguageSwitchButton(isCompact: true),
        ),
        // Theme Toggle
        IconButton(
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 20,
          ),
          tooltip: 'Theme',
          onPressed: () {
            ref.read(themeModeProvider.notifier).toggleTheme();
          },
        ),
      ],
    );
  }

  Widget _buildHomeDashboard(
    BuildContext context,
    bool isUrdu,
    bool isDark,
    AuthRepository authRepo,
    AsyncValue<List<CategoryModel>> categoriesAsync,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(categoriesListProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment:
                      isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    BilingualText(
                      textEn: 'Hello, ${authRepo.displayName} 👋',
                      textUr: 'خوش آمدید، ${authRepo.displayName} 👋',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    BilingualText(
                      textEn: 'Ready for today’s safety training?',
                      textUr: 'کیا آپ آج کی سیفٹی تربیت کے لیے تیار ہیں؟',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => setState(() => _currentNavIndex = 4),
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.safetyYellow,
                    child: Text(
                      authRepo.displayName.isNotEmpty
                          ? authRepo.displayName[0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Daily Safety Drill Card (Hero Card)
            _buildDailyDrillCard(context, isUrdu, isDark),
            const SizedBox(height: 20),

            // 2. Feature Action Cards (Hazard Hunt & Interview Prep)
            Row(
              children: [
                Expanded(
                  child: _buildFeatureCard(
                    context,
                    titleEn: 'Hazard Hunt',
                    titleUr: 'ہیزرڈ ہنٹ گیم',
                    subtitleEn: 'Construction Site Simulation',
                    subtitleUr: 'تعمیراتی سائٹ سمولیشن',
                    badgeEn: '90s Timer',
                    badgeUr: '90 سیکنڈ ٹائمر',
                    icon: Icons.search_rounded,
                    color: AppColors.safetyYellow,
                    isDark: isDark,
                    onTap: _onHazardHuntTapped,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFeatureCard(
                    context,
                    titleEn: 'Interview Prep',
                    titleUr: 'جاب انٹرویو گائیڈ',
                    subtitleEn: 'HSE Officer & Supervisor',
                    subtitleUr: 'ماڈل جوابات اور تکنیک',
                    badgeEn: 'Job Ready',
                    badgeUr: 'ملازمت کے سوالات',
                    icon: Icons.record_voice_over_rounded,
                    color: AppColors.infoBlue,
                    isDark: isDark,
                    onTap: _onInterviewPrepTapped,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Flashcards Study Card
            InkWell(
              onTap: _onFlashcardsTapped,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF334155)]
                        : [const Color(0xFFFEF3C7), Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(color: AppColors.safetyYellow, width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.safetyYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.style_rounded, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          const BilingualText(
                            textEn: 'Safety Flashcards (Quick Recall)',
                            textUr: 'سیفٹی فلیش کارڈز (تیز رفتار دہرائی)',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          BilingualText(
                            textEn: 'Swipe & flip 3D study cards to memorize safety terms',
                            textUr: 'سیفٹی کی اہم اصطلاحات یاد رکھنے کے لیے کارڈز پلٹیں',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isUrdu ? Icons.chevron_left : Icons.chevron_right,
                      color: AppColors.safetyYellow,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Section Title: Categories & Mastery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BilingualText(
                  textEn: 'Safety Disciplines & Mastery',
                  textUr: 'سیفٹی کے شعبہ جات اور مہارت',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.safetyGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const BilingualText(
                    textEn: 'Learn-First',
                    textUr: 'پہلے سیکھیں',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.safetyGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 4. Categories Grid
            categoriesAsync.when(
              data: (categories) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return _buildCategoryCard(context, cat, isUrdu, isDark);
                  },
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.safetyYellow),
                  ),
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error loading categories: $err'),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesTab(
    BuildContext context,
    bool isUrdu,
    bool isDark,
    AsyncValue<List<CategoryModel>> categoriesAsync,
  ) {
    return categoriesAsync.when(
      data: (categories) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                  border: Border.all(color: AppColors.safetyYellow.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.safetyYellow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          BilingualText(
                            textEn: 'All Safety Courses (${categories.length})',
                            textUr: 'تمام سیفٹی کورسز (${categories.length})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          BilingualText(
                            textEn: 'Select any course to view Concept Lessons, Practice, or Timed Exams',
                            textUr: 'اسباق، مشق یا امتحانات کے لیے کوئی بھی کورس منتخب کریں',
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final catColor = _hexToColor(cat.colorHex);
                  final catIcon = _getCategoryIcon(cat.icon);

                  return InkWell(
                    onTap: () => _onCategoryTapped(cat),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: catColor.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(catIcon, color: catColor, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    BilingualText(
                                      textEn: cat.titleEn,
                                      textUr: cat.titleUr,
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 2),
                                    BilingualText(
                                      textEn: cat.descriptionEn,
                                      textUr: cat.descriptionUr,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isUrdu ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                                color: isDark ? Colors.white38 : Colors.black26,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          MasteryProgressBar(
                            percentage: cat.masteryPercentage,
                            height: 6.0,
                            showLabel: true,
                            label: isUrdu ? 'مہارت (Mastery)' : 'Course Mastery',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.safetyYellow),
        ),
      ),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildDailyDrillCard(BuildContext context, bool isUrdu, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.safetyYellow.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment:
              isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.safetyYellow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, size: 14, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(
                        isUrdu ? 'روزانہ ڈرل' : 'DAILY DRILL',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '5 MCQs • 20s Timer',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            BilingualText(
              textEn: 'Daily Workplace Safety Challenge',
              textUr: 'روزانہ کا سیفٹی چیلنج اور پریکٹس',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            BilingualText(
              textEn: 'Answer 5 curated questions to boost your mastery streak.',
              textUr: 'اپنی اسٹریک برقرار رکھنے کے لیے 5 منتخب کردہ سوالات کے جواب دیں۔',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _onDailyDrillTapped,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                label: BilingualText(
                  textEn: 'Start Drill',
                  textUr: 'ڈرل شروع کریں',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.safetyYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String titleEn,
    required String titleUr,
    required String subtitleEn,
    required String subtitleUr,
    required String badgeEn,
    required String badgeUr,
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceCard : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: BilingualText(
                    textEn: badgeEn,
                    textUr: badgeUr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BilingualText(
              textEn: titleEn,
              textUr: titleUr,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            BilingualText(
              textEn: subtitleEn,
              textUr: subtitleUr,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    CategoryModel category,
    bool isUrdu,
    bool isDark,
  ) {
    final catColor = _hexToColor(category.colorHex);
    final catIcon = _getCategoryIcon(category.icon);

    return InkWell(
      onTap: () => _onCategoryTapped(category),
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      child: Container(
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceCard : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: catColor, size: 24),
                ),
                Icon(
                  isUrdu ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  color: isDark ? Colors.white38 : Colors.black26,
                  size: 20,
                ),
              ],
            ),
            Column(
              crossAxisAlignment:
                  isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                BilingualText(
                  textEn: category.titleEn,
                  textUr: category.titleUr,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                BilingualText(
                  textEn: category.descriptionEn,
                  textUr: category.descriptionUr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
            // Real-Time Mastery Bar
            MasteryProgressBar(
              percentage: category.masteryPercentage,
              height: 6.0,
              showLabel: true,
              label: isUrdu ? 'مہارت' : 'Mastery',
            ),
          ],
        ),
      ),
    );
  }
}
