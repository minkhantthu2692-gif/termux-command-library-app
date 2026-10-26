import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import 'command_category.dart';

enum CommandStatus {
  published,
  draft,
  archived;

  static CommandStatus parse(String? value) => switch (value) {
    'draft' => CommandStatus.draft,
    'archived' => CommandStatus.archived,
    _ => CommandStatus.published,
  };
}

enum CommandRunMode {
  foreground,
  background;

  static CommandRunMode parse(String? value) => value == 'background'
      ? CommandRunMode.background
      : CommandRunMode.foreground;
}

class CommandStep {
  const CommandStep({
    required this.id,
    required this.order,
    required this.title,
    required this.command,
    this.description = '',
    this.runMode = CommandRunMode.foreground,
  });

  final String id;
  final int order;
  final String title;
  final String description;

  /// Stored and copied exactly as the user entered it. Never trim or rewrite.
  final String command;
  final CommandRunMode runMode;

  CommandStep copyWith({
    String? id,
    int? order,
    String? title,
    String? description,
    String? command,
    CommandRunMode? runMode,
  }) => CommandStep(
    id: id ?? this.id,
    order: order ?? this.order,
    title: title ?? this.title,
    description: description ?? this.description,
    command: command ?? this.command,
    runMode: runMode ?? this.runMode,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'title': title,
    'description': description,
    'command': command,
    'runMode': runMode.name,
  };

  factory CommandStep.fromJson(
    Map<String, dynamic> json, {
    int? fallbackOrder,
  }) {
    return CommandStep(
      id: (json['id'] as String?) ?? 'step-${fallbackOrder ?? 0}',
      order: (json['order'] as num?)?.toInt() ?? fallbackOrder ?? 0,
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      command: (json['command'] as String?) ?? '',
      runMode: CommandRunMode.parse(json['runMode'] as String?),
    );
  }

  static List<CommandStep> sorted(Iterable<CommandStep> steps) {
    final result = steps.toList()..sort((a, b) => a.order.compareTo(b.order));
    return List.unmodifiable(result);
  }
}

class CommandPost {
  const CommandPost({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.steps,
    required this.authorUid,
    required this.createdAt,
    required this.updatedAt,
    this.tags = const [],
    this.metadata = const {},
    this.authorNickname = '',
    this.version = 1,
    this.status = CommandStatus.published,
    this.isSeed = false,
    this.isPendingSync = false,
  });

  final String id;
  final String name;
  final String description;
  final String categoryId;
  final List<String> tags;
  final Map<String, String> metadata;
  final List<CommandStep> steps;
  final String authorUid;
  final String authorNickname;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final CommandStatus status;

  /// Seeded offline content. It is not owned by a user and cannot be edited by
  /// normal users.
  final bool isSeed;

  /// A local change that has not yet been acknowledged by Firestore.
  final bool isPendingSync;

  int get stepCount => steps.length;
  bool get isDraft => status == CommandStatus.draft;

  String get allCommands => steps.map((step) => step.command).join('\n\n');

  CommandCategory? get category => CommandCategories.byId(categoryId);

  String get searchableText {
    final buffer = StringBuffer()
      ..writeln(name)
      ..writeln(description)
      ..writeln(categoryId)
      ..writeln(tags.join(' '))
      ..writeln(metadata.entries.map((e) => '${e.key} ${e.value}').join(' '));
    for (final step in steps) {
      buffer
        ..writeln(step.title)
        ..writeln(step.description)
        ..writeln(step.command);
    }
    return buffer.toString().toLowerCase();
  }

  CommandPost copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    List<String>? tags,
    Map<String, String>? metadata,
    List<CommandStep>? steps,
    String? authorUid,
    String? authorNickname,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    CommandStatus? status,
    bool? isSeed,
    bool? isPendingSync,
  }) => CommandPost(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    categoryId: categoryId ?? this.categoryId,
    tags: tags ?? this.tags,
    metadata: metadata ?? this.metadata,
    steps: steps == null ? this.steps : CommandStep.sorted(steps),
    authorUid: authorUid ?? this.authorUid,
    authorNickname: authorNickname ?? this.authorNickname,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    status: status ?? this.status,
    isSeed: isSeed ?? this.isSeed,
    isPendingSync: isPendingSync ?? this.isPendingSync,
  );

  /// Firestore representation. Timestamps are converted by the gateway so this
  /// model stays independent of the Firebase SDK.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'categoryId': categoryId,
    'tags': tags,
    'metadata': metadata,
    'steps': steps.map((step) => step.toJson()).toList(),
    'authorUid': authorUid,
    'authorNickname': authorNickname,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
    'version': version,
    'status': status.name,
  };

  /// Used by the built-in offline seed catalogue.
  factory CommandPost.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException('A command post must have a non-empty id.');
    }
    final rawSteps = (json['steps'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((step) => CommandStep.fromJson(Map<String, dynamic>.from(step)))
        .toList();
    final steps = CommandStep.sorted(rawSteps);
    final now = DateTime.now().toUtc();
    return CommandPost(
      id: id,
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      categoryId:
          (json['categoryId'] as String?) ??
          CommandCategories.packageManagement.id,
      tags: Validators.normalizeTags(
        (json['tags'] as List<dynamic>? ?? const []).whereType<String>(),
      ),
      metadata: (json['metadata'] as Map<dynamic, dynamic>? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
      steps: steps,
      authorUid: (json['authorUid'] as String?) ?? AppConstants.seedAuthorUid,
      authorNickname:
          (json['authorNickname'] as String?) ?? AppConstants.seedAuthorName,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
      version: (json['version'] as num?)?.toInt() ?? 1,
      status: CommandStatus.parse(json['status'] as String?),
      isSeed: true,
    );
  }
}

/// Lightweight projection used by list screens. Steps are intentionally not
/// loaded until the details screen needs them.
class CommandSummary {
  const CommandSummary({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.tags,
    required this.metadata,
    required this.authorUid,
    required this.authorNickname,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    required this.status,
    required this.stepCount,
    this.isSeed = false,
    this.isPendingSync = false,
  });

  final String id;
  final String name;
  final String description;
  final String categoryId;
  final List<String> tags;
  final Map<String, String> metadata;
  final String authorUid;
  final String authorNickname;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final CommandStatus status;
  final int stepCount;
  final bool isSeed;
  final bool isPendingSync;

  CommandCategory? get category => CommandCategories.byId(categoryId);
}
