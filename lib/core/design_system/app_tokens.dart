import 'package:flutter/material.dart';

/// A 4 dp spacing scale. Every layout value should come from these tokens (or
/// be a direct multiple of 4) to keep rhythm consistent across screens.
abstract final class AppSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x7 = 28;
  static const double x8 = 32;
  static const double x10 = 40;
  static const double x12 = 48;
  static const double x16 = 64;
}

abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double xxl = 30;
  static const double pill = 999;

  static const BorderRadius small = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius medium = BorderRadius.all(Radius.circular(md));
  static const BorderRadius large = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius extraLarge = BorderRadius.all(Radius.circular(xl));
}

abstract final class AppDurations {
  static const Duration quick = Duration(milliseconds: 120);
  static const Duration short = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);
  static const Duration long = Duration(milliseconds: 380);
}

abstract final class AppIconSizes {
  static const double xs = 14;
  static const double sm = 18;
  static const double md = 22;
  static const double lg = 28;
  static const double xl = 36;
}

abstract final class AppSizes {
  static const double minTapTarget = 48;
  static const double contentMaxWidth = 760;
  static const double cardMinHeight = 108;
  static const double avatar = 40;
  static const double avatarLarge = 88;
  static const double navBarHeight = 72;
  static const double appBarHeight = 64;
}

class AppAccent {
  const AppAccent({
    required this.id,
    required this.labelKey,
    required this.seed,
  });

  final String id;
  final String labelKey;
  final Color seed;
}

abstract final class AppAccents {
  static const indigo = AppAccent(
    id: 'indigo',
    labelKey: 'accentIndigo',
    seed: Color(0xFF4F5BD5),
  );
  static const teal = AppAccent(
    id: 'teal',
    labelKey: 'accentTeal',
    seed: Color(0xFF0E8576),
  );
  static const rose = AppAccent(
    id: 'rose',
    labelKey: 'accentRose',
    seed: Color(0xFFC24B6F),
  );
  static const amber = AppAccent(
    id: 'amber',
    labelKey: 'accentAmber',
    seed: Color(0xFFB27815),
  );
  static const violet = AppAccent(
    id: 'violet',
    labelKey: 'accentViolet',
    seed: Color(0xFF7651C9),
  );
  static const green = AppAccent(
    id: 'green',
    labelKey: 'accentGreen',
    seed: Color(0xFF2D7D5B),
  );
  static const blue = AppAccent(
    id: 'blue',
    labelKey: 'accentBlue',
    seed: Color(0xFF2B6CA3),
  );

  static const all = <AppAccent>[
    indigo,
    teal,
    rose,
    amber,
    violet,
    green,
    blue,
  ];

  static AppAccent byId(String? id) =>
      all.firstWhere((accent) => accent.id == id, orElse: () => indigo);
}

/// Extra semantic colors that Material's [ColorScheme] does not cover.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.card,
    required this.cardMuted,
    required this.codeBackground,
    required this.codeBorder,
    required this.glassTint,
    required this.glassBorder,
    required this.riskLow,
    required this.riskMedium,
    required this.riskHigh,
    required this.success,
    required this.warning,
    required this.star,
    required this.avatarPalette,
  });

  final Color canvas;
  final Color card;
  final Color cardMuted;
  final Color codeBackground;
  final Color codeBorder;
  final Color glassTint;
  final Color glassBorder;
  final Color riskLow;
  final Color riskMedium;
  final Color riskHigh;
  final Color success;
  final Color warning;
  final Color star;
  final List<Color> avatarPalette;

  static const light = AppColors(
    canvas: Color(0xFFF6F7FB),
    card: Color(0xFFFFFFFF),
    cardMuted: Color(0xFFF0F2F8),
    codeBackground: Color(0xFFF3F4F8),
    codeBorder: Color(0xFFE2E5EE),
    glassTint: Color(0xDDFDFDFF),
    glassBorder: Color(0x33FFFFFF),
    riskLow: Color(0xFF2F7D5B),
    riskMedium: Color(0xFF9A6700),
    riskHigh: Color(0xFFB3261E),
    success: Color(0xFF2F7D5B),
    warning: Color(0xFF9A6700),
    star: Color(0xFFB27815),
    avatarPalette: [
      Color(0xFF4F5BD5),
      Color(0xFF0E8576),
      Color(0xFFC24B6F),
      Color(0xFFB27815),
      Color(0xFF7651C9),
      Color(0xFF2D7D5B),
      Color(0xFF2B6CA3),
      Color(0xFF8B5E3C),
      Color(0xFF5D6673),
    ],
  );

  static const dark = AppColors(
    canvas: Color(0xFF0F1117),
    card: Color(0xFF171A22),
    cardMuted: Color(0xFF1E222C),
    codeBackground: Color(0xFF10131A),
    codeBorder: Color(0xFF2A303D),
    glassTint: Color(0xCC161A23),
    glassBorder: Color(0x22FFFFFF),
    riskLow: Color(0xFF7ED7AE),
    riskMedium: Color(0xFFF0C36A),
    riskHigh: Color(0xFFFF8D86),
    success: Color(0xFF7ED7AE),
    warning: Color(0xFFF0C36A),
    star: Color(0xFFF0C36A),
    avatarPalette: [
      Color(0xFF8E97F6),
      Color(0xFF69CBBE),
      Color(0xFFE68BA5),
      Color(0xFFE0B060),
      Color(0xFFB49AF0),
      Color(0xFF7FC9A7),
      Color(0xFF7CB3DE),
      Color(0xFFC7A385),
      Color(0xFF9AA7B8),
    ],
  );

  @override
  AppColors copyWith({
    Color? canvas,
    Color? card,
    Color? cardMuted,
    Color? codeBackground,
    Color? codeBorder,
    Color? glassTint,
    Color? glassBorder,
    Color? riskLow,
    Color? riskMedium,
    Color? riskHigh,
    Color? success,
    Color? warning,
    Color? star,
    List<Color>? avatarPalette,
  }) {
    return AppColors(
      canvas: canvas ?? this.canvas,
      card: card ?? this.card,
      cardMuted: cardMuted ?? this.cardMuted,
      codeBackground: codeBackground ?? this.codeBackground,
      codeBorder: codeBorder ?? this.codeBorder,
      glassTint: glassTint ?? this.glassTint,
      glassBorder: glassBorder ?? this.glassBorder,
      riskLow: riskLow ?? this.riskLow,
      riskMedium: riskMedium ?? this.riskMedium,
      riskHigh: riskHigh ?? this.riskHigh,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      star: star ?? this.star,
      avatarPalette: avatarPalette ?? this.avatarPalette,
    );
  }

  @override
  AppColors lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardMuted: Color.lerp(cardMuted, other.cardMuted, t)!,
      codeBackground: Color.lerp(codeBackground, other.codeBackground, t)!,
      codeBorder: Color.lerp(codeBorder, other.codeBorder, t)!,
      glassTint: Color.lerp(glassTint, other.glassTint, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      riskLow: Color.lerp(riskLow, other.riskLow, t)!,
      riskMedium: Color.lerp(riskMedium, other.riskMedium, t)!,
      riskHigh: Color.lerp(riskHigh, other.riskHigh, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      star: Color.lerp(star, other.star, t)!,
      avatarPalette: avatarPalette,
    );
  }
}

extension AppThemeX on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  ColorScheme get scheme => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  EdgeInsets get screenPadding =>
      const EdgeInsets.symmetric(horizontal: AppSpacing.x5);
}
