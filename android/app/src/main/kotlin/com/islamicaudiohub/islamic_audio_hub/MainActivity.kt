package com.islamicaudiohub.islamic_audio_hub

import android.os.Handler
import android.os.Looper
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : AudioServiceActivity() {
    private val channelName = "khaleek_momen/adhan_alarm"

    private val nativeExecutor = Executors.newSingleThreadExecutor()
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAdhanAlarms" -> {
                    val alarms =
                        call.argument<List<Map<String, Any?>>>("alarms") ?: emptyList()

                    nativeExecutor.execute {
                        try {
                            val scheduledCount = NativeAdhanScheduler.scheduleAlarms(
                                applicationContext,
                                alarms
                            )

                            mainHandler.post {
                                if (alarms.isNotEmpty() && scheduledCount <= 0) {
                                    result.error(
                                        "NO_ADHAN_ALARMS_SCHEDULED",
                                        "Native scheduler received ${alarms.size} alarm(s), but scheduled 0.",
                                        null
                                    )
                                } else {
                                    result.success(scheduledCount)
                                }
                            }
                        } catch (e: Exception) {
                            mainHandler.post {
                                result.error(
                                    "SCHEDULE_ADHAN_ALARMS_FAILED",
                                    e.message,
                                    null
                                )
                            }
                        }
                    }
                }

                "cancelAdhanAlarms" -> {
                    nativeExecutor.execute {
                        try {
                            NativeAdhanScheduler.cancelAll(applicationContext)

                            mainHandler.post {
                                result.success(true)
                            }
                        } catch (e: Exception) {
                            mainHandler.post {
                                result.error(
                                    "CANCEL_ADHAN_ALARMS_FAILED",
                                    e.message,
                                    null
                                )
                            }
                        }
                    }
                }

                "canScheduleExactAlarms" -> {
                    try {
                        result.success(
                            NativeAdhanScheduler.canScheduleExactAlarms(applicationContext)
                        )
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }

                "openExactAlarmSettings" -> {
                    try {
                        NativeAdhanScheduler.openExactAlarmSettings(applicationContext)
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
                            NativeAdhanScheduler.isIgnoringBatteryOptimizations(
                                applicationContext
                            )
                        )
                    } catch (_: Exception) {
                        result.success(false)
                    }
                }

                "openBatteryOptimizationSettings" -> {
                    try {
                        NativeAdhanScheduler.openBatteryOptimizationSettings(
                            applicationContext
                        )
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
                            applicationContext,
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
                        NativeAdhanScheduler.stopAdhanService(applicationContext)
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

    override fun onDestroy() {
        try {
            nativeExecutor.shutdown()
        } catch (_: Exception) {
        }

        super.onDestroy()
    }
}