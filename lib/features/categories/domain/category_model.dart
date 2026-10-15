import '../../../core/localization/app_locale.dart';

class CategoryModel {
  final String id;
  final String slug;
  final String titleEn;
  final String titleUr;
  final String descriptionEn;
  final String descriptionUr;
  final String icon;
  final String colorHex;
  final int orderIndex;
  final double masteryPercentage;

  CategoryModel({
    required this.id,
    required this.slug,
    required this.titleEn,
    required this.titleUr,
    required this.descriptionEn,
    required this.descriptionUr,
    required this.icon,
    required this.colorHex,
    required this.orderIndex,
    this.masteryPercentage = 0.0,
  });

  String getTitle(AppLanguage lang) => lang == AppLanguage.urdu ? titleUr : titleEn;
  String getDescription(AppLanguage lang) => lang == AppLanguage.urdu ? descriptionUr : descriptionEn;

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      slug: json['slug'] as String,
      titleEn: json['title_en'] as String? ?? '',
      titleUr: json['title_ur'] as String? ?? '',
      descriptionEn: json['description_en'] as String? ?? '',
      descriptionUr: json['description_ur'] as String? ?? '',
      icon: json['icon'] as String? ?? 'shield',
      colorHex: json['color_hex'] as String? ?? '#F59E0B',
      orderIndex: json['order_index'] as int? ?? 0,
      masteryPercentage: (json['mastery_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title_en': titleEn,
      'title_ur': titleUr,
      'description_en': descriptionEn,
      'description_ur': descriptionUr,
      'icon': icon,
      'color_hex': colorHex,
      'order_index': orderIndex,
      'mastery_percentage': masteryPercentage,
    };
  }
}
