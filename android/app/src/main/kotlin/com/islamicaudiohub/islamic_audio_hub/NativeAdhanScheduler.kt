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
import org.json.JSONArray
import org.json.JSONObject

object NativeAdhanScheduler {
    private const val TAG = "NativeAdhanScheduler"

    private const val REQUEST_BASE = 7000
    private const val REQUEST_LIMIT = 100

    private const val PREFS_NAME = "khaleek_momen_native_adhan"
    private const val PREF_ALARMS = "scheduled_adhan_alarms"

    private const val EXTRA_ID = "id"
    private const val EXTRA_PRAYER_EN = "prayer_en"
    private const val EXTRA_PRAYER_AR = "prayer_ar"
    private const val EXTRA_RESOURCE_NAME = "resource_name"
    private const val EXTRA_TITLE = "title"
    private const val EXTRA_BODY = "body"

    fun scheduleAlarms(
        context: Context,
        alarms: List<Map<String, Any?>>
    ): Int {
        val futureAlarms = sanitizeFutureAlarms(alarms)

        persistAlarms(context, futureAlarms)

        cancelAll(context, clearStored = false)

        val scheduledCount = scheduleInternal(context, futureAlarms)

        Log.d(
            TAG,
            "scheduleAlarms: received=${alarms.size}, future=${futureAlarms.size}, scheduled=$scheduledCount"
        )

        return scheduledCount
    }

    fun scheduleStoredAlarms(context: Context): Int {
        val storedAlarms = loadStoredAlarms(context)
        val futureAlarms = sanitizeFutureAlarms(storedAlarms)

        persistAlarms(context, futureAlarms)

        cancelAll(context, clearStored = false)

        val scheduledCount = scheduleInternal(context, futureAlarms)

        Log.d(
            TAG,
            "scheduleStoredAlarms: stored=${storedAlarms.size}, future=${futureAlarms.size}, scheduled=$scheduledCount"
        )

        return scheduledCount
    }

