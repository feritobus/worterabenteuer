import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class KidProgressBar extends StatelessWidget {
  const KidProgressBar({
    super.key,
    required this.value,
    this.color,
    this.backgroundColor,
    this.height = 10,
    this.label,
  });

  final double value; // 0.0 a 1.0
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.ink.withValues(alpha: 0.6),
              ),
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: height,
            backgroundColor: backgroundColor ?? AppColors.paleGray,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.violet,
            ),
          ),
        ),
      ],
    );
  }
}
