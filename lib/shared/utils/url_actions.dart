import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/ui_actions.dart';

/// Opens an externally hosted guide in the user's browser. Keeping this in one
/// place makes the app's outgoing URLs easy to audit and test.
Future<void> openExternalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    context.showSnack('This link is not valid.');
    return;
  }
  try {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      context.showSnack('No browser is available to open this link.');
    }
  } catch (error) {
    if (context.mounted) context.showErrorSnack(error);
  }
}
