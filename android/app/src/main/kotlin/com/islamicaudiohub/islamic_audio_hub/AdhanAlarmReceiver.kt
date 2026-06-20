package com.islamicaudiohub.islamic_audio_hub

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("AdhanAlarmReceiver", "Adhan alarm received.")

        val serviceIntent = Intent(context, AdhanForegroundService::class.java).apply {
            action = AdhanForegroundService.ACTION_PLAY_ADHAN

            putExtra(
                AdhanForegroundService.EXTRA_ID,
                intent.getIntExtra("id", 0)
            )
            putExtra(
                AdhanForegroundService.EXTRA_PRAYER_EN,
                intent.getStringExtra("prayer_en") ?: ""
            )
            putExtra(
                AdhanForegroundService.EXTRA_PRAYER_AR,
                intent.getStringExtra("prayer_ar") ?: ""
            )
            putExtra(
                AdhanForegroundService.EXTRA_RESOURCE_NAME,
                intent.getStringExtra("resource_name") ?: "adhan_makkah"
            )
            putExtra(
                AdhanForegroundService.EXTRA_TITLE,
                intent.getStringExtra("title") ?: "حان وقت الصلاة"
            )
            putExtra(
                AdhanForegroundService.EXTRA_BODY,
                intent.getStringExtra("body")
                    ?: "إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا"
            )
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}