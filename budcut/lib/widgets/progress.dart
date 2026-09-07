import 'package:flutter/material.dart';

import '../theme.dart';

class ColorDot extends StatelessWidget {
  final String hex;
  final double size;

  const ColorDot(this.hex, {super.key, this.size = 10});

  static Color parse(String hex) {
    final cleaned = hex.replaceAll('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    if (cleaned.length == 8) {
      return Color(int.parse(cleaned, radix: 16));
    }
    return AppTheme.ink;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: parse(hex),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.ink, width: 1.5),
      ),
    );
  }
}

/// Brutalist bordered progress bar with hard offset shadow.
class ProgressBar extends StatelessWidget {
  final double fraction;
  final Color color;
  final Color? backgroundColor;
  final double height;
  final bool showShadow;

  const ProgressBar({
    super.key,
    required this.fraction,
    required this.color,
    this.backgroundColor = const Color(0xFFEDE9E1),
    this.height = 12,
    this.showShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: showShadow ? 3 : 0, right: showShadow ? 3 : 0),
      decoration: BoxDecoration(
        boxShadow: showShadow ? [AppTheme.hardShadow()] : null,
      ),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(2),
          border: AppTheme.border2(),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}