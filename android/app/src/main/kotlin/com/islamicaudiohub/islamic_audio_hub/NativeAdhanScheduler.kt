package com.islamicaudiohub.islamic_audio_hub

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log

object NativeAdhanScheduler {
    private const val TAG = "NativeAdhanScheduler"

    private const val REQUEST_BASE = 7000

    private const val EXTRA_ID = "id"
    private const val EXTRA_PRAYER_EN = "prayer_en"
    private const val EXTRA_PRAYER_AR = "prayer_ar"
    private const val EXTRA_RESOURCE_NAME = "resource_name"
    private const val EXTRA_TITLE = "title"
    private const val EXTRA_BODY = "body"

    fun scheduleAlarms(
        context: Context,
        alarms: List<Map<String, Any?>>
    ) {
        cancelAll(context)

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()

        alarms.forEachIndexed { index, alarm ->
            val triggerAtMillis = (alarm["triggerAtMillis"] as? Number)?.toLong() ?: return@forEachIndexed
            if (triggerAtMillis <= now) return@forEachIndexed

            val id = (alarm["id"] as? Number)?.toInt() ?: (REQUEST_BASE + index)
            val prayerEn = alarm["prayerEn"] as? String ?: ""
            val prayerAr = alarm["prayerAr"] as? String ?: ""
            val resourceName = alarm["resourceName"] as? String ?: "adhan_makkah"
            val title = alarm["title"] as? String ?: "حان وقت الصلاة"
            val body = alarm["body"] as? String ?: "إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا"

            val intent = Intent(context, AdhanAlarmReceiver::class.java).apply {
                putExtra(EXTRA_ID, id)
                putExtra(EXTRA_PRAYER_EN, prayerEn)
                putExtra(EXTRA_PRAYER_AR, prayerAr)
                putExtra(EXTRA_RESOURCE_NAME, resourceName)
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_BODY, body)
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag()
            )

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    if (alarmManager.canScheduleExactAlarms()) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerAtMillis,
                            pendingIntent
                        )
                    } else {
                        alarmManager.setAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerAtMillis,
                            pendingIntent
                        )
                    }
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                } else {
                    alarmManager.setExact(
                        AlarmManager.RTC_WAKEUP,
                        triggerAtMillis,
                        pendingIntent
                    )
                }

                Log.d(
                    TAG,
                    "Scheduled native adhan alarm: id=$id prayer=$prayerEn at=$triggerAtMillis resource=$resourceName"
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed to schedule native adhan alarm id=$id", e)
            }
        }
    }

    fun cancelAll(context: Context) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        for (id in REQUEST_BASE until REQUEST_BASE + 100) {
            val intent = Intent(context, AdhanAlarmReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                id,
                intent,
                PendingIntent.FLAG_NO_CREATE or immutableFlag()
            )

            if (pendingIntent != null) {
                alarmManager.cancel(pendingIntent)
                pendingIntent.cancel()
            }
        }

        val stopIntent = Intent(context, AdhanForegroundService::class.java)
        context.stopService(stopIntent)

        Log.d(TAG, "Cancelled all native adhan alarms.")
    }

    fun canScheduleExactAlarms(context: Context): Boolean {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    fun openExactAlarmSettings(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                data = Uri.parse("package:${context.packageName}")
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
        }
    }

    fun isIgnoringBatteryOptimizations(context: Context): Boolean {
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return powerManager.isIgnoringBatteryOptimizations(context.packageName)
    }

    fun openBatteryOptimizationSettings(context: Context) {
        val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
            data = Uri.parse("package:${context.packageName}")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        context.startActivity(intent)
    }

    private fun immutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }
}