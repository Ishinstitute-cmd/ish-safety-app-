import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../../shared/widgets/safety_button.dart';
import '../../home/presentation/home_screen.dart';
import '../data/auth_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final authRepo = ref.read(authRepositoryProvider);
    final currentLang = ref.read(languageProvider);
    final isUrdu = currentLang == AppLanguage.urdu;

    try {
      if (_isSignUp) {
        await authRepo.signUpWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _nameController.text.isNotEmpty ? _nameController.text : 'Safety Trainee',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isUrdu
                    ? 'اکاؤنٹ کامیابی سے بن گیا! خوش آمدید'
                    : 'Account created successfully! Welcome',
              ),
              backgroundColor: AppColors.safetyGreen,
            ),
          );
        }
      } else {
        await authRepo.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isUrdu ? 'کامیابی سے لاگ ان ہو گئے!' : 'Signed in successfully!',
              ),
              backgroundColor: AppColors.safetyGreen,
            ),
          );
        }
      }
      _navigateToHome();
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceAll('Exception:', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.dangerRed,
            action: SnackBarAction(
              label: isUrdu ? 'مہمان موڈ' : 'Guest Mode',
              textColor: Colors.white,
              onPressed: _handleGuestSignIn,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final authRepo = ref.read(authRepositoryProvider);
    final currentLang = ref.read(languageProvider);
    final isUrdu = currentLang == AppLanguage.urdu;

    try {
      await authRepo.signInWithGoogle();
      _navigateToHome();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isUrdu
                  ? 'گوگل لاگ ان کے لیے سپابیس کی کیز درکار ہیں یا مہمان کے طور پر لاگ ان کریں'
                  : 'Google OAuth requires Supabase keys or continue as Guest.',
            ),
            backgroundColor: AppColors.dangerRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestSignIn() async {
    final authRepo = ref.read(authRepositoryProvider);
    await authRepo.signInAsGuest();
    _navigateToHome();
  }

  void _showForgotPasswordDialog() {
    final emailResetController = TextEditingController(text: _emailController.text);
    final currentLang = ref.read(languageProvider);
    final isUrdu = currentLang == AppLanguage.urdu;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: BilingualText(
          textEn: 'Reset Password',
          textUr: 'پاس ورڈ ری سیٹ کریں',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BilingualText(
              textEn: 'Enter your registered email address to receive reset instructions.',
              textUr: 'ری سیٹ ہدایات حاصل کرنے کے لیے اپنا رجسٹرڈ ای میل درج کریں۔',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailResetController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: isUrdu ? 'ای میل ایڈریس' : 'Email Address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: BilingualText(
              textEn: 'Cancel',
              textUr: 'منسوخ کریں',
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.safetyYellow,
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (emailResetController.text.isNotEmpty) {
                try {
                  await ref
                      .read(authRepositoryProvider)
                      .resetPassword(emailResetController.text);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isUrdu
                              ? 'پاس ورڈ ری سیٹ کی ای میل بھیج دی گئی ہے!'
                              : 'Password reset link sent to your email!',
                        ),
                        backgroundColor: AppColors.safetyGreen,
                      ),
                    );
                  }
                } catch (err) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(err.toString()),
                        backgroundColor: AppColors.dangerRed,
                      ),
                    );
                  }
                }
              }
            },
            child: BilingualText(
              textEn: 'Send Link',
              textUr: 'لنک بھیجیں',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isUrdu = currentLang == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const Icon(
              Icons.health_and_safety_rounded,
              color: AppColors.safetyYellow,
              size: 26,
            ),
            const SizedBox(width: 8),
            BilingualText(
              textEn: 'ISH Institute',
              textUr: 'آئی ایس ایچ انسٹیٹیوٹ',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: LanguageSwitchButton(isCompact: true),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                // Heading Banner
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.safetyYellow.withOpacity(0.14),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 48,
                      color: AppColors.safetyYellow,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                BilingualText(
                  textEn: _isSignUp ? 'Create Safety Account' : 'Welcome to ISH Institute',
                  textUr: _isSignUp ? 'نیا اکاؤنٹ بنائیں' : 'خوش آمدید! لاگ ان کریں',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                BilingualText(
                  textEn: _isSignUp
                      ? 'Track your mastery, streaks & interview prep'
                      : 'Sign in to access your courses, quizzes and progress',
                  textUr: _isSignUp
                      ? 'اپنی مہارت، اسٹریک اور انٹرویو کے سوالات محفوظ کریں'
                      : 'اپنے کورسز، کوئز اور پیش رفت تک رسائی کے لیے سائن ان کریں',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Mode Toggle (Sign In / Sign Up)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceCard : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _AuthTabButton(
                          titleEn: 'Sign In',
                          titleUr: 'لاگ ان',
                          isActive: !_isSignUp,
                          onTap: () => setState(() => _isSignUp = false),
                        ),
                      ),
                      Expanded(
                        child: _AuthTabButton(
                          titleEn: 'Sign Up',
                          titleUr: 'نیا اکاؤنٹ',
                          isActive: _isSignUp,
                          onTap: () => setState(() => _isSignUp = true),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name Input (Sign Up Only)
                if (_isSignUp) ...[
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: isUrdu ? 'مکمل نام' : 'Full Name',
                      hintText: isUrdu ? 'مثال: محمد احمد' : 'e.g. John Doe',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      ),
                    ),
                    validator: (val) {
                      if (_isSignUp && (val == null || val.trim().isEmpty)) {
                        return isUrdu ? 'براہ کرم اپنا نام درج کریں' : 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Input
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'ای میل ایڈریس' : 'Email Address',
                    hintText: 'student@example.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return isUrdu ? 'ای میل درج کریں' : 'Please enter your email';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return isUrdu ? 'درست ای میل درج کریں' : 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Input
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: isUrdu ? 'پاس ورڈ' : 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.length < 6) {
                      return isUrdu
                          ? 'پاس ورڈ کم از کم 6 ہندسوں کا ہونا چاہیے'
                          : 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                // Forgot Password link (Sign In Only)
                if (!_isSignUp) ...[
                  Align(
                    alignment: isUrdu ? Alignment.centerLeft : Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: BilingualText(
                        textEn: 'Forgot Password?',
                        textUr: 'پاس ورڈ بھول گئے؟',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.safetyYellow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                ],

                // Submit Button
                SafetyButton(
                  text: _isSignUp
                      ? (isUrdu ? 'اکاؤنٹ بنائیں' : 'Create Account')
                      : (isUrdu ? 'لاگ ان کریں' : 'Sign In'),
                  isLoading: _isLoading,
                  icon: _isSignUp ? Icons.person_add_alt_1 : Icons.login_rounded,
                  backgroundColor: AppColors.safetyYellow,
                  textColor: Colors.black,
                  onPressed: _handleEmailAuth,
                ),
                const SizedBox(height: 20),

                // Divider: Or
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: BilingualText(
                        textEn: 'OR',
                        textUr: 'یا',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Continue with Google Button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: Colors.red),
                  label: BilingualText(
                    textEn: 'Continue with Google',
                    textUr: 'گوگل کے ساتھ لاگ ان',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                    side: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Continue as Guest (Offline Mode) Button
                ElevatedButton.icon(
                  onPressed: _handleGuestSignIn,
                  icon: const Icon(Icons.explore_rounded, size: 20, color: AppColors.safetyGreen),
                  label: BilingualText(
                    textEn: 'Continue as Guest (Offline Study)',
                    textUr: 'مہمان کے طور پر مطالعہ کریں (آف لائن)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.safetyGreen,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.safetyGreen.withOpacity(0.12),
                    elevation: 0,
                    minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                      side: const BorderSide(color: AppColors.safetyGreen, width: 1.2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  final String titleEn;
  final String titleUr;
  final bool isActive;
  final VoidCallback onTap;

  const _AuthTabButton({
    required this.titleEn,
    required this.titleUr,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.darkSurface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: BilingualText(
            textEn: titleEn,
            textUr: titleUr,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              color: isActive
                  ? AppColors.safetyYellow
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }
}