    private fun scheduleInternal(
        context: Context,
        alarms: List<Map<String, Any?>>
    ): Int {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()

        var scheduledCount = 0

        alarms.forEachIndexed { index, alarm ->
            val triggerAtMillis =
                (alarm["triggerAtMillis"] as? Number)?.toLong() ?: return@forEachIndexed

            if (triggerAtMillis <= now) return@forEachIndexed

            val id = (alarm["id"] as? Number)?.toInt() ?: (REQUEST_BASE + index)
            val prayerEn = alarm["prayerEn"] as? String ?: ""
            val prayerAr = alarm["prayerAr"] as? String ?: ""
            val resourceName = alarm["resourceName"] as? String ?: "adhan_makkah"
            val title = alarm["title"] as? String ?: "حان وقت الصلاة"
            val body = alarm["body"] as? String
                ?: "إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا"

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
                if (canScheduleExactAlarms(context)) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
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
                } else {
                    val showIntent = buildOpenAppPendingIntent(context, id)

                    val alarmClockInfo = AlarmManager.AlarmClockInfo(
                        triggerAtMillis,
                        showIntent
                    )

                    alarmManager.setAlarmClock(
                        alarmClockInfo,
                        pendingIntent
                    )
                }

                scheduledCount++

                Log.d(
                    TAG,
                    "Scheduled native adhan alarm: id=$id prayer=$prayerEn at=$triggerAtMillis resource=$resourceName exact=${canScheduleExactAlarms(context)}"
                )
            } catch (e: Exception) {
                Log.e(TAG, "Failed to schedule native adhan alarm id=$id", e)
            }
        }

        return scheduledCount
    }

    fun cancelAll(context: Context) {
        cancelAll(context, clearStored = true)
    }

    private fun cancelAll(
        context: Context,
        clearStored: Boolean
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        for (id in REQUEST_BASE until REQUEST_BASE + REQUEST_LIMIT) {
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

            val openPendingIntent = PendingIntent.getActivity(
                context,
                id + 1000,
                buildOpenAppIntent(context),
                PendingIntent.FLAG_NO_CREATE or immutableFlag()
            )

            if (openPendingIntent != null) {
                openPendingIntent.cancel()
            }
        }

        stopAdhanService(context)

        if (clearStored) {
            clearStoredAlarms(context)
        }

        Log.d(TAG, "Cancelled all native adhan alarms. clearStored=$clearStored")
    }

    fun playTestAdhan(
        context: Context,
        resourceName: String,
        prayerAr: String
    ) {
        val serviceIntent = Intent(context, AdhanForegroundService::class.java).apply {
            action = AdhanForegroundService.ACTION_PLAY_ADHAN
            putExtra(AdhanForegroundService.EXTRA_ID, 9999)
            putExtra(AdhanForegroundService.EXTRA_PRAYER_EN, "Test")
            putExtra(AdhanForegroundService.EXTRA_PRAYER_AR, prayerAr)
            putExtra(AdhanForegroundService.EXTRA_RESOURCE_NAME, resourceName)
            putExtra(AdhanForegroundService.EXTRA_TITLE, "اختبار الأذان — خليك مؤمن")
            putExtra(
                AdhanForegroundService.EXTRA_BODY,
                "هذا اختبار لتشغيل الأذان الكامل من خدمة Android الأصلية"
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }

    fun stopAdhanService(context: Context) {
        val stopIntent = Intent(context, AdhanForegroundService::class.java).apply {
            action = AdhanForegroundService.ACTION_STOP_ADHAN
        }

        try {
            context.startService(stopIntent)
        } catch (_: Exception) {
            try {
                context.stopService(Intent(context, AdhanForegroundService::class.java))
            } catch (_: Exception) {
            }
        }
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

    private fun sanitizeFutureAlarms(
        alarms: List<Map<String, Any?>>
    ): List<Map<String, Any?>> {
        val now = System.currentTimeMillis()

        return alarms.mapIndexedNotNull { index, alarm ->
            val triggerAtMillis =
                (alarm["triggerAtMillis"] as? Number)?.toLong() ?: return@mapIndexedNotNull null

            if (triggerAtMillis <= now) return@mapIndexedNotNull null

            val id = (alarm["id"] as? Number)?.toInt() ?: (REQUEST_BASE + index)

            mapOf(
                "id" to id,
                "triggerAtMillis" to triggerAtMillis,
                "prayerEn" to (alarm["prayerEn"] as? String ?: ""),
                "prayerAr" to (alarm["prayerAr"] as? String ?: ""),
                "resourceName" to (alarm["resourceName"] as? String ?: "adhan_makkah"),
                "title" to (alarm["title"] as? String ?: "حان وقت الصلاة"),
                "body" to (
                    alarm["body"] as? String
                        ?: "إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا"
                    )
            )
        }
    }

    private fun persistAlarms(
        context: Context,
        alarms: List<Map<String, Any?>>
    ) {
        try {
            val array = JSONArray()

            alarms.forEach { alarm ->
                val obj = JSONObject()

                obj.put("id", alarm["id"])
                obj.put("triggerAtMillis", alarm["triggerAtMillis"])
                obj.put("prayerEn", alarm["prayerEn"])
                obj.put("prayerAr", alarm["prayerAr"])
                obj.put("resourceName", alarm["resourceName"])
                obj.put("title", alarm["title"])
                obj.put("body", alarm["body"])

                array.put(obj)
            }

            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(PREF_ALARMS, array.toString())
                .apply()

            Log.d(TAG, "Persisted ${alarms.size} native adhan alarm(s).")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to persist native alarms.", e)
        }
    }

    private fun loadStoredAlarms(context: Context): List<Map<String, Any?>> {
        return try {
            val raw = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .getString(PREF_ALARMS, null)
                ?: return emptyList()

            val array = JSONArray(raw)
            val alarms = mutableListOf<Map<String, Any?>>()

            for (i in 0 until array.length()) {
                val obj = array.getJSONObject(i)

                alarms.add(
                    mapOf(
                        "id" to obj.optInt("id"),
                        "triggerAtMillis" to obj.optLong("triggerAtMillis"),
                        "prayerEn" to obj.optString("prayerEn"),
                        "prayerAr" to obj.optString("prayerAr"),
                        "resourceName" to obj.optString("resourceName", "adhan_makkah"),
                        "title" to obj.optString("title", "حان وقت الصلاة"),
                        "body" to obj.optString(
                            "body",
                            "إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا"
                        )
                    )
                )
            }

            alarms
        } catch (e: Exception) {
            Log.e(TAG, "Failed to load stored native alarms.", e)
            emptyList()
        }
    }

    private fun clearStoredAlarms(context: Context) {
        try {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .remove(PREF_ALARMS)
                .apply()

            Log.d(TAG, "Cleared stored native adhan alarms.")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to clear stored native alarms.", e)
        }
    }

    private fun buildOpenAppPendingIntent(
        context: Context,
        id: Int
    ): PendingIntent {
        return PendingIntent.getActivity(
            context,
            id + 1000,
            buildOpenAppIntent(context),
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag()
        )
    }

    private fun buildOpenAppIntent(context: Context): Intent {
        return context.packageManager.getLaunchIntentForPackage(context.packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        } ?: Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:${context.packageName}")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
    }

    private fun immutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }
}