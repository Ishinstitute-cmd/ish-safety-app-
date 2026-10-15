import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/localization/app_locale.dart';
import 'core/localization/language_provider.dart';
import 'core/network/supabase_service.dart';
import 'core/storage/local_cache_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/onboarding/presentation/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load environment variables (.env)
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    debugPrint("[DotEnv] No .env file found or failed to load. Using system defaults.");
  }

  // 2. Initialize Hive local cache & boxes
  await LocalCacheService.init();

  // 3. Initialize Supabase
  await SupabaseService.init();

  runApp(
    const ProviderScope(
      child: IshInstituteApp(),
    ),
  );
}

class IshInstituteApp extends ConsumerWidget {
  const IshInstituteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'ISH Institute',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: language.locale,
      supportedLocales: AppLanguage.values.map((l) => l.locale),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: language.direction,
          child: child ?? const SizedBox(),
        );
      },
      home: const SplashScreen(),
    );
  }
}

