import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import '../../core/design_system/app_tokens.dart';
import '../settings/app_settings.dart';

/// Builds the application's light and dark Material 3 themes from the user's
/// accent, typography and density preferences. Design tokens live in
/// [AppSpacing], [AppRadius] and [AppColors]; this file only maps them onto
/// Material components.
abstract final class AppTheme {
  static ThemeData build(AppSettings settings, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final accent = AppAccents.byId(settings.accentId);
    final palette = dark ? AppColors.dark : AppColors.light;
    final scheme = _scheme(accent.seed, palette, brightness);
    final font = settings.font;
    final baseText = _textTheme(brightness, settings.fontScale);
    final textTheme = font.family == null
        ? baseText.apply(fontFamilyFallback: const [AppFonts.myanmarFallback])
        : baseText.apply(
            fontFamily: font.family,
            fontFamilyFallback: const [AppFonts.myanmarFallback],
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.canvas,
      cardColor: palette.card,
      dividerColor: scheme.outlineVariant.withValues(alpha: 0.55),
      fontFamily: font.family,
      fontFamilyFallback: const [AppFonts.myanmarFallback],
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      extensions: [palette],
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: palette.canvas,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: AppSizes.appBarHeight,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(
          color: scheme.onSurface,
          size: AppIconSizes.md,
        ),
        actionsIconTheme: IconThemeData(
          color: scheme.onSurface,
          size: AppIconSizes.md,
        ),
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.large,
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: palette.cardMuted,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x4,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.8),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.medium,
          borderSide: BorderSide(color: scheme.error, width: 1.6),
        ),
        helperStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: scheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizes.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
          side: BorderSide(color: scheme.outlineVariant),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSizes.minTapTarget),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.small),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.minTapTarget),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.small),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.cardMuted,
        selectedColor: scheme.primaryContainer,
        disabledColor: palette.cardMuted.withValues(alpha: 0.5),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
        shape: const StadiumBorder(),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onPrimaryContainer,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x2,
          vertical: AppSpacing.x1,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.glassTint,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: AppSizes.navBarHeight,
        indicatorColor: scheme.primary.withValues(alpha: dark ? 0.24 : 0.14),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: AppIconSizes.md,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: palette.card,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        modalBackgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        constraints: const BoxConstraints(maxWidth: 720),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.5,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: dark
            ? const Color(0xFF262B36)
            : const Color(0xFF232833),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: Colors.white.withValues(alpha: 0.94),
        ),
        actionTextColor: dark ? palette.star : const Color(0xFFD5DBFF),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        insetPadding: const EdgeInsets.all(AppSpacing.x4),
        elevation: 2,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.55),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x4,
          vertical: AppSpacing.x1,
        ),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.medium),
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        subtitleTextStyle: textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: palette.cardMuted,
        circularTrackColor: palette.cardMuted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.onPrimary
              : scheme.onSurfaceVariant,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.surfaceContainerHighest,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: scheme.primary,
        inactiveTrackColor: palette.cardMuted,
        thumbColor: scheme.primary,
        overlayColor: scheme.primary.withValues(alpha: 0.12),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.compact,
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
          side: WidgetStatePropertyAll(
            BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
          ),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        // Tooltips use Flutter's built-in long-press feedback. It cannot
        // express the app's intensity levels, so suppress it entirely when the
        // user has turned vibration off instead of letting the platform buzz.
        enableFeedback: settings.vibration != VibrationIntensity.off,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF2D3340) : const Color(0xFF2A2F3A),
          borderRadius: AppRadius.small,
        ),
        textStyle: textTheme.bodySmall?.copyWith(color: Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.large),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.primary,
        selectionColor: scheme.primary.withValues(alpha: 0.22),
        selectionHandleColor: scheme.primary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
        textStyle: textTheme.bodyMedium,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(
          scheme.onSurfaceVariant.withValues(alpha: 0.35),
        ),
        radius: const Radius.circular(AppRadius.pill),
        thickness: const WidgetStatePropertyAll(5),
      ),
    );
  }

  static ColorScheme _scheme(
    Color seed,
    AppColors palette,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    final generated = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
      contrastLevel: 0,
    );
    return generated.copyWith(
      surface: palette.card,
      onSurface: dark ? const Color(0xFFE7EAF2) : const Color(0xFF1B1F28),
      surfaceContainerLowest: palette.canvas,
      surfaceContainerLow: palette.card,
      surfaceContainer: palette.cardMuted,
      surfaceContainerHigh: dark
          ? const Color(0xFF232833)
          : const Color(0xFFE9ECF3),
      surfaceContainerHighest: dark
          ? const Color(0xFF2A303C)
          : const Color(0xFFE2E6EF),
      outlineVariant: dark ? const Color(0xFF343B48) : const Color(0xFFDDE1EA),
      onSurfaceVariant: dark
          ? const Color(0xFFAEB6C6)
          : const Color(0xFF586070),
      primary: dark ? generated.primary : generated.primary,
      onPrimary: generated.onPrimary,
      primaryContainer: dark
          ? generated.primaryContainer.withValues(alpha: 0.72)
          : generated.primaryContainer,
      onPrimaryContainer: generated.onPrimaryContainer,
      error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
      onError: dark ? const Color(0xFF690005) : Colors.white,
      errorContainer: dark ? const Color(0xFF93000A) : const Color(0xFFF9DEDC),
      onErrorContainer: dark
          ? const Color(0xFFFFDAD6)
          : const Color(0xFF410E0B),
    );
  }

  /// A restrained, product-style type scale. Sizes are intentionally not huge;
  /// the app is information dense and should remain readable on small phones.
  static TextTheme _textTheme(Brightness brightness, double scale) {
    final base = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final theme = base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.12,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 37,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.9,
        height: 1.13,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
        height: 1.15,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.22,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.28,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.3,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        height: 1.35,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.55,
        letterSpacing: 0,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14,
        height: 1.55,
        letterSpacing: 0,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12.5,
        height: 1.45,
        letterSpacing: 0.05,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
    );

    final factor = scale.isFinite ? scale.clamp(0.8, 1.35) : 1.0;
    return TextTheme(
      displayLarge: _scaled(theme.displayLarge, factor),
      displayMedium: _scaled(theme.displayMedium, factor),
      displaySmall: _scaled(theme.displaySmall, factor),
      headlineLarge: _scaled(theme.headlineLarge, factor),
      headlineMedium: _scaled(theme.headlineMedium, factor),
      headlineSmall: _scaled(theme.headlineSmall, factor),
      titleLarge: _scaled(theme.titleLarge, factor),
      titleMedium: _scaled(theme.titleMedium, factor),
      titleSmall: _scaled(theme.titleSmall, factor),
      bodyLarge: _scaled(theme.bodyLarge, factor),
      bodyMedium: _scaled(theme.bodyMedium, factor),
      bodySmall: _scaled(theme.bodySmall, factor),
      labelLarge: _scaled(theme.labelLarge, factor),
      labelMedium: _scaled(theme.labelMedium, factor),
      labelSmall: _scaled(theme.labelSmall, factor),
    );
  }

  /// Applies the user's font-size preference to a single style.
  ///
  /// [TextTheme.apply] asserts that every style has an explicit `fontSize`, and
  /// Material's 2021 typography leaves several entries unsized, which made any
  /// non-default font scale crash the app on the next launch. Scaling per style
  /// keeps unsized entries untouched and cannot brick startup.
  static TextStyle? _scaled(TextStyle? style, double factor) {
    final size = style?.fontSize;
    if (style == null || size == null) return style;
    return style.copyWith(fontSize: size * factor);
  }
}

extension AppTextStyles on BuildContext {
  TextStyle get monoStyle {
    final base = texts.bodyMedium ?? const TextStyle();
    return base.copyWith(
      fontFamily: AppFonts.commandMonoFamily,
      fontFamilyFallback: const [AppFonts.myanmarFallback],
      fontSize: (base.fontSize ?? 14) * 0.94,
      height: 1.55,
      letterSpacing: 0,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
