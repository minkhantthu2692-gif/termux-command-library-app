package com.termuxcommandlibrary.mm

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager

/**
 * Amplitude-aware haptics for the app's semantic cues.
 *
 * Flutter's HapticFeedback constants are mapped by each OEM and often feel
 * identical. Receiving an explicit waveform lets Light/Medium/Strong change
 * both duration and strength. Devices without amplitude control still get the
 * duration differences. All calls are best-effort and never fail the action.
 */
class HapticsController(context: Context) {
    private val vibrator: Vibrator? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        val manager =
            context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
        manager?.defaultVibrator
    } else {
        @Suppress("DEPRECATION")
        context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
    }

    fun perform(timings: LongArray, amplitudes: IntArray) {
        val device = vibrator ?: return
        if (timings.isEmpty() || !device.hasVibrator()) return
        try {
            // Rapid slider ticks should replace the previous tick instead of
            // queueing behind it.
            device.cancel()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val effect = if (
                    device.hasAmplitudeControl() &&
                    amplitudes.size == timings.size
                ) {
                    VibrationEffect.createWaveform(
                        timings,
                        IntArray(amplitudes.size) { amplitudes[it].coerceIn(0, 255) },
                        -1,
                    )
                } else {
                    VibrationEffect.createWaveform(timings, -1)
                }
                device.vibrate(effect)
            } else {
                // API 24-25 has no amplitude control. Preserve the total "on"
                // duration so Light and Strong still differ.
                var duration = 0L
                for (index in timings.indices step 2) {
                    if (index + 1 < timings.size) duration += timings[index + 1]
                }
                @Suppress("DEPRECATION")
                device.vibrate(duration)
            }
        } catch (_: Exception) {
            // Haptics are optional; a device or OS restriction is not an error.
        }
    }
}
