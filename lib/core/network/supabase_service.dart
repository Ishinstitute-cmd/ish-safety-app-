import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;
  static SupabaseClient? get client => _isInitialized ? Supabase.instance.client : null;

  static Future<void> init() async {
    try {
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (supabaseUrl.isNotEmpty &&
          supabaseAnonKey.isNotEmpty &&
          !supabaseUrl.contains('your-project-id') &&
          !supabaseUrl.contains('placeholder')) {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
          debug: kDebugMode,
        );
        _isInitialized = true;
        debugPrint('[SupabaseService] Successfully connected to Supabase.');
      } else {
        debugPrint('[SupabaseService] Using offline local mode (Supabase keys not yet configured).');
        _isInitialized = false;
      }
    } catch (e) {
      debugPrint('[SupabaseService] Initialization warning: $e. Operating in offline/cached mode.');
      _isInitialized = false;
    }
  }
}
