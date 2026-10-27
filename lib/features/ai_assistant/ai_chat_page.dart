import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/design_system/app_tokens.dart';
import '../../data/models/ai_models.dart';
import '../../data/services/ai/ai_prompts.dart';
import '../../data/services/haptics_service.dart';
import '../../shared/utils/app_formatters.dart';
import '../../shared/utils/error_messages.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/app_logo.dart';
import '../../shared/widgets/app_note.dart';
import '../../shared/widgets/section_header.dart';
import 'ai_message_bubble.dart';
import 'ai_setup_card.dart';

/// Shared conversation surface for the assistant tab and command context.
///
/// The page owns only transient stream state. Persisted messages come from
/// SQLite, and the provider history is rebuilt from SQLite immediately before
/// each request so a stale UI list can never change what is sent.
class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({
    super.key,
    this.conversationId,
    this.commandId,
    this.initialPrompt,
  });

  final String? conversationId;
  final String? commandId;
  final String? initialPrompt;

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _inputFocus = FocusNode();

  String? _conversationId;
  AiAttachment? _attachment;
  bool _attachmentTruncated = false;
  bool _picking = false;
  bool _sending = false;
  String _streamText = '';
  AiUsage _streamUsage = const AiUsage();
  bool _streamCached = false;
  String? _error;
  bool _retryAvailable = false;
  String? _lastProviderContent;
  StreamSubscription<AiStreamDelta>? _subscription;
  int _generation = 0;
  int _lastRenderedCount = -1;
  bool _promptInitialized = false;

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_promptInitialized) return;
    _promptInitialized = true;
    if (_conversationId != null) return;
    final initial = widget.initialPrompt?.trim() ?? '';
    if (initial.isNotEmpty) {
      _input.text = initial;
    } else if (widget.commandId != null) {
      _input.text = AppLocalizations.of(context).explainCommand;
    }
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_subscription?.cancel());
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final keyAsync = ref.watch(aiKeyPresentProvider);
    final models = ref.watch(aiModelsProvider).value ?? const <AiModelInfo>[];
    final availability = resolveAiAvailability(
      settings: settings,
      keyAsync: keyAsync,
      models: models,
    );
    final conversationId = _conversationId;
    final conversation = conversationId == null
        ? null
        : ref.watch(aiConversationProvider(conversationId)).value;
    final messagesAsync = conversationId == null
        ? null
        : ref.watch(aiMessagesProvider(conversationId));
    final messages = messagesAsync?.value ?? const <AiStoredMessage>[];

    String? commandName;
    if (widget.commandId != null) {
      final command = ref.watch(commandProvider(widget.commandId!)).value;
      if (command != null) {
        commandName = command.name;
      }
    }

    final modelLabel = _modelLabel(models, settings.aiModelId);
    final displayTitle = (conversation?.title.trim().isNotEmpty ?? false)
        ? conversation!.title
        : l10n.aiAssistant;

    _scheduleScroll(messages.length + (_sending ? 1 : 0));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (modelLabel != null)
              Text(
                modelLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.texts.labelSmall?.copyWith(
                  color: context.scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: l10n.newChat,
            onPressed: _startNewChat,
            icon: const Icon(Icons.add_comment_outlined),
          ),
          IconButton(
            tooltip: l10n.chatHistory,
            onPressed: () => context.push('/ai/history'),
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (commandName != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x4,
                AppSpacing.x2,
                AppSpacing.x4,
                0,
              ),
              child: AppNote(
                title: l10n.aiContext,
                message: commandName,
                icon: Icons.terminal_rounded,
                tone: AppNoteTone.info,
              ),
            ),
          Expanded(
            child: messages.isEmpty && !_sending && _error == null
                ? _ChatWelcome(
                    availability: availability,
                    onSuggestion: _applySuggestion,
                  )
                : ListView(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.x4,
                      AppSpacing.x3,
                      AppSpacing.x4,
                      AppSpacing.x4,
                    ),
                    children: [
                      for (final message in messages)
                        AiMessageBubble(
                          key: ValueKey(message.id),
                          role: message.role,
                          text: message.content,
                          attachmentName: message.attachmentName,
                          usage: message.usage,
                          createdAt: message.createdAt,
                          onCopy: () =>
                              copyWithFeedback(context, ref, message.content),
                        ),
                      if (_sending)
                        AiMessageBubble(
                          role: AiMessageRole.assistant,
                          text: _streamText,
                          usage: _streamUsage,
                          streaming: true,
                          cached: _streamCached,
                        ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.x2),
                          child: AppNote(
                            message: _error!,
                            tone: AppNoteTone.danger,
                            icon: Icons.error_outline_rounded,
                            actionLabel: _retryAvailable ? l10n.retry : null,
                            onAction: _retryAvailable ? _retry : null,
                          ),
                        ),
                    ],
                  ),
          ),
          _Composer(
            controller: _input,
            focusNode: _inputFocus,
            attachment: _attachment,
            attachmentTruncated: _attachmentTruncated,
            picking: _picking,
            sending: _sending,
            showSetupNotice: messages.isNotEmpty || _sending,
            onAttach: _pickAttachment,
            onRemoveAttachment: _removeAttachment,
            onSend: _send,
            onStop: _stop,
          ),
        ],
      ),
    );
  }

  String? _modelLabel(List<AiModelInfo> models, String selectedId) {
    if (selectedId.trim().isEmpty) return null;
    for (final model in models) {
      if (model.id == selectedId) {
        return model.displayName;
      }
    }
    return selectedId;
  }

  void _scheduleScroll(int count) {
    if (count == _lastRenderedCount) return;
    _lastRenderedCount = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToBottom(force: true);
    });
  }

  void _scrollToBottom({bool force = false}) {
    if (!_scroll.hasClients) return;
    final position = _scroll.position;
    if (!force && position.extentAfter > 260) return;
    position.animateTo(
      position.maxScrollExtent,
      duration: AppDurations.short,
      curve: Curves.easeOut,
    );
  }

  void _applySuggestion(String prompt) {
    unawaited(triggerHaptic(ref, cue: HapticCue.selection));
    _input.text = prompt;
    _input.selection = TextSelection.collapsed(offset: prompt.length);
    _inputFocus.requestFocus();
  }

  Future<void> _pickAttachment() async {
    if (_picking || _sending) return;
    final l10n = AppLocalizations.of(context);
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    setState(() => _picking = true);
    try {
      final attachment = await ref
          .read(fileAttachmentServiceProvider)
          .pickTextFile();
      if (!mounted) return;
      if (attachment != null) {
        setState(() {
          _attachment = attachment;
          _attachmentTruncated =
              attachment.content.length >
              AppConstants.aiMaxPromptAttachmentCharacters;
        });
        unawaited(triggerHaptic(ref, cue: HapticCue.success));
        context.showSnack(l10n.attachmentAdded);
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _removeAttachment() {
    unawaited(triggerHaptic(ref, cue: HapticCue.toggle));
    setState(() {
      _attachment = null;
      _attachmentTruncated = false;
    });
  }

  Future<void> _send() async {
    if (_sending) return;
    final l10n = AppLocalizations.of(context);
    final text = _input.text.trim();
    if (text.isEmpty) {
      context.showSnack(l10n.requiredField);
      _inputFocus.requestFocus();
      return;
    }
    if (text.length > AppConstants.aiMaxComposerCharacters) {
      context.showSnack(l10n.errorAiRequestTooLarge);
      return;
    }

    final settings = ref.read(settingsControllerProvider);
    final models = ref.read(aiModelsProvider).value ?? const <AiModelInfo>[];
    final availability = resolveAiAvailability(
      settings: settings,
      keyAsync: ref.read(aiKeyPresentProvider),
      models: models,
    );
    if (availability != AiAvailability.ready) {
      context.showSnack(l10n.aiNoProviderConfigured);
      context.push('/settings/ai');
      return;
    }

    final repo = ref.read(aiRepositoryProvider);
    final attachment = _attachment;
    final providerContent = _providerContent(text, attachment);
    final generation = ++_generation;

    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    setState(() {
      _sending = true;
      _streamText = '';
      _streamUsage = const AiUsage();
      _streamCached = false;
      _error = null;
      _retryAvailable = false;
    });

    var createdNew = false;
    _lastProviderContent = providerContent;
    try {
      var conversationId = _conversationId;
      if (conversationId == null) {
        final conversation = await repo.createConversation(
          title: text,
          modelId: settings.aiModelId,
        );
        conversationId = conversation.id;
        createdNew = true;
        if (!mounted || generation != _generation) return;
        setState(() => _conversationId = conversationId);
      }
      await repo.updateConversationModel(conversationId, settings.aiModelId);
      await repo.appendUserMessage(
        conversationId: conversationId,
        content: text,
        attachmentName: attachment?.name ?? '',
      );
      if (!mounted || generation != _generation) return;

      _input.clear();
      _attachment = null;
      _attachmentTruncated = false;
      _inputFocus.unfocus();
      _scrollToBottom(force: true);
      await _generate(
        conversationId: conversationId,
        providerUserContent: providerContent,
        generation: generation,
      );
    } catch (error) {
      if (!mounted || generation != _generation) return;
      if (createdNew && _conversationId != null) {
        final id = _conversationId;
        try {
          await repo.deleteConversation(id!);
        } catch (_) {
          // An empty draft conversation is harmless if cleanup fails.
        }
        if (mounted) setState(() => _conversationId = null);
      }
      unawaited(triggerHaptic(ref, cue: HapticCue.error));
      setState(() {
        _sending = false;
        _streamText = '';
        _error = localizeError(l10n, error);
        _retryAvailable = _lastProviderContent != null;
      });
    }
  }

  String _providerContent(String text, AiAttachment? attachment) {
    if (attachment == null) return text;
    final limit = AppConstants.aiMaxPromptAttachmentCharacters;
    final clipped = attachment.content.length > limit
        ? attachment.content.substring(0, limit)
        : attachment.content;
    final buffer = StringBuffer()
      ..writeln(text)
      ..writeln()
      ..writeln('[Attached file: ${attachment.name}]')
      ..write(clipped);
    if (attachment.content.length > limit) {
      buffer
        ..writeln()
        ..writeln(
          '[The app truncated this file to the first $limit characters.]',
        );
    }
    return buffer.toString();
  }

  Future<void> _generate({
    required String conversationId,
    String? providerUserContent,
    required int generation,
  }) async {
    final l10n = AppLocalizations.of(context);
    final repo = ref.read(aiRepositoryProvider);
    final stored = await repo.readMessages(conversationId);
    AiStoredMessage? lastUser;
    for (final message in stored) {
      if (message.role == AiMessageRole.user) lastUser = message;
    }

    final history = <AiPromptMessage>[];
    for (final message in stored) {
      if (message.role == AiMessageRole.system) continue;
      var content = message.content;
      if (providerUserContent != null &&
          lastUser != null &&
          message.id == lastUser.id) {
        content = providerUserContent;
      }
      history.add(AiPromptMessage(role: message.role, content: content));
    }
    if (history.length > AppConstants.aiMaxHistoryMessages) {
      history.removeRange(
        0,
        history.length - AppConstants.aiMaxHistoryMessages,
      );
    }
    while (history.isNotEmpty &&
        history.first.role == AiMessageRole.assistant) {
      history.removeAt(0);
    }
    if (history.isEmpty || history.last.role != AiMessageRole.user) {
      if (mounted && generation == _generation) {
        setState(() {
          _sending = false;
          _error = l10n.somethingWentWrong;
        });
      }
      return;
    }

    String? commandContext;
    if (widget.commandId != null) {
      final command = ref.read(commandProvider(widget.commandId!)).value;
      if (command != null) {
        commandContext = AiPromptBuilder.commandContextFor(command);
      }
    }

    final buffer = StringBuffer();
    var usage = const AiUsage();
    var cachedShown = false;

    try {
      final stream = repo.streamChat(
        messages: history,
        commandContext: commandContext,
      );
      _subscription = stream.listen(
        (delta) {
          if (!mounted || generation != _generation) return;
          if (delta.text.isNotEmpty) {
            buffer.write(delta.text);
            setState(() {
              _streamText = buffer.toString();
              if (delta.usage != null) _streamUsage = delta.usage!;
            });
            _scrollToBottom();
          }
          if (delta.cached && !cachedShown) {
            cachedShown = true;
            setState(() => _streamCached = true);
            context.showSnack(l10n.cacheHit);
          }
          if (delta.usage != null) usage = delta.usage!;
        },
        onError: (Object error, StackTrace stack) {
          if (!mounted || generation != _generation) return;
          _subscription = null;
          unawaited(triggerHaptic(ref, cue: HapticCue.error));
          setState(() {
            _sending = false;
            _streamText = '';
            _streamCached = false;
            _error = localizeError(l10n, error);
            _retryAvailable = _lastProviderContent != null;
          });
        },
        onDone: () async {
          if (!mounted || generation != _generation) return;
          _subscription = null;
          final answer = buffer.toString().trim();
          if (answer.isEmpty) {
            unawaited(triggerHaptic(ref, cue: HapticCue.error));
            setState(() {
              _sending = false;
              _streamText = '';
              _streamCached = false;
              _error = l10n.errorAiEmptyResponse;
              _retryAvailable = _lastProviderContent != null;
            });
            return;
          }
          try {
            await repo.appendAssistantMessage(
              conversationId: conversationId,
              content: answer,
              usage: usage,
            );
            if (!mounted || generation != _generation) return;
            unawaited(triggerHaptic(ref, cue: HapticCue.success));
            setState(() {
              _sending = false;
              _streamText = '';
              _streamUsage = const AiUsage();
              _streamCached = false;
              _error = null;
              _retryAvailable = false;
              _lastProviderContent = null;
            });
            _scrollToBottom(force: true);
          } catch (error) {
            if (!mounted || generation != _generation) return;
            unawaited(triggerHaptic(ref, cue: HapticCue.error));
            setState(() {
              _sending = false;
              _streamText = answer;
              _error = localizeError(l10n, error);
              _retryAvailable = false;
            });
          }
        },
        cancelOnError: true,
      );
    } catch (error) {
      if (!mounted || generation != _generation) return;
      unawaited(triggerHaptic(ref, cue: HapticCue.error));
      setState(() {
        _sending = false;
        _error = localizeError(l10n, error);
        _retryAvailable = _lastProviderContent != null;
      });
    }
  }

  Future<void> _stop() async {
    final l10n = AppLocalizations.of(context);
    unawaited(triggerHaptic(ref, cue: HapticCue.warning));
    _generation++;
    await _subscription?.cancel();
    _subscription = null;
    if (!mounted) return;
    setState(() {
      _sending = false;
      _streamText = '';
      _streamUsage = const AiUsage();
      _streamCached = false;
      _error = l10n.errorAiCancelled;
      _retryAvailable = _lastProviderContent != null;
    });
  }

  Future<void> _retry() async {
    final conversationId = _conversationId;
    final providerContent = _lastProviderContent;
    if (conversationId == null || providerContent == null) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    final generation = ++_generation;
    setState(() {
      _sending = true;
      _streamText = '';
      _error = null;
      _retryAvailable = false;
    });
    try {
      await _generate(
        conversationId: conversationId,
        providerUserContent: providerContent,
        generation: generation,
      );
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _sending = false;
        _error = localizeError(AppLocalizations.of(context), error);
        _retryAvailable = true;
      });
    }
  }

  Future<void> _startNewChat() async {
    unawaited(triggerHaptic(ref, cue: HapticCue.selection));
    if (_sending) {
      await _stop();
    }
    if (!mounted) return;
    context.pushReplacement('/assistant/chat');
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.attachment,
    required this.attachmentTruncated,
    required this.picking,
    required this.sending,
    required this.showSetupNotice,
    required this.onAttach,
    required this.onRemoveAttachment,
    required this.onSend,
    required this.onStop,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final AiAttachment? attachment;
  final bool attachmentTruncated;
  final bool picking;
  final bool sending;
  final bool showSetupNotice;
  final VoidCallback onAttach;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onSend;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.canvas,
        border: Border(
          top: BorderSide(
            color: context.scheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x4,
            AppSpacing.x2,
            AppSpacing.x4,
            AppSpacing.x3,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showSetupNotice) const AiComposerNotice(),
              if (attachment != null) ...[
                _AttachmentCard(
                  attachment: attachment!,
                  truncated: attachmentTruncated,
                  onRemove: onRemoveAttachment,
                ),
                const SizedBox(height: AppSpacing.x2),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: l10n.attachFile,
                    onPressed: sending ? null : onAttach,
                    icon: picking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.attach_file_rounded),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 6,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: l10n.askAiHint,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.x3,
                          vertical: AppSpacing.x3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x2),
                  if (sending)
                    IconButton.filledTonal(
                      tooltip: l10n.stopGenerating,
                      onPressed: onStop,
                      icon: const Icon(Icons.stop_rounded),
                    )
                  else
                    IconButton.filled(
                      tooltip: l10n.send,
                      onPressed: onSend,
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.x1),
              Text(
                l10n.aiPrivacyNote,
                textAlign: TextAlign.center,
                style: context.texts.labelSmall?.copyWith(
                  color: context.scheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  const _AttachmentCard({
    required this.attachment,
    required this.truncated,
    required this.onRemove,
  });

  final AiAttachment attachment;
  final bool truncated;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x3,
        AppSpacing.x2,
        AppSpacing.x1,
        AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: context.appColors.cardMuted,
        borderRadius: AppRadius.medium,
        border: Border.all(
          color: context.scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.description_outlined,
            size: AppIconSizes.sm,
            color: context.scheme.primary,
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  truncated
                      ? l10n.attachmentTruncated(
                          AppConstants.aiMaxPromptAttachmentCharacters,
                        )
                      : '${l10n.attachmentHelp}  ${AppFormatters.bytes(attachment.sizeBytes)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.texts.labelSmall?.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.removeAttachment,
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: AppIconSizes.sm),
          ),
        ],
      ),
    );
  }
}

