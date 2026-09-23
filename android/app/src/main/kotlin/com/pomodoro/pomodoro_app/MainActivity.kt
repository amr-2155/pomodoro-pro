package com.pomodoro.pomodoro_app

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.pomodoro.vibration"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vm = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as VibratorManager
            vm.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "vibrate" -> {
                        val duration = call.argument<Int>("duration") ?: 500
                        val amplitude = call.argument<Int>("amplitude") ?: 255
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val effect = VibrationEffect.createOneShot(
                                duration.toLong(),
                                amplitude.coerceIn(1, 255)
                            )
                            vibrator.vibrate(effect)
                        } else {
                            @Suppress("DEPRECATION")
                            vibrator.vibrate(duration.toLong())
                        }
                        result.success(true)
                    }
                    "pattern" -> {
                        val timings = call.argument<List<Int>>("timings")
                        val amplitudes = call.argument<List<Int>>("amplitudes")
                        if (timings != null) {
                            val timingsLong = timings.map { it.toLong() }.toLongArray()
                            val amps = amplitudes?.map { it.coerceIn(0, 255) }?.toIntArray()
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                val effect = if (amps != null && amps.size == timingsLong.size) {
                                    VibrationEffect.createWaveform(timingsLong, amps, -1)
                                } else {
                                    VibrationEffect.createWaveform(timingsLong, -1)
                                }
                                vibrator.vibrate(effect)
                            } else {
                                @Suppress("DEPRECATION")
                                vibrator.vibrate(timingsLong, -1)
                            }
                        }
                        result.success(true)
                    }
                    "cancel" -> {
                        vibrator.cancel()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
