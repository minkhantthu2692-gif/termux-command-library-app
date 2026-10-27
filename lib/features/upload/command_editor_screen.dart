import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/design_system/app_tokens.dart';
import '../../core/utils/validators.dart';
import '../../data/models/command_category.dart';
import '../../data/models/command_post.dart';
import '../../data/services/haptics_service.dart';
import '../../shared/utils/category_visual.dart';
import '../../shared/utils/error_messages.dart';
import '../../shared/utils/ui_actions.dart';
import '../../shared/widgets/app_note.dart';
import '../../shared/widgets/app_page.dart';
import '../../shared/widgets/command_code_block.dart';
import '../../shared/widgets/section_header.dart';
import 'ai_assist_sheet.dart';

class CommandEditorScreen extends ConsumerStatefulWidget {
  const CommandEditorScreen({super.key, this.commandId});

  final String? commandId;

  bool get isEditing => commandId != null;

  @override
  ConsumerState<CommandEditorScreen> createState() =>
      _CommandEditorScreenState();
}

class _StepEditor {
  _StepEditor({
    required String id,
    String title = '',
    String description = '',
    String command = '',
    CommandRunMode runMode = CommandRunMode.foreground,
  }) : id = id,
       title = TextEditingController(text: title),
       description = TextEditingController(text: description),
       command = TextEditingController(text: command),
       runMode = runMode;

  final String id;
  final TextEditingController title;
  final TextEditingController description;
  final TextEditingController command;
  CommandRunMode runMode;

  void dispose() {
    title.dispose();
    description.dispose();
    command.dispose();
  }
}

class _MetadataEditor {
  _MetadataEditor({String key = '', String value = ''})
    : key = TextEditingController(text: key),
      value = TextEditingController(text: value);

  final TextEditingController key;
  final TextEditingController value;

  void dispose() {
    key.dispose();
    value.dispose();
  }
}

