import 'dart:ui';

import 'package:flutter/material.dart';

/// Najd TV — Modern Brand Identity & Design System (v2.0)
///
/// موجّه لـ شوشو:
/// 1. تأكد من تعريف الخطوط في `pubspec.yaml` تحت الأسماء التالية:
///    - `ThmanyahSans` (للواجهات، الأزرار، القوائم، والبطاقات)
///    - `ThmanyahSerif` (للعناوين الكبرى وشاشة البداية - أبيات ابن قرملة)
/// 2. استخدم `NajdTheme.dark(isTv: ...)` كوضع افتراضي للبث، و `NajdTheme.light(isTv: ...)` للوضع الفاتح.
/// 3. استخدم `NajdContrast.onColor(bg)` لأي خلفية ديناميكية لضمان التباين الذكي (Smart Contrast).

abstract final class NajdColors {
  // ── Dark Mode (Default Streaming Experience) ──────────────────────────────
  static const Color darkBackground = Color(0xFF090712);
  static const Color darkSurface = Color(0xFF131022);
  static const Color darkSurfaceElevated = Color(0xFF1B1630);
  static const Color darkSurfaceGlass = Color(0xBF1C1733); // 75% opacity
  static const Color darkPrimary = Color(0xFF7C3AED);
  static const Color darkAccentGlow = Color(0xFFA78BFA);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFFA19BB5);
  static const Color darkBorder = Color(0x26A78BFA); // 15% lavender tint

  // ── Light Mode ────────────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8F7FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF1EEF9);
  static const Color lightSurfaceGlass = Color(0xCCEFEBF9); // 80% opacity
  static const Color lightPrimary = Color(0xFF5B21B6);
  static const Color lightAccentGlow = Color(0xFF7C3AED);
  static const Color lightTextPrimary = Color(0xFF110D1F);
  static const Color lightTextSecondary = Color(0xFF5B5470);
  static const Color lightBorder = Color(0x245B21B6); // 14% lavender tint

  // ── Semantic Status Colors ────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
}

/// دوال التباين الذكي (Smart Contrast) لمنع اختفاء النصوص فوق أي خلفية.
abstract final class NajdContrast {
  static bool isDark(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark;

  static Color onColor(Color background) => isDark(background)
      ? NajdColors.darkTextPrimary
      : NajdColors.lightTextPrimary;

  static Color mutedOnColor(Color background) => isDark(background)
      ? NajdColors.darkTextSecondary
      : NajdColors.lightTextSecondary;
}

/// امتداد مخصص لتمرير خصائص نجد البصرية (الزجاجية، توهج التلفاز، خط العناوين) عبر Widget Tree.
@immutable
class NajdThemeExtension extends ThemeExtension<NajdThemeExtension> {
  const NajdThemeExtension({
    required this.surfaceGlass,
    required this.surfaceElevated,
    required this.accentGlow,
    required this.borderSubtle,
    required this.serifFontFamily,
    required this.sansFontFamily,
    required this.isTv,
  });

  final Color surfaceGlass;
  final Color surfaceElevated;
  final Color accentGlow;
  final Color borderSubtle;
  final String serifFontFamily;
  final String sansFontFamily;
  final bool isTv;

  static NajdThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<NajdThemeExtension>() ??
        const NajdThemeExtension(
          surfaceGlass: NajdColors.darkSurfaceGlass,
          surfaceElevated: NajdColors.darkSurfaceElevated,
          accentGlow: NajdColors.darkAccentGlow,
          borderSubtle: NajdColors.darkBorder,
          serifFontFamily: 'NajdArabicFallback',
          sansFontFamily: 'NajdArabicFallback',
          isTv: false,
        );
  }

  /// إطار التركيز المتوهج لنسخة التلفاز (Android TV) وسطح المكتب.
  BoxDecoration tvFocusDecoration({
    required bool isFocused,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(14)),
    Color? backgroundColor,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius,
      border: Border.all(
        color: isFocused ? accentGlow : borderSubtle,
        width: isFocused ? 2.2 : 1.0,
      ),
      boxShadow: isFocused
          ? [
              BoxShadow(
                color: accentGlow.withValues(alpha: 0.38),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ]
          : null,
    );
  }

  @override
  NajdThemeExtension copyWith({
    Color? surfaceGlass,
    Color? surfaceElevated,
    Color? accentGlow,
    Color? borderSubtle,
    String? serifFontFamily,
    String? sansFontFamily,
    bool? isTv,
  }) {
    return NajdThemeExtension(
      surfaceGlass: surfaceGlass ?? this.surfaceGlass,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      accentGlow: accentGlow ?? this.accentGlow,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      serifFontFamily: serifFontFamily ?? this.serifFontFamily,
      sansFontFamily: sansFontFamily ?? this.sansFontFamily,
      isTv: isTv ?? this.isTv,
    );
  }

  @override
  NajdThemeExtension lerp(ThemeExtension<NajdThemeExtension>? other, double t) {
    if (other is! NajdThemeExtension) return this;
    return NajdThemeExtension(
      surfaceGlass: Color.lerp(surfaceGlass, other.surfaceGlass, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      serifFontFamily: t < 0.5 ? serifFontFamily : other.serifFontFamily,
      sansFontFamily: t < 0.5 ? sansFontFamily : other.sansFontFamily,
      isTv: t < 0.5 ? isTv : other.isTv,
    );
  }
}

/// ويدجت جاهزة للخلفيات الزجاجية الضبابية (القائمة الجانبية للتلفاز وشريط المشغل).
class NajdGlassContainer extends StatelessWidget {
  const NajdGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding,
    this.blurSigma = 18,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final ext = NajdThemeExtension.of(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: ext.surfaceGlass,
            borderRadius: borderRadius,
            border: Border.all(color: ext.borderSubtle),
          ),
          child: child,
        ),
      ),
    );
  }
}
