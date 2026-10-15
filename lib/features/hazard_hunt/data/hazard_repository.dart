import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/storage/seed_data_provider.dart';
import '../domain/hazard_model.dart';

final hazardRepositoryProvider = Provider<HazardRepository>((ref) {
  return HazardRepository();
});

class HazardRepository {
  Future<List<HazardModel>> getHazardsForLevel(String levelId) async {
    final cacheKey = 'hazards_level_$levelId';

    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      try {
        final response = await SupabaseService.client!
            .from('hazards')
            .select()
            .eq('level_id', levelId);
        final list = (response as List).map((json) => HazardModel.fromJson(json)).toList();
        await LocalCacheService.setCacheList(cacheKey, list.map((e) => e.toJson()).toList());
        return list;
      } catch (_) {}
    }

    final cached = LocalCacheService.getCacheList(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      return cached.map((e) => HazardModel.fromJson(e)).toList();
    }

    return SeedDataProvider.getConstructionSiteHazards();
  }
}
