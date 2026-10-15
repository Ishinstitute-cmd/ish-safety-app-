import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class MasteryProgressBar extends StatelessWidget {
  final double percentage; // 0.0 to 1.0
  final double height;
  final bool showLabel;
  final String? label;

  const MasteryProgressBar({
    super.key,
    required this.percentage,
    this.height = 8.0,
    this.showLabel = true,
    this.label,
  });

  Color _getColor(double pct) {
    if (pct >= 0.75) return AppColors.safetyGreen;
    if (pct >= 0.40) return AppColors.infoBlue;
    return AppColors.safetyYellow;
  }

  @override
  Widget build(BuildContext context) {
    final clampedPct = percentage.clamp(0.0, 1.0);
    final pctInt = (clampedPct * 100).toInt();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progressColor = _getColor(clampedPct);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label ?? 'Mastery',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Text(
                '$pctInt%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          child: Container(
            height: height,
            width: double.infinity,
            color: isDark ? Colors.white12 : Colors.black.withOpacity(0.08),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedPct == 0 ? 0.02 : clampedPct,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: progressColor.withOpacity(0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
