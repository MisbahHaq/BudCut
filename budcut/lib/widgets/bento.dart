import 'package:flutter/material.dart';

import '../theme.dart';

/// Brutalist card: white fill, 2px black border, hard 3px offset shadow.
class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;
  final VoidCallback? onTap;
  final double shadow;
  final BorderSide? side;

  const BentoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = AppTheme.radius,
    this.color = AppTheme.white,
    this.onTap,
    this.shadow = 3,
    this.side,
  });

  @override
  Widget build(BuildContext context) {
    final borderSide = side;
    return Container(
      margin: EdgeInsets.only(bottom: shadow, right: shadow),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [AppTheme.hardShadow(offset: shadow)],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: borderSide != null
                  ? Border.fromBorderSide(borderSide)
                  : AppTheme.border2(),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Small uppercase mono label used across tiles.
class TileLabel extends StatelessWidget {
  final String text;
  final Color color;

  const TileLabel(this.text, {super.key, this.color = AppTheme.ink});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        fontFamily: AppTheme.mono,
        color: color,
      ),
    );
  }
}

/// Heavy mono KPI value (tabular, currency aware).
class KpiValue extends StatelessWidget {
  final String text;
  final double size;
  final Color color;

  const KpiValue(
    this.text, {
    super.key,
    this.size = 26,
    this.color = AppTheme.ink,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: AppTheme.mono,
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: -1,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// Screen section header — extrabold uppercase with accent block.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: AppTheme.yellow,
            border: AppTheme.border2(),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                  letterSpacing: -0.8,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 12),
          trailing!,
        ],
      ],
    );
  }
}

/// Tactile brutalist button with press translate + shadow drop.
class BrutButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color textColor;
  final double height;
  final double fontSize;

  const BrutButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color = AppTheme.yellow,
    this.textColor = AppTheme.ink,
    this.height = 48,
    this.fontSize = 14,
  });

  @override
  State<BrutButton> createState() => _BrutButtonState();
}

class _BrutButtonState extends State<BrutButton> {
  bool _down = false;

  void _press(bool down) {
    if (widget.onPressed == null) return;
    if (mounted) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return GestureDetector(
      onTapDown: (_) => _press(true),
      onTapCancel: () => _press(false),
      onTapUp: (_) => _press(false),
      onTap: widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        padding: EdgeInsets.only(
          right: _down ? 2 : 4,
          bottom: _down ? 2 : 4,
        ),
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: enabled ? widget.color : const Color(0xFFD9D3C8),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: AppTheme.border2(),
            boxShadow: _down
                ? null
                : [AppTheme.hardShadow(offset: 2)],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: widget.textColor),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: widget.fontSize,
                  letterSpacing: 0.3,
                  color: enabled ? widget.textColor : AppTheme.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tactile brutalist square icon button (>=48px target).
class BrutIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;
  final double size;
  final String tooltip;

  const BrutIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.color = AppTheme.white,
    this.iconColor = AppTheme.ink,
    this.size = 48,
    this.tooltip = '',
  });

  @override
  State<BrutIconButton> createState() => _BrutIconButtonState();
}

class _BrutIconButtonState extends State<BrutIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        padding: EdgeInsets.only(right: _down ? 1 : 3, bottom: _down ? 1 : 3),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: AppTheme.border2(),
            boxShadow: _down ? null : [AppTheme.hardShadow(offset: 2)],
          ),
          child: Tooltip(
            message: widget.tooltip,
            child: Icon(widget.icon, size: 22, color: widget.iconColor),
          ),
        ),
      ),
    );
  }
}

/// Brutalist pill badge for the app title.
class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.ink,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: AppTheme.border2(),
        boxShadow: [AppTheme.hardShadow(offset: 3)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: AppTheme.yellow,
              border: AppTheme.border2(const BorderSide(width: 1.5)),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'BUDCUT',
            style: TextStyle(
              color: AppTheme.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Legacy alias for [BrutButton] — kept so older screens compile unchanged.
class BrutalistButton extends BrutButton {
  const BrutalistButton({
    super.key,
    required super.label,
    super.icon,
    super.onPressed,
    super.color,
    super.textColor,
    super.height,
    super.fontSize,
  });
}