import 'package:flutter/material.dart';

import '../../app/localization/generated/app_localizations.dart';
import '../../data/models/command_category.dart';

String categoryLabel(AppLocalizations l10n, String? categoryId) {
  return switch (categoryId) {
    'linux_distributions' => l10n.categoryLinux,
    'shell_scripting' => l10n.categoryShell,
    'file_storage' => l10n.categoryFiles,
    'git_version_control' => l10n.categoryGit,
    'programming_development' => l10n.categoryProgramming,
    'networking_remote' => l10n.categoryNetworking,
    'system_process' => l10n.categorySystem,
    'termux_api_device' => l10n.categoryTermuxApi,
    'security_testing' => l10n.categorySecurity,
    _ => l10n.categoryPackage,
  };
}

/// Visual identity for each command category. Kept separate from the data model
/// so icons/colors can change without touching stored category IDs.
class CategoryVisual {
  const CategoryVisual({
    required this.icon,
    required this.color,
    required this.descriptionKey,
  });

  final IconData icon;
  final Color color;
  final String descriptionKey;

  static CategoryVisual of(String? categoryId) {
    return switch (categoryId) {
      'linux_distributions' => const CategoryVisual(
        icon: Icons.dns_rounded,
        color: Color(0xFF5B6BC0),
        descriptionKey: 'categoryLinuxDescription',
      ),
      'shell_scripting' => const CategoryVisual(
        icon: Icons.code_rounded,
        color: Color(0xFF0E8576),
        descriptionKey: 'categoryShellDescription',
      ),
      'file_storage' => const CategoryVisual(
        icon: Icons.folder_copy_rounded,
        color: Color(0xFFB27815),
        descriptionKey: 'categoryFilesDescription',
      ),
      'git_version_control' => const CategoryVisual(
        icon: Icons.account_tree_rounded,
        color: Color(0xFFC2563F),
        descriptionKey: 'categoryGitDescription',
      ),
      'programming_development' => const CategoryVisual(
        icon: Icons.terminal_rounded,
        color: Color(0xFF7651C9),
        descriptionKey: 'categoryProgrammingDescription',
      ),
      'networking_remote' => const CategoryVisual(
        icon: Icons.lan_rounded,
        color: Color(0xFF2B6CA3),
        descriptionKey: 'categoryNetworkingDescription',
      ),
      'system_process' => const CategoryVisual(
        icon: Icons.memory_rounded,
        color: Color(0xFF626B7D),
        descriptionKey: 'categorySystemDescription',
      ),
      'termux_api_device' => const CategoryVisual(
        icon: Icons.phone_android_rounded,
        color: Color(0xFF2D7D5B),
        descriptionKey: 'categoryTermuxApiDescription',
      ),
      'security_testing' => const CategoryVisual(
        icon: Icons.shield_outlined,
        color: Color(0xFF9A6700),
        descriptionKey: 'categorySecurityDescription',
      ),
      _ => const CategoryVisual(
        icon: Icons.inventory_2_rounded,
        color: Color(0xFF4F5BD5),
        descriptionKey: 'categoryPackageDescription',
      ),
    };
  }

  static IconData iconFor(CommandCategory? category) => of(category?.id).icon;
}
