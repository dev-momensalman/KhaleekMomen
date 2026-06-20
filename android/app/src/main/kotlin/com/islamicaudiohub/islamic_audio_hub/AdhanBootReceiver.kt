package com.islamicaudiohub.islamic_audio_hub

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        val shouldReschedule = action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == Intent.ACTION_TIME_CHANGED ||
            action == Intent.ACTION_TIMEZONE_CHANGED

        if (!shouldReschedule) return

        try {
            val count = NativeAdhanScheduler.scheduleStoredAlarms(context)

            Log.d(
                "AdhanBootReceiver",
                "Rescheduled native adhan alarms after $action. count=$count"
            )
        } catch (e: Exception) {
            Log.e(
                "AdhanBootReceiver",
                "Failed to reschedule native adhan alarms after $action",
                e
            )
        }
    }
}