import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../core/design_system/app_tokens.dart';
import '../../shared/utils/markdown_styles.dart';
import '../../shared/utils/url_actions.dart';
import '../../shared/widgets/section_header.dart';

/// Bundled, offline help. The Markdown asset documents setup, connectivity,
/// privacy and Termux behavior without requiring a browser.
class DocsScreen extends StatefulWidget {
  const DocsScreen({super.key});

  @override
  State<DocsScreen> createState() => _DocsScreenState();
}

class _DocsScreenState extends State<DocsScreen> {
  Future<String>? _content;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _content ??= _load();
  }

  Future<String> _load() => rootBundle.loadString('assets/docs/help_center.md');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.documentation)),
      body: FutureBuilder<String>(
        future: _content,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const LoadingState();
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return ErrorStateView(
              message: l10n.somethingWentWrong,
              onRetry: () => setState(() => _content = _load()),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x3,
              AppSpacing.x5,
              AppSpacing.x8,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: MarkdownBody(
                  data: snapshot.data!,
                  selectable: true,
                  styleSheet: appMarkdownStyle(context),
                  onTapLink: (_, href, _) {
                    if (href != null && href.isNotEmpty) {
                      openExternalUrl(context, href);
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
