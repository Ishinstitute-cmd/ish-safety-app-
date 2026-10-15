import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_service.dart';
import '../../../core/storage/hive_boxes.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<AuthState?>((ref) {
  if (SupabaseService.isInitialized && SupabaseService.client != null) {
    return SupabaseService.client!.auth.onAuthStateChange;
  }
  return Stream.value(null);
});

class AuthRepository {
  static const String _keyIsGuest = 'is_guest_user';
  static const String _keyGuestName = 'guest_user_name';

  bool get isGuest {
    try {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        return Hive.box(HiveBoxes.settings).get(_keyIsGuest, defaultValue: false) as bool;
      }
    } catch (_) {}
    return false;
  }

  User? get currentUser {
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      return SupabaseService.client!.auth.currentUser;
    }
    return null;
  }

  String get displayName {
    if (isGuest) {
      if (Hive.isBoxOpen(HiveBoxes.settings)) {
        return Hive.box(HiveBoxes.settings).get(_keyGuestName, defaultValue: 'Safety Trainee') as String;
      }
      return 'Safety Trainee';
    }
    final user = currentUser;
    if (user != null) {
      return user.userMetadata?['full_name'] as String? ??
          user.email?.split('@').first ??
          'Safety Trainee';
    }
    return 'Safety Trainee';
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!SupabaseService.isInitialized || SupabaseService.client == null) {
      throw Exception('Supabase connection is not configured. You can continue as a Guest.');
    }

    final response = await SupabaseService.client!.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    // Clear guest flag
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.box(HiveBoxes.settings).put(_keyIsGuest, false);
    }

    return response;
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (!SupabaseService.isInitialized || SupabaseService.client == null) {
      throw Exception('Supabase connection is not configured. You can continue as a Guest.');
    }

    final response = await SupabaseService.client!.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );

    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.box(HiveBoxes.settings).put(_keyIsGuest, false);
    }

    return response;
  }

  Future<bool> signInWithGoogle() async {
    if (!SupabaseService.isInitialized || SupabaseService.client == null) {
      throw Exception('Supabase connection is not configured. Please use Guest mode.');
    }

    return await SupabaseService.client!.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'org.ishinstitutes.app://login-callback',
    );
  }

  Future<void> signInAsGuest({String guestName = 'Safety Trainee'}) async {
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      final box = Hive.box(HiveBoxes.settings);
      await box.put(_keyIsGuest, true);
      await box.put(_keyGuestName, guestName);
    }
  }

  Future<void> resetPassword(String email) async {
    if (!SupabaseService.isInitialized || SupabaseService.client == null) {
      throw Exception('Supabase is not configured.');
    }
    await SupabaseService.client!.auth.resetPasswordForEmail(email.trim());
  }

  Future<void> signOut() async {
    if (Hive.isBoxOpen(HiveBoxes.settings)) {
      await Hive.box(HiveBoxes.settings).put(_keyIsGuest, false);
    }
    if (SupabaseService.isInitialized && SupabaseService.client != null) {
      await SupabaseService.client!.auth.signOut();
    }
  }
}
