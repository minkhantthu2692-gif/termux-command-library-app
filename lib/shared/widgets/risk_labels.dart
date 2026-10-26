import '../../app/localization/generated/app_localizations.dart';
import '../../core/utils/command_risk.dart';

String riskReasonLabel(AppLocalizations l10n, CommandRiskReason reason) {
  return switch (reason) {
    CommandRiskReason.recursiveRootDelete => l10n.riskRecursiveRootDelete,
    CommandRiskReason.homeDelete => l10n.riskHomeDelete,
    CommandRiskReason.filesystemFormat => l10n.riskFilesystemFormat,
    CommandRiskReason.rawDiskWrite => l10n.riskRawDiskWrite,
    CommandRiskReason.systemPermissionChange => l10n.riskSystemPermissionChange,
    CommandRiskReason.forkBomb => l10n.riskForkBomb,
    CommandRiskReason.systemPower => l10n.riskSystemPower,
    CommandRiskReason.pipeDownloadToShell => l10n.riskPipeDownloadToShell,
    CommandRiskReason.destructiveGitClean => l10n.riskDestructiveGitClean,
    CommandRiskReason.packageRemoval => l10n.riskPackageRemoval,
    CommandRiskReason.privilegeEscalation => l10n.riskPrivilegeEscalation,
    CommandRiskReason.forceKill => l10n.riskForceKill,
  };
}
