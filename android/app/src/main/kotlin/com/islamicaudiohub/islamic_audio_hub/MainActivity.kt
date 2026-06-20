package com.islamicaudiohub.islamic_audio_hub

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

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
                        val alarms =
                            call.argument<List<Map<String, Any?>>>("alarms") ?: emptyList()

                        val scheduledCount = NativeAdhanScheduler.scheduleAlarms(
                            this,
                            alarms
                        )

                        if (alarms.isNotEmpty() && scheduledCount <= 0) {
                            result.error(
                                "NO_ADHAN_ALARMS_SCHEDULED",
                                "Native scheduler received ${alarms.size} alarm(s), but scheduled 0.",
                                null
                            )
                        } else {
                            result.success(scheduledCount)
                        }
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
                        result.success(
                            NativeAdhanScheduler.canScheduleExactAlarms(this)
                        )
                    } catch (_: Exception) {
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
                        result.success(
                            NativeAdhanScheduler.isIgnoringBatteryOptimizations(this)
                        )
                    } catch (_: Exception) {
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

                "playTestAdhan" -> {
                    try {
                        val resourceName =
                            call.argument<String>("resourceName") ?: "adhan_makkah"
                        val prayerAr =
                            call.argument<String>("prayerAr") ?: "اختبار الأذان"

                        NativeAdhanScheduler.playTestAdhan(
                            this,
                            resourceName,
                            prayerAr
                        )

                        result.success(true)
                    } catch (e: Exception) {
                        result.error(
                            "PLAY_TEST_ADHAN_FAILED",
                            e.message,
                            null
                        )
                    }
                }

                "stopAdhan" -> {
                    try {
                        NativeAdhanScheduler.stopAdhanService(this)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error(
                            "STOP_ADHAN_FAILED",
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