import 'package:flutter/material.dart';

import '../../core/design_system/app_tokens.dart';

/// Standard full-screen page used by secondary destinations. It keeps the app
/// bar flat, centers long content on tablets, and respects the keyboard inset
/// when a form is open.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.leading,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.maxWidth = AppSizes.contentMaxWidth,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.x5,
      AppSpacing.x2,
      AppSpacing.x5,
      AppSpacing.x8,
    ),
    this.resizeToAvoidBottomInset = true,
    this.scrollable = true,
    this.backgroundColor,
    this.extendBody = false,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final double maxWidth;
  final EdgeInsetsGeometry padding;
  final bool resizeToAvoidBottomInset;
  final bool scrollable;
  final Color? backgroundColor;

  /// Lets the body paint behind a translucent [bottomNavigationBar]. Pages that
  /// enable this should reserve `MediaQuery.padding.bottom` in their scroll
  /// extent.
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
    return Scaffold(
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      appBar: AppBar(title: Text(title), leading: leading, actions: actions),
      body: scrollable
          ? SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.zero,
              child: content,
            )
          : content,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}

/// An empty scaffolding state that still has a working back button.
class AppMessageScaffold extends StatelessWidget {
  const AppMessageScaffold({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppPage(title: title, scrollable: false, child: child);
  }
}
