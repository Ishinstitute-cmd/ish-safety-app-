import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../data/leaderboard_repository.dart';
import '../domain/leaderboard_entry_model.dart';

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  String _selectedTimeframe = 'week';

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isUrdu = currentLang == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entriesAsync = ref.watch(leaderboardEntriesProvider(_selectedTimeframe));

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Column(
          crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            BilingualText(
              textEn: 'Safety Leaderboard',
              textUr: 'سیفٹی رینکنگ بورڈ',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            Text(
              isUrdu ? 'صلاحیت اور مستقل مزاجی کی بنیاد پر' : 'Ranked by Consistency & Mastery',
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
      ),
      body: entriesAsync.when(
        data: (entries) {
          final top3 = entries.take(3).toList();
          final rest = entries.skip(3).toList();
          final currentUserEntry = entries.firstWhere(
            (e) => e.isCurrentUser,
            orElse: () => entries.first,
          );

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(leaderboardEntriesProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Timeframe selector
                      _buildTimeframeFilter(isUrdu, isDark),
                      const SizedBox(height: 16),

                      // Top 3 Podium
                      if (top3.length >= 3)
                        _buildPodium(context, top3, isUrdu, isDark),
                      const SizedBox(height: 20),

                      // List title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          BilingualText(
                            textEn: 'Top Safety Champions',
                            textUr: 'ٹاپ سیفٹی چیمپئنز',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.safetyYellow.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isUrdu ? '20 بہترین طلبہ' : 'Top 20',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.safetyYellowDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Rest of rankings
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rest.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = rest[index];
                          return _buildLeaderboardTile(item, isUrdu, isDark);
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Sticky User Rank Card at Bottom
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: _buildCurrentUserStickyCard(currentUserEntry, isUrdu, isDark),
              ),
            ],
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
            child: Text('Error loading leaderboard: $err'),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeframeFilter(bool isUrdu, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.grey.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          _buildTimeframeBtn('week', 'This Week', 'اس ہفتے', isUrdu, isDark),
          _buildTimeframeBtn('month', 'This Month', 'اس مہینے', isUrdu, isDark),
          _buildTimeframeBtn('all', 'All Time', 'ہمیشہ', isUrdu, isDark),
        ],
      ),
    );
  }

  Widget _buildTimeframeBtn(
    String key,
    String labelEn,
    String labelUr,
    bool isUrdu,
    bool isDark,
  ) {
    final isSelected = _selectedTimeframe == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTimeframe = key),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.safetyYellow : AppColors.safetyYellow)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          ),
          child: Center(
            child: Text(
              isUrdu ? labelUr : labelEn,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                color: isSelected
                    ? Colors.black
                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(
    BuildContext context,
    List<LeaderboardEntryModel> top3,
    bool isUrdu,
    bool isDark,
  ) {
    final first = top3[0];
    final second = top3[1];
    final third = top3[2];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFFFFBEB), Colors.white],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: AppColors.safetyYellow.withOpacity(0.4),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Left)
          Expanded(child: _buildPodiumPillar(second, 2, const Color(0xFF94A3B8), 120, isDark)),
          const SizedBox(width: 8),
          // 1st Place (Center - Tallest)
          Expanded(child: _buildPodiumPillar(first, 1, const Color(0xFFF59E0B), 150, isDark)),
          const SizedBox(width: 8),
          // 3rd Place (Right)
          Expanded(child: _buildPodiumPillar(third, 3, const Color(0xFFB45309), 105, isDark)),
        ],
      ),
    );
  }

  Widget _buildPodiumPillar(
    LeaderboardEntryModel entry,
    int rank,
    Color metalColor,
    double pillarHeight,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown or medal indicator
        Text(
          rank == 1 ? '👑' : (rank == 2 ? '🥈' : '🥉'),
          style: TextStyle(fontSize: rank == 1 ? 26 : 22),
        ),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: rank == 1 ? 24 : 20,
          backgroundColor: metalColor,
          child: CircleAvatar(
            radius: rank == 1 ? 22 : 18,
            backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
            child: Text(
              entry.userName.isNotEmpty ? entry.userName[0].toUpperCase() : 'S',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: metalColor,
                fontSize: rank == 1 ? 16 : 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.userName.split(' ').first,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
        ),
        Text(
          '${entry.score} pts',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: metalColor,
          ),
        ),
        const SizedBox(height: 6),
        // Pillar Block
        Container(
          height: pillarHeight * 0.45,
          width: double.infinity,
          decoration: BoxDecoration(
            color: metalColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: metalColor.withOpacity(0.5), width: 1.2),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: metalColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTile(
    LeaderboardEntryModel item,
    bool isUrdu,
    bool isDark,
  ) {
    final isMe = item.isCurrentUser;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.safetyYellow.withOpacity(isDark ? 0.15 : 0.2)
            : (isDark ? AppColors.darkSurfaceCard : Colors.white),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isMe
              ? AppColors.safetyYellow
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isMe ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Rank Number
          SizedBox(
            width: 28,
            child: Text(
              '#${item.rank}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isMe ? AppColors.safetyYellowDark : (isDark ? Colors.white60 : Colors.black45),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isMe ? AppColors.safetyYellow : Colors.grey.withOpacity(0.2),
            child: Text(
              item.userName.isNotEmpty ? item.userName[0].toUpperCase() : 'U',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isMe ? Colors.black : (isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isMe ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.safetyYellow,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isUrdu ? 'آپ' : 'YOU',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text('🔥 ${item.streakDays}d streak', style: const TextStyle(fontSize: 10, color: Colors.orange)),
                    const SizedBox(width: 8),
                    Text('🎓 ${item.conceptsMastered} mastered', style: const TextStyle(fontSize: 10, color: AppColors.safetyGreen)),
                  ],
                ),
              ],
            ),
          ),

          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.score}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'pts',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentUserStickyCard(
    LeaderboardEntryModel userEntry,
    bool isUrdu,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.black87,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.safetyYellow, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.safetyYellow,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '#${userEntry.rank}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                BilingualText(
                  textEn: 'Your Standing • Rank #${userEntry.rank}',
                  textUr: 'آپ کا درجہ • رینک #${userEntry.rank}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${userEntry.score} pts • ${userEntry.conceptsMastered} Concepts Mastered',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.military_tech_rounded,
            color: AppColors.safetyYellow,
            size: 28,
          ),
        ],
      ),
    );
  }
}
