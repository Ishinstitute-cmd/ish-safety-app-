class LeaderboardEntryModel {
  final String userId;
  final String userName;
  final int rank;
  final int score;
  final int conceptsMastered;
  final int streakDays;
  final String? avatarUrl;
  final bool isCurrentUser;

  const LeaderboardEntryModel({
    required this.userId,
    required this.userName,
    required this.rank,
    required this.score,
    required this.conceptsMastered,
    required this.streakDays,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final uid = json['user_id'] as String? ?? '';
    return LeaderboardEntryModel(
      userId: uid,
      userName: json['full_name'] as String? ?? json['username'] as String? ?? 'Safety Learner',
      rank: json['rank'] as int? ?? 1,
      score: json['score'] as int? ?? (json['total_score'] as int? ?? 0),
      conceptsMastered: json['concepts_mastered'] as int? ?? 0,
      streakDays: json['streak_days'] as int? ?? 1,
      avatarUrl: json['avatar_url'] as String?,
      isCurrentUser: currentUserId != null && uid == currentUserId,
    );
  }
}
