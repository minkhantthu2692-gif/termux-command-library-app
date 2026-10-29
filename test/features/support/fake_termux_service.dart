import 'package:termux_command_library/data/services/termux_service.dart';

/// Configurable Termux bridge for widget tests. No Android APIs are touched.
class FakeTermuxService implements TermuxService {
  FakeTermuxService({
    this.installed = true,
    this.apiInstalled = true,
    this.overlay = true,
    this.permission = true,
  });

  bool installed;
  bool apiInstalled;
  bool overlay;
  bool permission;
  int apiSettingsOpened = 0;
  int appSettingsOpened = 0;
  int overlaySettingsOpened = 0;
  final List<String> sent = <String>[];
  final List<bool> sentInBackground = <bool>[];
  final List<bool> sentKeepOpen = <bool>[];

  @override
  bool get isSupported => true;

  @override
  Future<bool> isTermuxInstalled() async => installed;

  @override
  Future<bool> isTermuxApiInstalled() async => apiInstalled;

  @override
  Future<bool> canTermuxDrawOverlays() async => overlay;

  @override
  Future<bool> hasRunCommandPermission() async => permission;

  @override
  Future<bool> requestRunCommandPermission() async => permission;

  @override
  Future<void> openTermux() async {}

  @override
  Future<bool> openTermuxAppInfo() async => installed;

  @override
  Future<bool> openTermuxApiAppInfo() async {
    apiSettingsOpened++;
    return apiInstalled;
  }

  @override
  Future<bool> openTermuxOverlaySettings() async {
    overlaySettingsOpened++;
    return installed;
  }

  @override
  Future<void> openAppSettings() async {
    appSettingsOpened++;
  }

  @override
  Future<int> runCommands(
    List<String> commands, {
    bool background = false,
    bool keepOpen = false,
    String keepOpenHint = 'Command finished. Press Enter to close.',
    String? label,
  }) async {
    sent.addAll(commands);
    sentInBackground.addAll(commands.map((_) => background));
    sentKeepOpen.addAll(commands.map((_) => keepOpen));
    return commands.length;
  }

  @override
  Future<void> restartApp() async {}
}
