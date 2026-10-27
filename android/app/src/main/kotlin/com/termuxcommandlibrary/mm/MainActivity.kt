package com.termuxcommandlibrary.mm

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Bridges the small, Android-specific surface the Flutter app needs:
 *  - Termux installation / RUN_COMMAND permission detection
 *  - Sending a command through Termux's documented RUN_COMMAND intent
 *  - Opening Android settings and restarting the activity
 *
 * The app intentionally does not embed a terminal emulator. Termux remains
 * responsible for running commands and displaying their output.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "dev.termuxlibrary/native"
    private val hapticsChannelName = "dev.termuxlibrary/haptics"
    private val requestRunCommandPermissionCode = 7101
    private val termuxPackage = "com.termux"
    private val termuxRunPermission = "com.termux.permission.RUN_COMMAND"
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val haptics = HapticsController(this)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, hapticsChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "perform" -> {
                        val timings = call.argument<List<Int>>("timings")
                            ?.map { it.toLong() }
                            ?.toLongArray()
                        val amplitudes = call.argument<List<Int>>("amplitudes")?.toIntArray()
                        if (
                            timings == null ||
                            timings.isEmpty() ||
                            amplitudes == null ||
                            amplitudes.size != timings.size
                        ) {
                            result.error(
                                "invalid_haptic_pattern",
                                "The haptic pattern is invalid.",
                                null,
                            )
                            return@setMethodCallHandler
                        }
                        haptics.perform(timings, amplitudes)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isTermuxInstalled" -> result.success(isPackageInstalled(termuxPackage))
                    "isTermuxApiInstalled" -> result.success(isPackageInstalled("com.termux.api"))
                    "hasRunCommandPermission" -> result.success(hasRunCommandPermission())
                    "requestRunCommandPermission" -> requestRunCommandPermission(result)
                    "runTermuxCommand" -> {
                        val command = call.argument<String>("command")
                        val background = call.argument<Boolean>("background") ?: false
                        val label = call.argument<String>("label")
                        if (command.isNullOrBlank()) {
                            result.error("invalid_command", "The command is empty.", null)
                            return@setMethodCallHandler
                        }
                        runTermuxCommand(command, background, label, result)
                    }
                    "openTermux" -> {
                        val launchIntent = packageManager.getLaunchIntentForPackage(termuxPackage)
                        if (launchIntent == null) {
                            result.error("termux_missing", "Termux is not installed.", null)
                        } else {
                            launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launchIntent)
                            result.success(true)
                        }
                    }
                    "openAppSettings" -> {
                        val intent = Intent(
                            android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            Uri.fromParts("package", packageName, null),
                        )
                        startActivity(intent)
                        result.success(true)
                    }
                    "openTermuxSettings" -> {
                        openTermuxAppInfo(result)
                    }
                    "restartApp" -> {
                        val intent = Intent(this, MainActivity::class.java)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
                        startActivity(intent)
                        finish()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun hasRunCommandPermission(): Boolean {
        return ContextCompat.checkSelfPermission(this, termuxRunPermission) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun requestRunCommandPermission(result: MethodChannel.Result) {
        if (!isPackageInstalled(termuxPackage)) {
            result.success(false)
            return
        }
        if (hasRunCommandPermission()) {
            result.success(true)
            return
        }
        if (pendingPermissionResult != null) {
            result.error("request_in_progress", "A permission request is already in progress.", null)
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            arrayOf(termuxRunPermission),
            requestRunCommandPermissionCode,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == requestRunCommandPermissionCode) {
            val granted = grantResults.isNotEmpty() &&
                grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingPermissionResult?.success(granted)
            pendingPermissionResult = null
        }
    }

    private fun runTermuxCommand(
        command: String,
        background: Boolean,
        label: String?,
        result: MethodChannel.Result,
    ) {
        if (!isPackageInstalled(termuxPackage)) {
            result.error("termux_missing", "Termux is not installed.", null)
            return
        }
        if (!hasRunCommandPermission()) {
            result.error("permission_missing", "RUN_COMMAND permission has not been granted.", null)
            return
        }

        try {
            val intent = Intent().apply {
                setClassName(termuxPackage, "com.termux.app.RunCommandService")
                action = "com.termux.RUN_COMMAND"
                putExtra(
                    "com.termux.RUN_COMMAND_PATH",
                    "/data/data/com.termux/files/usr/bin/bash",
                )
                putExtra("com.termux.RUN_COMMAND_ARGUMENTS", arrayOf("-c", command))
                putExtra(
                    "com.termux.RUN_COMMAND_WORKDIR",
                    "/data/data/com.termux/files/home",
                )
                putExtra("com.termux.RUN_COMMAND_BACKGROUND", background)
                // 0 = create/switch to a new terminal session and open Termux.
                putExtra("com.termux.RUN_COMMAND_SESSION_ACTION", "0")
                putExtra(
                    "com.termux.RUN_COMMAND_COMMAND_LABEL",
                    label ?: "Termux Command Library command",
                )
                putExtra(
                    "com.termux.RUN_COMMAND_COMMAND_DESCRIPTION",
                    "Command sent from Termux Command Library",
                )
            }
            startService(intent)
            // The service accepted the intent. Termux still runs the command,
            // and this app cannot confirm command completion without a result
            // pending intent. The UI therefore reports "sent", not "finished".
            result.success(true)
        } catch (error: SecurityException) {
            result.error("permission_missing", error.localizedMessage, null)
        } catch (error: Exception) {
            result.error("termux_error", error.localizedMessage, null)
        }
    }

    private fun openTermuxAppInfo(result: MethodChannel.Result) {
        if (!isPackageInstalled(termuxPackage)) {
            result.success(false)
            return
        }
        val intent = Intent(android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
            .setData(Uri.fromParts("package", termuxPackage, null))
        startActivity(intent)
        result.success(true)
    }
}
