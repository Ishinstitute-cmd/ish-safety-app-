import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../../../shared/widgets/safety_button.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCourse = 'NEBOSH IGC';
  bool _isSubmitting = false;

  final List<String> _courses = [
    'NEBOSH IGC',
    'IOSH Managing Safely',
    'OSHA 30-Hour General Industry',
    'First Aid at Work & CPR',
    'Fire Safety & Firefighting',
    'Scaffolding & Working at Height',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showToast('Could not open $urlString');
      }
    } catch (_) {
      _showToast('Could not open link');
    }
  }

  Future<void> _openWhatsApp() async {
    const phone = '+923001234567';
    const text = 'Hello ISH Institute! I would like to inquire about HSE safety courses.';
    final url = 'https://wa.me/$phone?text=${Uri.encodeComponent(text)}';
    await _launchUrl(url);
  }

  Future<void> _makeCall() async {
    await _launchUrl('tel:+923001234567');
  }

  Future<void> _sendEmail() async {
    await _launchUrl('mailto:info@ishinstitutes.org?subject=HSE Course Inquiry');
  }

  Future<void> _openWebsite() async {
    await _launchUrl('https://ishinstitutes.org');
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.safetyYellow),
    );
  }

  void _submitInquiry() {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: BilingualText(
            textEn: 'Please enter your Name and Phone Number.',
            textUr: 'براہ کرم اپنا نام اور فون نمبر درج کریں۔',
          ),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _nameController.clear();
        _phoneController.clear();
        _messageController.clear();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.safetyGreen, size: 28),
                SizedBox(width: 8),
                BilingualText(
                  textEn: 'Inquiry Submitted',
                  textUr: 'درخواست موصول ہو گئی',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const BilingualText(
              textEn: 'Thank you! Our HSE course counselor will contact you via WhatsApp/Phone within 24 hours.',
              textUr: 'شکریہ! ہمارے ایچ ایس ای کونسلر 24 گھنٹوں کے اندر آپ سے واٹس ایپ یا فون پر رابطہ کریں گے۔',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentLang = ref.watch(languageProvider);
    final isUrdu = currentLang == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        title: Column(
          crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            BilingualText(
              textEn: 'About & Contact',
              textUr: 'ہمارے بارے میں اور رابطہ',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            Text(
              'ishinstitutes.org',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: LanguageSwitchButton(isCompact: true),
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
            ),
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. ISH Institute Brand Card
            _buildBrandHeaderCard(isUrdu, isDark),
            const SizedBox(height: 16),

            // 2. Quick Connect Buttons (WhatsApp, Call, Web)
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.chat_rounded,
                    labelEn: 'WhatsApp',
                    labelUr: 'واٹس ایپ',
                    color: const Color(0xFF25D366),
                    onTap: _openWhatsApp,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.phone_in_talk_rounded,
                    labelEn: 'Call Us',
                    labelUr: 'کال کریں',
                    color: AppColors.infoBlue,
                    onTap: _makeCall,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.language_rounded,
                    labelEn: 'Website',
                    labelUr: 'ویب سائٹ',
                    color: AppColors.safetyYellowDark,
                    onTap: _openWebsite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Accredited Course Programs
            _buildCoursesSection(isUrdu, isDark),
            const SizedBox(height: 20),

            // 4. Direct Course Inquiry Form
            _buildInquiryForm(isUrdu, isDark),
            const SizedBox(height: 20),

            // 5. Campus Location & Contact Info
            _buildLocationCard(isUrdu, isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeaderCard(bool isUrdu, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF334155)]
              : [const Color(0xFFFEF3C7), Colors.white],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.safetyYellow, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.safetyYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.health_and_safety_rounded, color: Colors.black, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    BilingualText(
                      textEn: 'ISH Institute of Safety & Health',
                      textUr: 'آئی ایس ایچ انسٹیٹیوٹ آف سیفٹی اینڈ ہیلتھ',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Premier Occupational Health & Safety Training Institute',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          BilingualText(
            textEn:
                'Empowering safety engineers, HSE officers, and supervisors with world-class international certifications (NEBOSH, IOSH, OSHA) and hands-on workplace training.',
            textUr:
                'سیفٹی انجینئرز، ایچ ایس ای افسران اور سپروائزرز کو بین الاقوامی سرٹیفیکیشنز (نیبوش، آئیوش، اوشا) اور عملی تربیت سے آراستہ کرنے والا سرکردہ ادارہ۔',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String labelEn,
    required String labelUr,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: color.withOpacity(0.3), width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            BilingualText(
              textEn: labelEn,
              textUr: labelUr,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesSection(bool isUrdu, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_rounded, color: AppColors.safetyYellow, size: 20),
              const SizedBox(width: 8),
              BilingualText(
                textEn: 'Accredited Certification Programs',
                textUr: 'منظور شدہ کورس پروگرامز',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildCourseItem('NEBOSH International General Certificate (IGC)', 'UK Qualification', isDark),
          _buildCourseItem('IOSH Managing Safely (v5.0)', 'UK Safety Standard', isDark),
          _buildCourseItem('OSHA 30-Hour General Industry & Construction', 'US Department of Labor', isDark),
          _buildCourseItem('Medic First Aid & CPR / AED Certification', 'Emergency Response', isDark),
          _buildCourseItem('Fire Safety & Industrial Fire Warden Training', 'Civil Defence Compliant', isDark),
        ],
      ),
    );
  }

  Widget _buildCourseItem(String title, String tag, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: AppColors.safetyGreen, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.infoBlue.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: const TextStyle(fontSize: 9, color: AppColors.infoBlue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInquiryForm(bool isUrdu, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.send_rounded, color: AppColors.safetyYellow, size: 20),
              const SizedBox(width: 8),
              BilingualText(
                textEn: 'Quick Course Inquiry',
                textUr: 'کورس کی معلومات حاصل کریں',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Name field
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: isUrdu ? 'آپ کا مکمل نام' : 'Your Full Name',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
            ),
          ),
          const SizedBox(height: 12),

          // Phone field
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: isUrdu ? 'واٹس ایپ یا موبائل نمبر' : 'WhatsApp / Mobile Number',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
            ),
          ),
          const SizedBox(height: 12),

          // Course dropdown
          DropdownButtonFormField<String>(
            value: _selectedCourse,
            decoration: InputDecoration(
              labelText: isUrdu ? 'پسندیدہ کورس' : 'Course of Interest',
              prefixIcon: const Icon(Icons.school_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
            ),
            items: _courses.map((course) {
              return DropdownMenuItem(value: course, child: Text(course, style: const TextStyle(fontSize: 13)));
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedCourse = val);
            },
          ),
          const SizedBox(height: 12),

          // Message
          TextField(
            controller: _messageController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: isUrdu ? 'کوئی اضافی سوال یا پیغام (اختیاری)' : 'Questions or Message (Optional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusMedium)),
            ),
          ),
          const SizedBox(height: 16),

          // Submit
          SafetyButton(
            textEn: _isSubmitting ? 'Submitting...' : 'Send Inquiry to Counselor',
            textUr: _isSubmitting ? 'بھیجا جا رہا ہے...' : 'کونسلر کو پیغام بھیجیں',
            backgroundColor: AppColors.safetyYellow,
            textColor: Colors.black,
            onPressed: _isSubmitting ? () {} : _submitInquiry,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(bool isUrdu, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place_rounded, color: AppColors.dangerRed, size: 20),
              const SizedBox(width: 8),
              BilingualText(
                textEn: 'Institute Campus & Contact',
                textUr: 'کیمپس اور رابطہ کی تفصیلات',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildContactRow(Icons.email_outlined, 'info@ishinstitutes.org', _sendEmail),
          const SizedBox(height: 8),
          _buildContactRow(Icons.phone_outlined, '+92 300 1234567 / +92 21 34567890', _makeCall),
          const SizedBox(height: 8),
          _buildContactRow(Icons.location_city_rounded, 'Main Shahrah-e-Faisal, Karachi, Pakistan', null),
          const SizedBox(height: 8),
          _buildContactRow(Icons.language_rounded, 'https://ishinstitutes.org', _openWebsite),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onTap != null ? AppColors.infoBlue : null,
                decoration: onTap != null ? TextDecoration.underline : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
