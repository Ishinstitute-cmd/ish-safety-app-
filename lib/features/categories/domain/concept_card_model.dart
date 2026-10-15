import '../../../core/localization/app_locale.dart';

class ConceptCardModel {
  final String id;
  final String categoryId;
  final String titleEn;
  final String titleUr;
  final String bodyEn;
  final String bodyUr;
  final List<String> keyPointsEn;
  final List<String> keyPointsUr;
  final String? imageUrl;
  final int readTimeMinutes;
  final int orderIndex;

  ConceptCardModel({
    required this.id,
    required this.categoryId,
    required this.titleEn,
    required this.titleUr,
    required this.bodyEn,
    required this.bodyUr,
    required this.keyPointsEn,
    required this.keyPointsUr,
    this.imageUrl,
    this.readTimeMinutes = 2,
    this.orderIndex = 0,
  });

  String getTitle(AppLanguage lang) => lang == AppLanguage.urdu ? titleUr : titleEn;
  String getBody(AppLanguage lang) => lang == AppLanguage.urdu ? bodyUr : bodyEn;
  List<String> getKeyPoints(AppLanguage lang) => lang == AppLanguage.urdu ? keyPointsUr : keyPointsEn;

  factory ConceptCardModel.fromJson(Map<String, dynamic> json) {
    return ConceptCardModel(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      titleEn: json['title_en'] as String? ?? '',
      titleUr: json['title_ur'] as String? ?? '',
      bodyEn: json['body_en'] as String? ?? '',
      bodyUr: json['body_ur'] as String? ?? '',
      keyPointsEn: (json['key_points_en'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      keyPointsUr: (json['key_points_ur'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: json['image_url'] as String?,
      readTimeMinutes: json['read_time_minutes'] as int? ?? 2,
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title_en': titleEn,
      'title_ur': titleUr,
      'body_en': bodyEn,
      'body_ur': bodyUr,
      'key_points_en': keyPointsEn,
      'key_points_ur': keyPointsUr,
      'image_url': imageUrl,
      'read_time_minutes': readTimeMinutes,
      'order_index': orderIndex,
    };
  }
}
