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
import '../../auth/presentation/login_screen.dart';
import '../../contact/presentation/contact_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  void _confirmSignOut() {
    final currentLang = ref.read(languageProvider);
    final isUrdu = currentLang == AppLanguage.urdu;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: BilingualText(
          textEn: 'Sign Out?',
          textUr: 'اکاؤنٹ سے لاگ آؤٹ کریں؟',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: BilingualText(
          textEn: 'Are you sure you want to sign out of your ISH Institute session?',
          textUr: 'کیا آپ واقعی اپنے سیشن سے لاگ آؤٹ کرنا چاہتے ہیں؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(isUrdu ? 'منسوخ کریں' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(authRepositoryProvider).signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(isUrdu ? 'لاگ آؤٹ' : 'Sign Out'),
          ),
        ],
      ),
    );
  }

  void _openContactSupport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ContactScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isUrdu = currentLang == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authRepo = ref.watch(authRepositoryProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Column(
          crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            BilingualText(
              textEn: 'Safety Passport & Profile',
              textUr: 'سیفٹی پاسپورٹ اور پروفائل',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            Text(
              'ISH Institute of Safety & Health',
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Digital Safety Passport Card
            _buildSafetyPassportCard(authRepo, isUrdu, isDark),
            const SizedBox(height: 18),

            // 2. Training Milestones & Stats
            _buildMilestonesGrid(isUrdu, isDark),
            const SizedBox(height: 18),

            // 3. Earned Safety Badges
            _buildBadgesSection(isUrdu, isDark),
            const SizedBox(height: 18),

            // 4. Preferences & Settings
            _buildSettingsSection(isUrdu, isDark),
            const SizedBox(height: 18),

            // 5. Sign Out Button
            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: AppColors.dangerRed),
              label: BilingualText(
                textEn: 'Sign Out of Account',
                textUr: 'اکاؤنٹ سے لاگ آؤٹ کریں',
                style: const TextStyle(
                  color: AppColors.dangerRed,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.dangerRed, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
              ),
              onPressed: _confirmSignOut,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyPassportCard(
    AuthRepository authRepo,
    bool isUrdu,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFF0F172A), const Color(0xFF1E293B)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: AppColors.safetyYellow, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Passport header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.safetyYellow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, color: Colors.black, size: 20),
                  ),
                  const SizedBox(width: 8),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIGITAL SAFETY PASSPORT',
                        style: TextStyle(
                          color: AppColors.safetyYellow,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        'ISH Institute Certified Candidate',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.qr_code_2_rounded, color: Colors.white70, size: 28),
            ],
          ),
          const SizedBox(height: 16),

          // User info row
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.safetyYellow,
                child: Text(
                  authRepo.displayName.isNotEmpty ? authRepo.displayName[0].toUpperCase() : 'S',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authRepo.displayName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      authRepo.currentUser?.email ?? 'Offline Guest Learner',
                      style: const TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.safetyGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.safetyGreen.withOpacity(0.5)),
                      ),
                      child: const Text(
                        'ID: ISH-PK-2026-042',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.safetyGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Overall Mastery Bar
          MasteryProgressBar(
            percentage: 0.65,
            height: 8,
            showLabel: true,
            label: isUrdu ? 'مجموعی سیفٹی مہارت (Mastery)' : 'Overall HSE Mastery',
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesGrid(bool isUrdu, bool isDark) {
    return Row(
      children: [
        _buildStatBox('🔥 5 Days', 'Active Streak', 'مستقل مزاجی', Colors.orange, isDark),
        const SizedBox(width: 8),
        _buildStatBox('18/24', 'Concepts Mastered', 'مکمل مہارت', AppColors.safetyGreen, isDark),
        const SizedBox(width: 8),
        _buildStatBox('⭐ 3 Stars', 'Hazard Hunt Site', 'ہیزرڈ ہنٹ ریکارڑ', AppColors.safetyYellowDark, isDark),
      ],
    );
  }

  Widget _buildStatBox(String val, String titleEn, String titleUr, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceCard : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            BilingualText(
              textEn: titleEn,
              textUr: titleUr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(bool isUrdu, bool isDark) {
    return Container(
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
              const Icon(Icons.military_tech_rounded, color: AppColors.safetyYellow, size: 22),
              const SizedBox(width: 8),
              BilingualText(
                textEn: 'Earned Competency Badges',
                textUr: 'حاصل کردہ اسناد اور بیجز',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBadgeChip('Risk Assessor (Level 1)', Icons.shield_rounded, AppColors.safetyGreen),
              _buildBadgeChip('Fire Safety Warden', Icons.local_fire_department_rounded, Colors.orange),
              _buildBadgeChip('Hierarchy of Controls Pro', Icons.account_tree_rounded, AppColors.infoBlue),
              _buildBadgeChip('PPE Specialist', Icons.construction_rounded, Colors.purple),
              _buildBadgeChip('Scaffold Inspector (Novice)', Icons.hardware_rounded, Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(bool isUrdu, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.language_rounded, color: AppColors.infoBlue),
            title: const BilingualText(
              textEn: 'App Language',
              textUr: 'ایپ کی زبان',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Text(
              isUrdu ? 'اردو (Nastaliq RTL)' : 'English (LTR)',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const LanguageSwitchButton(isCompact: true),
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.safetyYellowDark,
            ),
            title: const BilingualText(
              textEn: 'Appearance (Theme)',
              textUr: 'ظاہری شکل (تھیم)',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: Text(
              isDark ? 'Dark Mode' : 'Light Mode',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: Switch(
              value: isDark,
              activeColor: AppColors.safetyYellow,
              onChanged: (val) => ref.read(themeModeProvider.notifier).toggleTheme(),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.support_agent_rounded, color: AppColors.safetyGreen),
            title: const BilingualText(
              textEn: 'About ISH & Contact Support',
              textUr: 'ادارے کے بارے میں اور سپورٹ',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            subtitle: const Text(
              'WhatsApp, Courses, Campus Location',
              style: TextStyle(fontSize: 12),
            ),
            trailing: Icon(
              isUrdu ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
            ),
            onTap: _openContactSupport,
          ),
        ],
      ),
    );
  }
}
