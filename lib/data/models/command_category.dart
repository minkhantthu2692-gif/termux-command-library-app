/// Stable category identifiers. Display names live in localization resources so
/// the same IDs work for English and Myanmar, and remain valid if a translation
/// changes.
class CommandCategory {
  const CommandCategory({required this.id, required this.titleKey});

  final String id;

  /// Key from the generated localization class, e.g. `categoryPackage`.
  final String titleKey;
}

abstract final class CommandCategories {
  static const packageManagement = CommandCategory(
    id: 'package_management',
    titleKey: 'categoryPackage',
  );
  static const linuxDistributions = CommandCategory(
    id: 'linux_distributions',
    titleKey: 'categoryLinux',
  );
  static const shellScripting = CommandCategory(
    id: 'shell_scripting',
    titleKey: 'categoryShell',
  );
  static const fileStorage = CommandCategory(
    id: 'file_storage',
    titleKey: 'categoryFiles',
  );
  static const gitVersionControl = CommandCategory(
    id: 'git_version_control',
    titleKey: 'categoryGit',
  );
  static const programmingDevelopment = CommandCategory(
    id: 'programming_development',
    titleKey: 'categoryProgramming',
  );
  static const networkingRemote = CommandCategory(
    id: 'networking_remote',
    titleKey: 'categoryNetworking',
  );
  static const systemProcess = CommandCategory(
    id: 'system_process',
    titleKey: 'categorySystem',
  );
  static const termuxApiDevice = CommandCategory(
    id: 'termux_api_device',
    titleKey: 'categoryTermuxApi',
  );
  static const securityTesting = CommandCategory(
    id: 'security_testing',
    titleKey: 'categorySecurity',
  );

  static const all = <CommandCategory>[
    packageManagement,
    linuxDistributions,
    shellScripting,
    fileStorage,
    gitVersionControl,
    programmingDevelopment,
    networkingRemote,
    systemProcess,
    termuxApiDevice,
    securityTesting,
  ];

  static const ids = <String>{
    'package_management',
    'linux_distributions',
    'shell_scripting',
    'file_storage',
    'git_version_control',
    'programming_development',
    'networking_remote',
    'system_process',
    'termux_api_device',
    'security_testing',
  };

  static CommandCategory? byId(String? id) {
    if (id == null) return null;
    for (final category in all) {
      if (category.id == id) return category;
    }
    return null;
  }

  static bool isValid(String id) => ids.contains(id);
}
