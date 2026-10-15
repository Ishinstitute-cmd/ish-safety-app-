import '../../../core/localization/app_locale.dart';
import '../../../core/utils/hierarchy_of_controls.dart';

class HazardModel {
  final String id;
  final String levelId;
  final String? conceptId;
  final double x; // 0.0 to 100.0 (%)
  final double y; // 0.0 to 100.0 (%)
  final double radius; // radius percentage (%)
  final String nameEn;
  final String nameUr;
  final String reasonEn;
  final String reasonUr;
  final String controlEn;
  final String controlUr;
  final ControlLevel controlLevel;
  bool isDiscovered;

  HazardModel({
    required this.id,
    required this.levelId,
    this.conceptId,
    required this.x,
    required this.y,
    this.radius = 8.0,
    required this.nameEn,
    required this.nameUr,
    required this.reasonEn,
    required this.reasonUr,
    required this.controlEn,
    required this.controlUr,
    required this.controlLevel,
    this.isDiscovered = false,
  });

  String getName(AppLanguage lang) => lang == AppLanguage.urdu ? nameUr : nameEn;
  String getReason(AppLanguage lang) => lang == AppLanguage.urdu ? reasonUr : reasonEn;
  String getControl(AppLanguage lang) => lang == AppLanguage.urdu ? controlUr : controlEn;

  factory HazardModel.fromJson(Map<String, dynamic> json) {
    return HazardModel(
      id: json['id'] as String,
      levelId: json['level_id'] as String,
      conceptId: json['concept_id'] as String?,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      radius: (json['radius'] as num?)?.toDouble() ?? 8.0,
      nameEn: json['name_en'] as String? ?? '',
      nameUr: json['name_ur'] as String? ?? '',
      reasonEn: json['reason_en'] as String? ?? '',
      reasonUr: json['reason_ur'] as String? ?? '',
      controlEn: json['control_en'] as String? ?? '',
      controlUr: json['control_ur'] as String? ?? '',
      controlLevel: ControlLevel.fromString(json['control_level'] as String? ?? 'PPE'),
      isDiscovered: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'level_id': levelId,
      'concept_id': conceptId,
      'x': x,
      'y': y,
      'radius': radius,
      'name_en': nameEn,
      'name_ur': nameUr,
      'reason_en': reasonEn,
      'reason_ur': reasonUr,
      'control_en': controlEn,
      'control_ur': controlUr,
      'control_level': controlLevel.name,
    };
  }
}

class HazardLevelModel {
  final String id;
  final int levelNumber;
  final String titleEn;
  final String titleUr;
  final String imageUrl;
  final int timeLimit;
  final int requiredStarsToUnlock;
  final bool isUnlocked;
  final int stars;

  HazardLevelModel({
    required this.id,
    required this.levelNumber,
    required this.titleEn,
    required this.titleUr,
    required this.imageUrl,
    this.timeLimit = 90,
    this.requiredStarsToUnlock = 0,
    this.isUnlocked = true,
    this.stars = 0,
  });

  String getTitle(AppLanguage lang) => lang == AppLanguage.urdu ? titleUr : titleEn;

  factory HazardLevelModel.fromJson(Map<String, dynamic> json) {
    return HazardLevelModel(
      id: json['id'] as String,
      levelNumber: json['level_number'] as int? ?? 1,
      titleEn: json['title_en'] as String? ?? '',
      titleUr: json['title_ur'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      timeLimit: json['time_limit'] as int? ?? 90,
      requiredStarsToUnlock: json['required_stars_to_unlock'] as int? ?? 0,
      isUnlocked: json['is_unlocked'] as bool? ?? true,
      stars: json['stars'] as int? ?? 0,
    );
  }
}
