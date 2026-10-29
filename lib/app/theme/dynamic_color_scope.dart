import 'package:flutter/widgets.dart';

/// Reports whether the platform supplied wallpaper-based colors.
///
/// The app root installs this once `DynamicColorBuilder` resolves the system
/// palette. Appearance uses it to hide the wallpaper switch on devices older
/// than Android 12 instead of offering a setting that cannot take effect.
class DynamicColorScope extends InheritedWidget {
  const DynamicColorScope({
    super.key,
    required this.isSupported,
    required super.child,
  });

  final bool isSupported;

  static bool isSupportedOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<DynamicColorScope>()
            ?.isSupported ??
        false;
  }

  @override
  bool updateShouldNotify(DynamicColorScope oldWidget) {
    return oldWidget.isSupported != isSupported;
  }
}