class _ChatWelcome extends StatelessWidget {
  const _ChatWelcome({required this.availability, required this.onSuggestion});

  final AiAvailability availability;
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final suggestions = <(IconData, String)>[
      (Icons.menu_book_outlined, l10n.suggestionExplain),
      (Icons.build_circle_outlined, l10n.suggestionFix),
      (Icons.terminal_rounded, l10n.suggestionScript),
      (Icons.translate_rounded, l10n.suggestionTranslate),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x5,
        AppSpacing.x8,
        AppSpacing.x5,
        AppSpacing.x6,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AppLogo(size: 62, showShadow: true)),
              const SizedBox(height: AppSpacing.x4),
              Text(
                l10n.aiWelcomeTitle,
                textAlign: TextAlign.center,
                style: context.texts.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.x2),
              Text(
                l10n.aiWelcomeBody,
                textAlign: TextAlign.center,
                style: context.texts.bodyMedium?.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.x5),
              if (availability != AiAvailability.ready) ...[
                const AiSetupCard(),
                const SizedBox(height: AppSpacing.x3),
                AppNote(
                  message: l10n.aiPrivacyNote,
                  icon: Icons.lock_outline_rounded,
                ),
              ] else ...[
                SectionHeader(
                  title: l10n.suggestions,
                  subtitle: l10n.aiAssistantSubtitle,
                ),
                const SizedBox(height: AppSpacing.x3),
                for (final suggestion in suggestions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                    child: _SuggestionTile(
                      icon: suggestion.$1,
                      label: suggestion.$2,
                      onTap: () => onSuggestion(suggestion.$2),
                    ),
                  ),
                const SizedBox(height: AppSpacing.x2),
                AppNote(
                  message: l10n.aiPrivacyNote,
                  icon: Icons.lock_outline_rounded,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appColors.card,
      borderRadius: AppRadius.medium,
      child: InkWell(
        borderRadius: AppRadius.medium,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x3,
            vertical: AppSpacing.x3,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.medium,
            border: Border.all(
              color: context.scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: AppIconSizes.sm, color: context.scheme.primary),
              const SizedBox(width: AppSpacing.x3),
              Expanded(child: Text(label, style: context.texts.bodyMedium)),
              Icon(
                Icons.north_east_rounded,
                size: AppIconSizes.xs,
                color: context.scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