class _CommandEditorScreenState extends ConsumerState<CommandEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _tags = TextEditingController();
  final List<_StepEditor> _steps = [];
  final List<_MetadataEditor> _metadata = [];
  String _categoryId = CommandCategories.packageManagement.id;
  CommandPost? _existing;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _allowed = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExisting();
    } else {
      _steps.add(_StepEditor(id: const Uuid().v4()));
      _loading = false;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _tags.dispose();
    for (final step in _steps) {
      step.dispose();
    }
    for (final entry in _metadata) {
      entry.dispose();
    }
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final command = await ref
          .read(commandRepositoryProvider)
          .getCommand(widget.commandId!);
      if (!mounted) return;
      if (command == null) {
        setState(() {
          _loading = false;
          _loadError = AppLocalizations.of(context).guideNotAvailable;
        });
        return;
      }
      final session = ref.read(currentSessionProvider);
      final canEdit =
          !command.isSeed &&
          (session.isAdmin || session.uid == command.authorUid);
      if (!canEdit) {
        setState(() {
          _loading = false;
          _allowed = false;
        });
        return;
      }
      setState(() {
        _existing = command;
        _name.text = command.name;
        _description.text = command.description;
        _tags.text = command.tags.join(', ');
        _categoryId = command.categoryId;
        for (final step in command.steps) {
          _steps.add(
            _StepEditor(
              id: step.id,
              title: step.title,
              description: step.description,
              command: step.command,
              runMode: step.runMode,
            ),
          );
        }
        for (final entry in command.metadata.entries) {
          _metadata.add(_MetadataEditor(key: entry.key, value: entry.value));
        }
        if (_steps.isEmpty) _steps.add(_StepEditor(id: const Uuid().v4()));
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = localizeError(AppLocalizations.of(context), error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = widget.isEditing ? l10n.editCommand : l10n.newCommand;
    if (_loading) {
      return AppMessageScaffold(
        title: title,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_loadError != null) {
      return AppMessageScaffold(
        title: title,
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: l10n.guideNotAvailable,
          body: _loadError!,
        ),
      );
    }
    if (!_allowed) {
      return AppMessageScaffold(
        title: title,
        child: EmptyState(
          icon: Icons.lock_outline_rounded,
          title: l10n.noPermission,
          body: l10n.ownerOnly,
        ),
      );
    }

    final session = ref.watch(currentSessionProvider);
    final cloudConfigured = ref.watch(
      appDependenciesProvider.select((deps) => deps.cloudConfigured),
    );
    final canSave = cloudConfigured && session.canPublish;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_dirty) return;
        final discard = await _confirmDiscard();
        if (discard && context.mounted) {
          setState(() => _dirty = false);
          Navigator.of(context).pop();
        }
      },
      child: AppPage(
        title: title,
        scrollable: false,
        padding: EdgeInsets.zero,
        actions: [
          IconButton(
            tooltip: l10n.preview,
            onPressed: _openPreview,
            icon: const Icon(Icons.visibility_outlined),
          ),
          IconButton(
            tooltip: l10n.aiAssist,
            onPressed: canSave ? _openAiAssist : null,
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
        ],
        bottomNavigationBar: _BottomBar(
          saving: _saving,
          canSave: canSave,
          onSaveDraft: () => _save(publish: false),
          onPublish: () => _save(publish: true),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x5,
              AppSpacing.x2,
              AppSpacing.x5,
              AppSpacing.x10,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppSizes.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!cloudConfigured)
                      AppNote(
                        title: l10n.cloudUnavailableTitle,
                        message: l10n.cloudUnavailableBody,
                        tone: AppNoteTone.warning,
                      )
                    else if (!session.canPublish)
                      AppNote(
                        title: l10n.guestCannotPublish,
                        message: l10n.createAccountToPublish,
                        tone: AppNoteTone.info,
                        actionLabel: l10n.signIn,
                        onAction: () =>
                            context.push('/auth/register?next=%2Fupload'),
                      )
                    else
                      AppNote(
                        message: l10n.publishRulesBody,
                        icon: Icons.verified_user_outlined,
                      ),
                    const SizedBox(height: AppSpacing.x5),
                    SectionHeader(title: l10n.basics),
                    const SizedBox(height: AppSpacing.x3),
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: AppConstants.maxCommandNameLength,
                      decoration: InputDecoration(
                        labelText: l10n.commandName,
                        hintText: l10n.commandNameHint,
                        prefixIcon: const Icon(Icons.terminal_rounded),
                      ),
                      validator: (value) =>
                          localizeValidation(l10n, Validators.nameError(value)),
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    TextFormField(
                      controller: _description,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: AppConstants.maxDescriptionLength,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.description,
                        hintText: l10n.descriptionHint,
                        alignLabelWithHint: true,
                      ),
                      validator: (value) => localizeValidation(
                        l10n,
                        Validators.descriptionError(value),
                      ),
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      decoration: InputDecoration(
                        labelText: l10n.category,
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                      items: [
                        for (final category in CommandCategories.all)
                          DropdownMenuItem(
                            value: category.id,
                            child: Row(
                              children: [
                                Icon(
                                  CategoryVisual.of(category.id).icon,
                                  size: AppIconSizes.sm,
                                  color: CategoryVisual.of(category.id).color,
                                ),
                                const SizedBox(width: AppSpacing.x2),
                                Text(categoryLabel(l10n, category.id)),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        unawaited(triggerHaptic(ref, cue: HapticCue.selection));
                        setState(() => _categoryId = value);
                        _markDirty();
                      },
                    ),
                    const SizedBox(height: AppSpacing.x4),
                    TextFormField(
                      controller: _tags,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.tags,
                        hintText: l10n.tagsHint,
                        helperText: l10n.tagsHelper,
                        prefixIcon: const Icon(Icons.tag_rounded),
                      ),
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: AppSpacing.x6),
                    SectionHeader(
                      title: l10n.stepsTitle,
                      subtitle: l10n.stepsHelper,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    for (var index = 0; index < _steps.length; index++) ...[
                      _StepEditorCard(
                        key: ValueKey(_steps[index].id),
                        index: index,
                        step: _steps[index],
                        canMoveUp: index > 0,
                        canMoveDown: index < _steps.length - 1,
                        canRemove: _steps.length > 1,
                        onMoveUp: () => _moveStep(index, index - 1),
                        onMoveDown: () => _moveStep(index, index + 1),
                        onRemove: () => _removeStep(index),
                        onRunModeChanged: (mode) {
                          unawaited(
                            triggerHaptic(ref, cue: HapticCue.selection),
                          );
                          setState(() => _steps[index].runMode = mode);
                          _markDirty();
                        },
                        onChanged: _markDirty,
                        l10n: l10n,
                      ),
                      const SizedBox(height: AppSpacing.x3),
                    ],
                    OutlinedButton.icon(
                      onPressed: _addStep,
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.addStep),
                    ),
                    const SizedBox(height: AppSpacing.x6),
                    SectionHeader(
                      title: l10n.metadata,
                      subtitle: l10n.metadataHint,
                      actionLabel: l10n.addMetadata,
                      onAction: _addMetadata,
                    ),
                    const SizedBox(height: AppSpacing.x3),
                    if (_metadata.isEmpty)
                      Text(
                        l10n.metadataHint,
                        style: context.texts.bodySmall?.copyWith(
                          color: context.scheme.onSurfaceVariant,
                        ),
                      )
                    else
                      for (var index = 0; index < _metadata.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.x2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 4,
                                child: TextFormField(
                                  controller: _metadata[index].key,
                                  decoration: InputDecoration(
                                    labelText: l10n.metadataKey,
                                  ),
                                  onChanged: (_) => _markDirty(),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.x2),
                              Expanded(
                                flex: 6,
                                child: TextFormField(
                                  controller: _metadata[index].value,
                                  decoration: InputDecoration(
                                    labelText: l10n.metadataValue,
                                  ),
                                  onChanged: (_) => _markDirty(),
                                ),
                              ),
                              IconButton(
                                tooltip: l10n.removeMetadata,
                                onPressed: () => _removeMetadata(index),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _addStep() {
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    setState(() => _steps.add(_StepEditor(id: const Uuid().v4())));
    _markDirty();
  }

  void _removeStep(int index) {
    unawaited(triggerHaptic(ref, cue: HapticCue.warning));
    final step = _steps.removeAt(index);
    step.dispose();
    setState(() {});
    _markDirty();
  }

  void _moveStep(int from, int to) {
    if (to < 0 || to >= _steps.length) return;
    unawaited(triggerHaptic(ref, cue: HapticCue.selection));
    setState(() {
      final step = _steps.removeAt(from);
      _steps.insert(to, step);
    });
    _markDirty();
  }

  void _addMetadata() {
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    setState(() => _metadata.add(_MetadataEditor()));
    _markDirty();
  }

  void _removeMetadata(int index) {
    unawaited(triggerHaptic(ref, cue: HapticCue.warning));
    final entry = _metadata.removeAt(index);
    entry.dispose();
    setState(() {});
    _markDirty();
  }

  CommandPost _buildDraft() {
    final now = DateTime.now().toUtc();
    final session = ref.read(currentSessionProvider);
    final profile = ref.read(profileProvider).value;
    final steps = <CommandStep>[];
    for (var index = 0; index < _steps.length; index++) {
      final editor = _steps[index];
      steps.add(
        CommandStep(
          id: editor.id,
          order: index,
          title: editor.title.text.trim(),
          // Command text and step notes are stored as typed, without trimming.
          command: editor.command.text,
          description: editor.description.text,
          runMode: editor.runMode,
        ),
      );
    }
    final metadata = <String, String>{};
    for (final entry in _metadata) {
      final key = entry.key.text.trim();
      if (key.isEmpty) continue;
      metadata[key] = entry.value.text.trim();
    }
    return CommandPost(
      id: _existing?.id ?? const Uuid().v4(),
      name: _name.text,
      description: _description.text,
      categoryId: _categoryId,
      tags: Validators.normalizeTags(_tags.text.split(',')),
      metadata: metadata,
      steps: steps,
      authorUid: _existing?.authorUid ?? session.uid,
      authorNickname:
          profile?.effectiveNickname ?? _existing?.authorNickname ?? '',
      createdAt: _existing?.createdAt ?? now,
      updatedAt: now,
      version: _existing?.version ?? 1,
      status: _existing?.status ?? CommandStatus.draft,
    );
  }

  Future<void> _save({required bool publish}) async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    final session = ref.read(currentSessionProvider);
    if (!session.canPublish) {
      context.showSnack(l10n.guestCannotPublish);
      return;
    }
    final draft = _buildDraft();
    if (publish) {
      if (!(_formKey.currentState?.validate() ?? false)) return;
      if (draft.steps.isEmpty) {
        context.showSnack(l10n.atLeastOneStep);
        return;
      }
    } else if (draft.name.trim().isEmpty) {
      context.showSnack(l10n.commandNameRequired);
      return;
    }
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    setState(() => _saving = true);
    try {
      final saved = await ref
          .read(commandRepositoryProvider)
          .savePost(
            session: session,
            post: draft,
            publish: publish,
            authorNickname:
                ref.read(profileProvider).value?.effectiveNickname ?? '',
          );
      if (!mounted) return;
      unawaited(triggerHaptic(ref, cue: HapticCue.success));
      setState(() => _dirty = false);
      context.showSnack(publish ? l10n.published : l10n.draftSaved);
      if (widget.isEditing) {
        context.pop();
      } else {
        context.pushReplacement('/command/${saved.id}');
      }
    } catch (error) {
      if (mounted) context.showErrorSnack(error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    return showConfirmDialog(
      context,
      title: l10n.discardChangesTitle,
      message: l10n.discardChangesBody,
      confirmLabel: l10n.discard,
      cancelLabel: l10n.keepEditing,
      destructive: true,
    );
  }

  void _openPreview() {
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    final l10n = AppLocalizations.of(context);
    final draft = _buildDraft();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.94,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x5,
            0,
            AppSpacing.x5,
            AppSpacing.x6,
          ),
          children: [
            Text(
              draft.name.trim().isEmpty ? l10n.missingTitle : draft.name,
              style: context.texts.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              draft.description.trim().isEmpty
                  ? l10n.previewEmptySteps
                  : draft.description,
              style: context.texts.bodyMedium?.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.x5),
            if (draft.steps.every(
              (step) => step.command.trim().isEmpty && step.title.isEmpty,
            ))
              AppNote(message: l10n.previewEmptySteps)
            else
              for (final step in draft.steps) ...[
                Text(
                  '${step.order + 1}. ${step.title.trim().isEmpty ? l10n.newStep : step.title}',
                  style: context.texts.titleSmall,
                ),
                if (step.description.trim().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    step.description,
                    style: context.texts.bodySmall?.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (step.command.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x2),
                  CommandCodeBlock(
                    command: step.command,
                    dense: true,
                    label: l10n.stepNumber(step.order + 1),
                  ),
                ],
                const SizedBox(height: AppSpacing.x4),
              ],
          ],
        ),
      ),
    );
  }

  Future<void> _openAiAssist() async {
    unawaited(triggerHaptic(ref, cue: HapticCue.tap));
    final draft = _buildDraft();
    await showAiAssistSheet(
      context,
      ref,
      draft: draft,
      onApplyDescription: (value) {
        setState(() {
          _description.text = value;
          _dirty = true;
        });
        context.showSnack(AppLocalizations.of(context).aiAssistApplied);
      },
    );
  }
}

class _StepEditorCard extends StatelessWidget {
  const _StepEditorCard({
    super.key,
    required this.index,
    required this.step,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.canRemove,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onRunModeChanged,
    required this.onChanged,
    required this.l10n,
  });

  final int index;
  final _StepEditor step;
  final bool canMoveUp;
  final bool canMoveDown;
  final bool canRemove;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final ValueChanged<CommandRunMode> onRunModeChanged;
  final VoidCallback onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x4),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: AppRadius.large,
        border: Border.all(
          color: context.scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.scheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  '${index + 1}',
                  style: context.texts.labelSmall?.copyWith(
                    color: context.scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x2),
              Expanded(
                child: Text(
                  l10n.stepNumber(index + 1),
                  style: context.texts.titleSmall,
                ),
              ),
              IconButton(
                tooltip: l10n.moveUp,
                onPressed: canMoveUp ? onMoveUp : null,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
              IconButton(
                tooltip: l10n.moveDown,
                onPressed: canMoveDown ? onMoveDown : null,
                icon: const Icon(Icons.arrow_downward_rounded),
              ),
              if (canRemove)
                IconButton(
                  tooltip: l10n.removeStep,
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          TextFormField(
            controller: step.title,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            maxLength: AppConstants.maxStepTitleLength,
            decoration: InputDecoration(
              labelText: l10n.stepTitle,
              hintText: l10n.stepTitleHint,
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? l10n.stepTitleRequired
                : null,
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.x2),
          TextFormField(
            controller: step.description,
            minLines: 2,
            maxLines: 4,
            maxLength: AppConstants.maxStepDescriptionLength,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.stepDescription,
              hintText: l10n.stepDescriptionHint,
              alignLabelWithHint: true,
            ),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.x2),
          TextFormField(
            controller: step.command,
            minLines: 3,
            maxLines: 12,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            autocorrect: false,
            enableSuggestions: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            style: context.monoStyle,
            decoration: InputDecoration(
              labelText: l10n.stepCommand,
              hintText: l10n.stepCommandHint,
              alignLabelWithHint: true,
            ),
            validator: (value) =>
                localizeValidation(l10n, Validators.commandError(value)),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(l10n.runMode, style: context.texts.labelMedium),
          const SizedBox(height: AppSpacing.x2),
          SegmentedButton<CommandRunMode>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: CommandRunMode.foreground,
                icon: const Icon(Icons.open_in_new_rounded),
                label: Text(l10n.runModeForeground),
              ),
              ButtonSegment(
                value: CommandRunMode.background,
                icon: const Icon(Icons.layers_outlined),
                label: Text(l10n.runModeBackground),
              ),
            ],
            selected: {step.runMode},
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              onRunModeChanged(selection.first);
            },
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.saving,
    required this.canSave,
    required this.onSaveDraft,
    required this.onPublish,
  });

  final bool saving;
  final bool canSave;
  final VoidCallback onSaveDraft;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x5,
          AppSpacing.x3,
          AppSpacing.x5,
          AppSpacing.x3,
        ),
        decoration: BoxDecoration(
          color: context.appColors.glassTint,
          border: Border(
            top: BorderSide(
              color: context.scheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: saving || !canSave ? null : onSaveDraft,
                child: Text(l10n.saveDraft),
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: FilledButton(
                onPressed: saving || !canSave ? null : onPublish,
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.publish),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
