import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../data/interview_repository.dart';
import '../domain/interview_question_model.dart';

class InterviewPrepScreen extends ConsumerStatefulWidget {
  const InterviewPrepScreen({super.key});

  @override
  ConsumerState<InterviewPrepScreen> createState() => _InterviewPrepScreenState();
}

class _InterviewPrepScreenState extends ConsumerState<InterviewPrepScreen> {
  String _selectedRole = 'all';
  bool _showBookmarkedOnly = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<InterviewQuestionModel> _questions = [];
  bool _isLoading = true;

  final List<Map<String, String>> _roles = [
    {'id': 'all', 'name_en': 'All Roles', 'name_ur': 'تمام عہدے'},
    {'id': 'HSE Officer', 'name_en': 'HSE Officer', 'name_ur': 'ایچ ایس ای آفیسر'},
    {'id': 'Safety Supervisor', 'name_en': 'Safety Supervisor', 'name_ur': 'سیفٹی سپروائزر'},
    {'id': 'Fire Safety Officer', 'name_en': 'Fire Safety Officer', 'name_ur': 'فائر سیفٹی آفیسر'},
  ];

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);
    final repo = ref.read(interviewRepositoryProvider);
    final fetched = await repo.getQuestions(
      role: _selectedRole == 'all' ? null : _selectedRole,
      bookmarkedOnly: _showBookmarkedOnly,
    );

    if (mounted) {
      setState(() {
        _questions = fetched;
        _isLoading = false;
      });
    }
  }

  void _toggleBookmark(InterviewQuestionModel q) async {
    final repo = ref.read(interviewRepositoryProvider);
    final newState = await repo.toggleBookmark(q.id);

    setState(() {
      q.isBookmarked = newState;
      if (_showBookmarkedOnly && !newState) {
        _questions.removeWhere((item) => item.id == q.id);
      }
    });

    final isUrdu = ref.read(languageProvider) == AppLanguage.urdu;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newState
              ? (isUrdu ? 'سوال بک مارک میں شامل کر دیا گیا' : 'Question added to bookmarks')
              : (isUrdu ? 'سوال بک مارک سے ہٹا دیا گیا' : 'Question removed from bookmarks'),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: newState ? AppColors.safetyGreen : Colors.grey[700],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'hse officer':
        return AppColors.infoBlue;
      case 'safety supervisor':
        return AppColors.safetyYellow;
      case 'fire safety officer':
        return AppColors.safetyOrange;
      default:
        return AppColors.safetyGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final isUrdu = language == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _questions.where((q) {
      if (_searchQuery.isEmpty) return true;
      final term = _searchQuery.toLowerCase();
      return q.questionEn.toLowerCase().contains(term) ||
          q.questionUr.toLowerCase().contains(term) ||
          q.modelAnswerEn.toLowerCase().contains(term) ||
          q.modelAnswerUr.toLowerCase().contains(term);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: BilingualText(
          textEn: 'HSE Interview Prep',
          textUr: 'جاب انٹرویو گائیڈ',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showBookmarkedOnly ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              color: _showBookmarkedOnly ? AppColors.safetyYellow : null,
            ),
            tooltip: 'Saved Questions',
            onPressed: () {
              setState(() {
                _showBookmarkedOnly = !_showBookmarkedOnly;
              });
              _loadQuestions();
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.0),
            child: LanguageSwitchButton(isCompact: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: isUrdu ? 'سوال یا جواب میں تلاش کریں...' : 'Search questions, scenarios...',
                  hintStyle: TextStyle(
                    fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
              ),
            ),

            // Role Filter Chips
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _roles.length,
                itemBuilder: (context, index) {
                  final r = _roles[index];
                  final isSelected = _selectedRole == r['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      selected: isSelected,
                      selectedColor: AppColors.safetyYellow,
                      backgroundColor: isDark ? AppColors.darkSurfaceCard : Colors.white,
                      label: Text(
                        isUrdu ? r['name_ur']! : r['name_en']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                          fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                        ),
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedRole = r['id']!);
                          _loadQuestions();
                        }
                      },
                    ),
                  );
                },
              ),
            ),

            // Questions List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.safetyYellow),
                      ),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _showBookmarkedOnly
                                    ? Icons.bookmark_border_rounded
                                    : Icons.search_off_rounded,
                                size: 48,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              BilingualText(
                                textEn: _showBookmarkedOnly
                                    ? 'No bookmarked questions yet.'
                                    : 'No interview questions matched your query.',
                                textUr: _showBookmarkedOnly
                                    ? 'ابھی تک کوئی سوال محفوظ نہیں کیا گیا۔'
                                    : 'کوئی انٹرویو سوال دستیاب نہیں۔',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final q = filtered[index];
                            return _InterviewQuestionCard(
                              question: q,
                              roleColor: _getRoleColor(q.role),
                              onToggleBookmark: () => _toggleBookmark(q),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterviewQuestionCard extends ConsumerStatefulWidget {
  final InterviewQuestionModel question;
  final Color roleColor;
  final VoidCallback onToggleBookmark;

  const _InterviewQuestionCard({
    required this.question,
    required this.roleColor,
    required this.onToggleBookmark,
  });

  @override
  ConsumerState<_InterviewQuestionCard> createState() => _InterviewQuestionCardState();
}

class _InterviewQuestionCardState extends ConsumerState<_InterviewQuestionCard> {
  bool _isAnswerRevealed = false;

  void _copyAnswer(String answerText, bool isUrdu) {
    Clipboard.setData(ClipboardData(text: answerText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isUrdu ? 'جواب کلپ بورڈ میں کاپی ہو گیا' : 'Model answer copied to clipboard!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final isUrdu = language == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final q = widget.question;
    final takeaways = q.getKeyTakeaways(language);

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Role Badge & Bookmark button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.roleColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    q.role,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: widget.roleColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    q.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                    color: q.isBookmarked ? AppColors.safetyYellow : (isDark ? Colors.white38 : Colors.black38),
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: widget.onToggleBookmark,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question Text
            BilingualText(
              textEn: q.questionEn,
              textUr: q.questionUr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Reveal Model Answer Toggle Button
            InkWell(
              onTap: () {
                setState(() => _isAnswerRevealed = !_isAnswerRevealed);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _isAnswerRevealed
                      ? AppColors.safetyGreen.withOpacity(0.15)
                      : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _isAnswerRevealed ? AppColors.safetyGreen : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isAnswerRevealed ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 16,
                      color: _isAnswerRevealed ? AppColors.safetyGreen : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(width: 8),
                    BilingualText(
                      textEn: _isAnswerRevealed ? 'Hide Model Answer' : 'Reveal Model Answer',
                      textUr: _isAnswerRevealed ? 'ماڈل جواب چھپائیں' : 'ماڈل جواب دیکھیں',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: _isAnswerRevealed ? AppColors.safetyGreen : (isDark ? Colors.white : Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded Model Answer Content
            if (_isAnswerRevealed) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.safetyGreen.withOpacity(0.5),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment:
                      isUrdu ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.safetyGreen),
                            const SizedBox(width: 6),
                            BilingualText(
                              textEn: 'Recommended HSE Model Answer:',
                              textUr: 'تجویز کردہ بہترین ماڈل جواب:',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.safetyGreen,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 16),
                          tooltip: 'Copy Answer',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _copyAnswer(q.getModelAnswer(language), isUrdu),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    BilingualText(
                      textEn: q.modelAnswerEn,
                      textUr: q.modelAnswerUr,
                      style: const TextStyle(fontSize: 13, height: 1.6),
                    ),

                    // Key Interview Talking Points
                    if (takeaways.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Divider(color: isDark ? Colors.white12 : Colors.black12, height: 1),
                      const SizedBox(height: 10),
                      BilingualText(
                        textEn: 'Key Talking Points for Interview:',
                        textUr: 'انٹرویو کے کلیدی تکنیکی نکات:',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.safetyYellow,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: takeaways.map((point) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.safetyYellow.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.safetyYellow.withOpacity(0.4)),
                            ),
                            child: Text(
                              point,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
