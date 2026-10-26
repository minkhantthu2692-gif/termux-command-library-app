import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../remote/firebase_errors.dart';

/// Abstraction over the Android bridge so command execution can be faked in
/// tests and the UI never depends on MethodChannel details.
abstract interface class TermuxService {
  bool get isSupported;

  Future<bool> isTermuxInstalled();

  Future<bool> isTermuxApiInstalled();

  Future<bool> hasRunCommandPermission();

  Future<bool> requestRunCommandPermission();

  Future<void> openTermux();

  Future<bool> openTermuxAppInfo();

  Future<void> openAppSettings();

  Future<int> runCommands(
    List<String> commands, {
    bool background = false,
    String? label,
  });

  Future<void> restartApp();
}

class PlatformTermuxService implements TermuxService {
  PlatformTermuxService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AppConstants.nativeChannel);

  final MethodChannel _channel;

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<bool> isTermuxInstalled() => _invokeBool('isTermuxInstalled');

  @override
  Future<bool> isTermuxApiInstalled() => _invokeBool('isTermuxApiInstalled');

  @override
  Future<bool> hasRunCommandPermission() =>
      _invokeBool('hasRunCommandPermission');

  @override
  Future<bool> requestRunCommandPermission() async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>(
        'requestRunCommandPermission',
      );
      return result ?? false;
    } on PlatformException catch (error) {
      throw mapPlatformError(error);
    } on MissingPluginException {
      throw const AppException(AppErrorCode.unsupported);
    }
  }

  @override
  Future<void> openTermux() async {
    await _invoke('openTermux');
  }

  @override
  Future<bool> openTermuxAppInfo() => _invokeBool('openTermuxSettings');

  @override
  Future<void> openAppSettings() async {
    await _invoke('openAppSettings');
  }

  @override
  Future<int> runCommands(
    List<String> commands, {
    bool background = false,
    String? label,
  }) async {
    if (!isSupported) {
      throw const AppException(AppErrorCode.unsupported);
    }
    if (commands.isEmpty) return 0;
    var sent = 0;
    for (final command in commands) {
      try {
        await _channel.invokeMethod<bool>('runTermuxCommand', {
          'command': command,
          'background': background,
          'label': label ?? 'Termux Command Library',
        });
        sent++;
      } on PlatformException catch (error) {
        throw mapPlatformError(error);
      } on MissingPluginException {
        throw const AppException(AppErrorCode.unsupported);
      }
      // Termux needs a moment to create/switch sessions between intents.
      if (commands.length > 1 && sent < commands.length) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
    }
    return sent;
  }

  @override
  Future<void> restartApp() async {
    await _invoke('restartApp');
  }

  Future<bool> _invokeBool(String method) async {
    if (!isSupported) return false;
    try {
      final result = await _channel.invokeMethod<bool>(method);
      return result ?? false;
    } on PlatformException catch (error) {
      throw mapPlatformError(error);
    } on MissingPluginException {
      return false;
    }
  }

  Future<void> _invoke(String method) async {
    if (!isSupported) {
      throw const AppException(AppErrorCode.unsupported);
    }
    try {
      await _channel.invokeMethod<bool>(method);
    } on PlatformException catch (error) {
      throw mapPlatformError(error);
    } on MissingPluginException {
      throw const AppException(AppErrorCode.unsupported);
    }
  }
}
