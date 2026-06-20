package com.islamicaudiohub.islamic_audio_hub

import android.content.Context
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    private val channelName = "khaleek_momen/adhan_alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAdhanAlarms" -> {
                    try {
                        val alarms = call.argument<List<Map<String, Any?>>>("alarms") ?: emptyList()
                        NativeAdhanScheduler.scheduleAlarms(this, alarms)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error(
                            "SCHEDULE_ADHAN_ALARMS_FAILED",
                            e.message,
                            null
                        )
                    }
                }

                "cancelAdhanAlarms" -> {
                    try {
                        NativeAdhanScheduler.cancelAll(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error(
                            "CANCEL_ADHAN_ALARMS_FAILED",
                            e.message,
                            null
                        )
                    }
                }

                "canScheduleExactAlarms" -> {
                    try {
                        result.success(NativeAdhanScheduler.canScheduleExactAlarms(this))
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "openExactAlarmSettings" -> {
                    try {
                        NativeAdhanScheduler.openExactAlarmSettings(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error(
                            "OPEN_EXACT_ALARM_SETTINGS_FAILED",
                            e.message,
                            null
                        )
                    }
                }

                "isIgnoringBatteryOptimizations" -> {
                    try {
                        result.success(NativeAdhanScheduler.isIgnoringBatteryOptimizations(this))
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "openBatteryOptimizationSettings" -> {
                    try {
                        NativeAdhanScheduler.openBatteryOptimizationSettings(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error(
                            "OPEN_BATTERY_SETTINGS_FAILED",
                            e.message,
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}