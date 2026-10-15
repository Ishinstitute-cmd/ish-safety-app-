import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/storage/seed_data_provider.dart';
import '../domain/category_model.dart';
import '../domain/concept_card_model.dart';

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository();
});

final categoriesListProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.getCategories();
});

final conceptCardsListProvider = FutureProvider.family<List<ConceptCardModel>, String>((ref, categoryId) async {
  final repo = ref.watch(categoriesRepositoryProvider);
  return repo.getConceptCards(categoryId);
});

class CategoriesRepository {
  Future<List<CategoryModel>> getCategories() async {
    // 1. Try Supabase if connected
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        final response = await SupabaseService.client!
            .from('categories')
            .select()
            .order('order_index', ascending: true);
        final list = (response as List).map((json) => CategoryModel.fromJson(json)).toList();
        // Cache to Hive
        await LocalCacheService.setCacheList('categories', list.map((e) => e.toJson()).toList());
        return list;
      } catch (_) {}
    }

    // 2. Try Hive Cache
    final cached = LocalCacheService.getCacheList('categories');
    if (cached != null && cached.isNotEmpty) {
      return cached.map((e) => CategoryModel.fromJson(e)).toList();
    }

    // 3. Fallback to Local Seed Data
    return SeedDataProvider.getCategories();
  }

  Future<List<ConceptCardModel>> getConceptCards(String categoryId) async {
    final cacheKey = 'concept_cards_$categoryId';

    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        final response = await SupabaseService.client!
            .from('concept_cards')
            .select()
            .eq('category_id', categoryId)
            .order('order_index', ascending: true);
        final list = (response as List).map((json) => ConceptCardModel.fromJson(json)).toList();
        await LocalCacheService.setCacheList(cacheKey, list.map((e) => e.toJson()).toList());
        return list;
      } catch (_) {}
    }

    final cached = LocalCacheService.getCacheList(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      return cached.map((e) => ConceptCardModel.fromJson(e)).toList();
    }

    return SeedDataProvider.getConceptCards(categoryId);
  }
}
