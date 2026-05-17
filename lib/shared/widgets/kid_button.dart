import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class KidButton extends StatelessWidget {
  const KidButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.textColor,
    this.width = double.infinity,
    this.height = 64,
    this.fontSize = 18,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? color;
  final Color? textColor;
  final double width;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final bgColor = color ?? AppColors.violet;
    final fgColor = textColor ?? AppColors.cloud;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          disabledBackgroundColor: bgColor.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 4,
          shadowColor: bgColor.withValues(alpha: 0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 10)],
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
