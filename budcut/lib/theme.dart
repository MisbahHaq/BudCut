import 'package:flutter/material.dart';

import 'currency.dart';

/// Bold Tactile Neo-Brutalist (Modern Poster) design system.
///
/// Warm off-white canvas, crisp solid black borders, hard-edge offset
/// drop shadows, an energetic pastel accent palette, extrabold uppercase
/// headings and mono-spaced tabular currency figures.
class AppTheme {
  // Canvas & ink
  static const Color canvas = Color(0xFFFAF7F2);
  static const Color ink = Color(0xFF000000);
  static const Color inkSoft = Color(0xFF6B6B6B);
  static const Color white = Color(0xFFFFFFFF);

  // Legacy aliases kept for compatibility.
  static const Color surface = white;
  static const Color surfaceAlt = Color(0xFFEFEBE3);
  static const Color muted = Color(0xFFF1EDE4);
  static const Color border = ink;

  // Accent palette
  static const Color yellow = Color(0xFFFDE047);
  static const Color yellowSoft = Color(0xFFFEF08A);
  static const Color lavender = Color(0xFFE9D5FF);
  static const Color mint = Color(0xFFA7F3D0);
  static const Color rose = Color(0xFFFECDD3);
  static const Color sky = Color(0xFFBAE6FD);

  // Semantic
  static const Color accent = ink;
  static const Color coral = rose;
  static const Color negative = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color positive = Color(0xFF10B981);

  static const String mono = 'JetBrainsMono';
  static const double radius = 14;
  static const double radiusSm = 10;

  /// Legacy compatibility shims (old UI API).
  static const double borderWidth = 2;
  static const BoxShadow cardShadow =
      BoxShadow(color: ink, offset: Offset(3, 3), blurRadius: 0);
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: white,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        border: Border.all(color: ink, width: 2),
        boxShadow: const [cardShadow],
      );

  /// Hard-edge offset drop shadow (blurless).
  static BoxShadow hardShadow({
    Color color = ink,
    double offset = 3,
    bool strong = false,
  }) {
    return BoxShadow(
      color: color,
      offset: Offset(offset, offset),
      blurRadius: 0,
      spreadRadius: strong ? 0 : 0,
    );
  }

  static BoxDecoration brutalBox({
    Color color = white,
    double radius = 12,
    BorderSide side = const BorderSide(color: ink, width: 2),
    double shadow = 3,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: border2(side),
      boxShadow: [hardShadow(offset: shadow)],
    );
  }

  static Border border2([BorderSide side = const BorderSide(width: 2)]) {
    return Border.fromBorderSide(side);
  }

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: ink,
        onPrimary: white,
        secondary: ink,
        surface: white,
        onSurface: ink,
        error: negative,
        outline: ink,
      ),
      scaffoldBackgroundColor: canvas,
      fontFamily: 'Roboto',
      visualDensity: VisualDensity.standard,
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: _hd(base.textTheme.displayLarge, size: 44),
        headlineMedium: _hd(base.textTheme.headlineMedium, size: 30),
        titleLarge: _hd(base.textTheme.titleLarge, size: 20),
        titleMedium: _hd(base.textTheme.titleMedium, size: 16),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: ink),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(color: inkSoft),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w800,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: ink, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: ink,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
            side: const BorderSide(color: ink, width: 2),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: const TextStyle(color: inkSoft, fontWeight: FontWeight.w500),
        labelStyle: const TextStyle(color: ink, fontWeight: FontWeight.w700),
        prefixStyle: const TextStyle(
          color: ink,
          fontWeight: FontWeight.w700,
          fontFamily: mono,
        ),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(strong: true),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: const BorderSide(color: ink, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: ink, thickness: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: ink, width: 2),
        ),
        titleTextStyle: const TextStyle(
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? white : white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? ink : const Color(0xFFD6D0C6);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? ink : const Color(0xFF6B6B6B)),
      ),
    );
  }

  static TextStyle? _hd(TextStyle? base, {required double size}) {
    return base?.copyWith(
      color: ink,
      fontWeight: FontWeight.w900,
      letterSpacing: -0.8,
    );
  }

  static OutlineInputBorder _inputBorder({bool strong = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radiusSm),
      borderSide: BorderSide(color: ink, width: strong ? 2 : 2),
    );
  }
}

/// Uniform currency formatting helper (font-mono, tabular).
///
/// Amounts are always stored in PKR (base) and formatted in the currently
/// active currency so every figure re-renders when the user switches.
class Money {
  Money(this._pkrAmount);

  final num _pkrAmount;

  /// Formats with the active currency symbol.
  String get mon {
    final cur = Currencies.current.value;
    return formatFor(cur);
  }

  /// Legacy alias — identical to [mon].
  String get rupee => mon;

  String formatFor(Currency cur) {
    final raw = cur.fromPkr(_pkrAmount).toDouble();
    final v = _group(raw == raw.roundToDouble() ? raw.toInt() : raw);
    return '${cur.symbol} $v';
  }
}

String _group(num value) {
  final neg = value < 0;
  final abs = neg ? -value : value;
  final whole = abs.floor();
  final frac = abs - whole;
  final fracStr = frac > 0 ? frac.toStringAsFixed(2).substring(1) : '';
  final negStr = neg ? '-' : '';
  return '$negStr${_thousands(whole)}$fracStr';
}

String _thousands(int n) {
  final s = n.toString();
  if (s.length <= 3) return s;
  var out = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  while (rest.length > 2) {
    out = '${rest.substring(rest.length - 2)},$out';
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) out = '$rest,$out';
  return out;
}

String formatPkr(num value) => Money(value).rupee;