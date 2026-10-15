import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_boxes.dart';

class LocalCacheService {
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(HiveBoxes.settings);
    await Hive.openBox(HiveBoxes.cache);
    await Hive.openBox(HiveBoxes.mastery);
    await Hive.openBox(HiveBoxes.reviewQueue);
    await Hive.openBox(HiveBoxes.bookmarks);
  }

  // Generic Cache Methods
  static Future<void> setCacheList(String key, List<Map<String, dynamic>> items) async {
    final box = Hive.box(HiveBoxes.cache);
    await box.put(key, jsonEncode(items));
  }

  static List<Map<String, dynamic>>? getCacheList(String key) {
    try {
      final box = Hive.box(HiveBoxes.cache);
      final raw = box.get(key) as String?;
      if (raw == null) return null;
      final List<dynamic> decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return null;
    }
  }

  // Mastery Cache
  static Future<void> saveMastery(String conceptId, Map<String, dynamic> data) async {
    final box = Hive.box(HiveBoxes.mastery);
    await box.put(conceptId, jsonEncode(data));
  }

  static Map<String, dynamic>? getMastery(String conceptId) {
    try {
      final box = Hive.box(HiveBoxes.mastery);
      final raw = box.get(conceptId) as String?;
      if (raw == null) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static List<Map<String, dynamic>> getAllMastery() {
    try {
      final box = Hive.box(HiveBoxes.mastery);
      final list = <Map<String, dynamic>>[];
      for (final key in box.keys) {
        final raw = box.get(key) as String?;
        if (raw != null) {
          list.add(Map<String, dynamic>.from(jsonDecode(raw) as Map));
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  // Review Queue Spaced Repetition Cache
  static Future<void> addToReviewQueue(String questionId, Map<String, dynamic> data) async {
    final box = Hive.box(HiveBoxes.reviewQueue);
    await box.put(questionId, jsonEncode(data));
  }

  static List<Map<String, dynamic>> getReviewQueue() {
    try {
      final box = Hive.box(HiveBoxes.reviewQueue);
      final list = <Map<String, dynamic>>[];
      for (final key in box.keys) {
        final raw = box.get(key) as String?;
        if (raw != null) {
          list.add(Map<String, dynamic>.from(jsonDecode(raw) as Map));
        }
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  static Future<void> removeFromReviewQueue(String questionId) async {
    final box = Hive.box(HiveBoxes.reviewQueue);
    await box.delete(questionId);
  }
}
