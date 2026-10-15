import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_locale.dart';
import '../../../core/localization/language_provider.dart';
import '../../../shared/widgets/bilingual_text.dart';
import '../../../shared/widgets/language_switch_button.dart';
import '../data/hazard_repository.dart';
import '../domain/hazard_model.dart';
import 'hazard_bottom_sheet.dart';
import 'hazard_hunt_recap_dialog.dart';

class HazardHuntScreen extends ConsumerStatefulWidget {
  final String levelId;
  final String levelTitleEn;
  final String levelTitleUr;

  const HazardHuntScreen({
    super.key,
    this.levelId = '55555555-5555-5555-5555-555555555501',
    this.levelTitleEn = 'Level 1: Construction Site Perimeter',
    this.levelTitleUr = 'لیول 1: تعمیراتی سائٹ کا منظر',
  });

  @override
  ConsumerState<HazardHuntScreen> createState() => _HazardHuntScreenState();
}

class _HazardHuntScreenState extends ConsumerState<HazardHuntScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformController = TransformationController();
  List<HazardModel> _hazards = [];
  bool _isLoading = true;

  // Game Rules
  int _lives = 3;
  int _hints = 2;
  int _secondsLeft = 90;
  Timer? _gameTimer;

  // Visual effects
  Offset? _hintPulsingLocation;
  Offset? _lastMissLocation;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _loadHazards();
  }

  Future<void> _loadHazards() async {
    final repo = ref.read(hazardRepositoryProvider);
    final fetched = await repo.getHazardsForLevel(widget.levelId);
    if (mounted) {
      setState(() {
        _hazards = fetched;
        _isLoading = false;
      });
      _startGameTimer();
    }
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 1) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        _onTimeExpired();
      }
    });
  }

  void _onTimeExpired() {
    _showRecap(isVictory: false);
  }

  void _handleTap(TapUpDetails details, Size canvasSize) {
    if (_lives <= 0 || _secondsLeft <= 0) return;

    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy;

    // Convert tap position to percentage (0.0 to 100.0)
    final tapXPct = (tapX / canvasSize.width) * 100.0;
    final tapYPct = (tapY / canvasSize.height) * 100.0;

    HazardModel? hitHazard;

    for (final hazard in _hazards) {
      if (hazard.isDiscovered) continue;

      // Calculate Euclidean distance in percentage space
      final distance = sqrt(pow(tapXPct - hazard.x, 2) + pow(tapYPct - hazard.y, 2));

      if (distance <= hazard.radius) {
        hitHazard = hazard;
        break;
      }
    }

    if (hitHazard != null) {
      // Hit a hazard!
      setState(() {
        hitHazard!.isDiscovered = true;
        _hintPulsingLocation = null;
      });

      _gameTimer?.cancel();

      HazardBottomSheet.show(
        context,
        hazard: hitHazard,
        onContinue: () {
          // Check if all hazards have been found
          final allFound = _hazards.every((h) => h.isDiscovered);
          if (allFound) {
            _showRecap(isVictory: true);
          } else {
            _startGameTimer();
          }
        },
      );
    } else {
      // Missed! Wrong tap costs a life
      setState(() {
        _lives--;
        _lastMissLocation = details.localPosition;
      });

      if (_lives <= 0) {
        _gameTimer?.cancel();
        _showRecap(isVictory: false);
      } else {
        // Clear miss ripple after 600ms
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _lastMissLocation = null);
        });
      }
    }
  }

  void _useHint() {
    if (_hints <= 0) return;

    final unfound = _hazards.where((h) => !h.isDiscovered).toList();
    if (unfound.isEmpty) return;

    final target = unfound.first;

    setState(() {
      _hints--;
      _hintPulsingLocation = Offset(target.x, target.y);
    });

    // Cancel hint pulsing after 6 seconds
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        setState(() => _hintPulsingLocation = null);
      }
    });
  }

  void _showRecap({required bool isVictory}) {
    _gameTimer?.cancel();
    final foundCount = _hazards.where((h) => h.isDiscovered).length;
    final calculatedScore = (foundCount * 100) + (_secondsLeft * 2) + (_lives * 50);

    int stars = 0;
    if (isVictory) {
      if (_secondsLeft >= 30 && _lives == 3) {
        stars = 3;
      } else if (foundCount == _hazards.length) {
        stars = 2;
      } else {
        stars = 1;
      }
    }

    HazardHuntRecapDialog.show(
      context,
      isVictory: isVictory,
      score: calculatedScore,
      stars: stars,
      timeRemaining: _secondsLeft,
      hazards: _hazards,
      onRetry: () {
        setState(() {
          _lives = 3;
          _hints = 2;
          _secondsLeft = 90;
          for (var h in _hazards) {
            h.isDiscovered = false;
          }
        });
        _startGameTimer();
      },
      onExit: () {
        Navigator.pop(context);
      },
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _pulseController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = ref.watch(languageProvider);
    final isUrdu = language == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foundCount = _hazards.where((h) => h.isDiscovered).length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top HUD Bar (Timer, Lives, Hints, Language Switch)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Timer HUD Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _secondsLeft <= 15
                          ? AppColors.dangerRed.withOpacity(0.25)
                          : AppColors.safetyYellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _secondsLeft <= 15 ? AppColors.dangerRed : AppColors.safetyYellow,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          size: 16,
                          color: _secondsLeft <= 15 ? AppColors.dangerRed : AppColors.safetyYellow,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_secondsLeft}s',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: _secondsLeft <= 15 ? AppColors.dangerRed : AppColors.safetyYellow,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Lives Remaining (Hearts)
                  Row(
                    children: List.generate(3, (index) {
                      final hasHeart = index < _lives;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Icon(
                          hasHeart ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: hasHeart ? AppColors.dangerRed : Colors.white24,
                          size: 18,
                        ),
                      );
                    }),
                  ),

                  // Hints Button
                  InkWell(
                    onTap: _hints > 0 ? _useHint : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _hints > 0
                            ? AppColors.infoBlue.withOpacity(0.2)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _hints > 0 ? AppColors.infoBlue : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_rounded,
                            size: 16,
                            color: _hints > 0 ? AppColors.infoBlue : Colors.white38,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$_hints',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _hints > 0 ? AppColors.infoBlue : Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Language Switcher
                  const LanguageSwitchButton(isCompact: true),
                ],
              ),
            ),

            // Instruction Subheader
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: AppColors.safetyYellow,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.touch_app_rounded, size: 16, color: Colors.black),
                      const SizedBox(width: 6),
                      BilingualText(
                        textEn: 'Tap hazards to inspect. Zoom & drag to inspect.',
                        textUr: 'خطرات کو ٹیپ کریں۔ زوم کر کے معائنہ کریں۔',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '🎯 $foundCount/${_hazards.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            // Zoomable / Pannable Scene Canvas
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.safetyYellow),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

                        return Stack(
                          children: [
                            InteractiveViewer(
                              transformationController: _transformController,
                              minScale: 1.0,
                              maxScale: 3.5,
                              boundaryMargin: const EdgeInsets.all(50),
                              child: GestureDetector(
                                onTapUp: (details) => _handleTap(details, canvasSize),
                                child: Container(
                                  width: canvasSize.width,
                                  height: canvasSize.height,
                                  color: const Color(0xFF1E293B),
                                  child: CustomPaint(
                                    size: canvasSize,
                                    painter: _ConstructionSiteCanvasPainter(
                                      hazards: _hazards,
                                      hintLocationPct: _hintPulsingLocation,
                                      pulseAnimation: _pulseController.value,
                                      missLocation: _lastMissLocation,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

/// Dynamic Illustrated Construction Site Scene Painter
/// Draws scaffolding, crane, excavation trench, electrical lines, walkways, and found hazard markers
class _ConstructionSiteCanvasPainter extends CustomPainter {
  final List<HazardModel> hazards;
  final Offset? hintLocationPct;
  final double pulseAnimation;
  final Offset? missLocation;

  _ConstructionSiteCanvasPainter({
    required this.hazards,
    this.hintLocationPct,
    required this.pulseAnimation,
    this.missLocation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Sky & Ground
    final skyPaint = Paint()..color = const Color(0xFF64748B);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.55), skyPaint);

    final groundPaint = Paint()..color = const Color(0xFF78350F); // Dirt/earth
    canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45), groundPaint);

    // 2. Concrete building under construction (Left side)
    final buildingPaint = Paint()..color = const Color(0xFF475569);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.05, size.height * 0.15, size.width * 0.35, size.height * 0.5), buildingPaint);

    // Scaffolding lines
    final scaffoldPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    for (double y = 0.2; y <= 0.6; y += 0.1) {
      canvas.drawLine(
        Offset(size.width * 0.03, size.height * y),
        Offset(size.width * 0.42, size.height * y),
        scaffoldPaint,
      );
    }
    canvas.drawLine(Offset(size.width * 0.03, size.height * 0.15), Offset(size.width * 0.03, size.height * 0.65), scaffoldPaint);
    canvas.drawLine(Offset(size.width * 0.42, size.height * 0.15), Offset(size.width * 0.42, size.height * 0.65), scaffoldPaint);

    // 3. Tower Crane (Right side)
    final cranePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;
    // Crane tower
    canvas.drawLine(Offset(size.width * 0.82, size.height * 0.05), Offset(size.width * 0.82, size.height * 0.65), cranePaint);
    // Crane boom horizontal
    canvas.drawLine(Offset(size.width * 0.5, size.height * 0.1), Offset(size.width * 0.95, size.height * 0.1), cranePaint);
    // Suspended load cable
    final cablePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(size.width * 0.72, size.height * 0.1), Offset(size.width * 0.72, size.height * 0.28), cablePaint);
    // Suspended steel load
    final loadPaint = Paint()..color = const Color(0xFF334155);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.68, size.height * 0.28, size.width * 0.08, size.height * 0.03), loadPaint);

    // 4. Deep Excavation Trench (Bottom Left)
    final trenchPaint = Paint()..color = const Color(0xFF451A03);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.08, size.height * 0.68, size.width * 0.25, size.height * 0.22), trenchPaint);

    // 5. Walkway & Oil puddle (Bottom Center)
    final walkwayPaint = Paint()..color = const Color(0xFF94A3B8);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.35, size.height * 0.7, size.width * 0.55, size.height * 0.25), walkwayPaint);

    // Oil Spill puddle
    final oilPaint = Paint()..color = const Color(0xFF1E293B);
    canvas.drawOval(Rect.fromLTWH(size.width * 0.57, size.height * 0.81, size.width * 0.12, size.height * 0.06), oilPaint);

    // 6. Draw Discovered Hazard Markers
    int markerIndex = 1;
    for (final h in hazards) {
      final center = Offset((h.x / 100.0) * size.width, (h.y / 100.0) * size.height);
      final radius = (h.radius / 100.0) * size.width;

      if (h.isDiscovered) {
        // Glowing Green Discovery Ring
        final ringPaint = Paint()
          ..color = AppColors.safetyGreen.withOpacity(0.4)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius, ringPaint);

        final borderPaint = Paint()
          ..color = AppColors.safetyGreen
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(center, radius, borderPaint);

        // Marker badge with index number
        final badgePaint = Paint()..color = AppColors.safetyGreen;
        canvas.drawCircle(center, 12, badgePaint);

        final textPainter = TextPainter(
          text: TextSpan(
            text: '$markerIndex',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, center - Offset(textPainter.width / 2, textPainter.height / 2));
      }
      markerIndex++;
    }

    // 7. Draw Hint Pulsing Ring (if active)
    if (hintLocationPct != null) {
      final hintCenter = Offset((hintLocationPct!.dx / 100.0) * size.width, (hintLocationPct!.dy / 100.0) * size.height);
      final hintRadius = 35.0 + (pulseAnimation * 15.0);

      final hintPaint = Paint()
        ..color = AppColors.safetyYellow.withOpacity(0.5 - (pulseAnimation * 0.3))
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(hintCenter, hintRadius, hintPaint);
    }

    // 8. Draw Miss Red Ripple (if user tapped empty area)
    if (missLocation != null) {
      final missPaint = Paint()
        ..color = AppColors.dangerRed.withOpacity(0.7)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(missLocation!, 24, missPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstructionSiteCanvasPainter oldDelegate) => true;
}
