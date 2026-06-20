package com.islamicaudiohub.islamic_audio_hub

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat

class AdhanForegroundService : Service() {
    companion object {
        const val ACTION_PLAY_ADHAN = "com.islamicaudiohub.islamic_audio_hub.PLAY_ADHAN"
        const val ACTION_STOP_ADHAN = "com.islamicaudiohub.islamic_audio_hub.STOP_ADHAN"

        const val EXTRA_ID = "id"
        const val EXTRA_PRAYER_EN = "prayer_en"
        const val EXTRA_PRAYER_AR = "prayer_ar"
        const val EXTRA_RESOURCE_NAME = "resource_name"
        const val EXTRA_TITLE = "title"
        const val EXTRA_BODY = "body"

        private const val TAG = "AdhanForegroundService"
        private const val CHANNEL_ID = "native_adhan_foreground_channel_v3"
        private const val NOTIFICATION_ID = 9200
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP_ADHAN -> {
                stopAdhan()
                return START_NOT_STICKY
            }

            ACTION_PLAY_ADHAN -> {
                val prayerAr = intent.getStringExtra(EXTRA_PRAYER_AR) ?: ""
                val resourceName = intent.getStringExtra(EXTRA_RESOURCE_NAME) ?: "adhan_makkah"
                val title = intent.getStringExtra(EXTRA_TITLE) ?: "حان وقت الصلاة"
                val body = intent.getStringExtra(EXTRA_BODY)
                    ?: "إِنَّ الصَّلَاةَ كَانَتْ عَلَى الْمُؤْمِنِينَ كِتَابًا مَّوْقُوتًا"

                startForeground(
                    NOTIFICATION_ID,
                    buildNotification(
                        title = title,
                        body = body,
                        prayerAr = prayerAr
                    )
                )

                playAdhan(resourceName)
            }
        }

        return START_NOT_STICKY
    }

    private fun playAdhan(resourceName: String) {
        try {
            stopCurrentPlayerOnly()
            acquireWakeLock()

            val resId = resources.getIdentifier(
                resourceName,
                "raw",
                packageName
            )

            if (resId == 0) {
                Log.e(TAG, "Raw resource not found: $resourceName")
                stopAdhan()
                return
            }

            val afd = resources.openRawResourceFd(resId)
            val player = MediaPlayer()

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    player.setAudioAttributes(
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .build()
                    )
                }

                player.setWakeMode(
                    applicationContext,
                    PowerManager.PARTIAL_WAKE_LOCK
                )

                player.setDataSource(
                    afd.fileDescriptor,
                    afd.startOffset,
                    afd.length
                )
            } finally {
                try {
                    afd.close()
                } catch (_: Exception) {
                }
            }

            player.setOnCompletionListener {
                stopAdhan()
            }

            player.setOnErrorListener { _, what, extra ->
                Log.e(TAG, "MediaPlayer error what=$what extra=$extra")
                stopAdhan()
                true
            }

            player.prepare()
            mediaPlayer = player
            player.start()

            Log.d(TAG, "Native full adhan started: $resourceName")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to play native adhan.", e)
            stopAdhan()
        }
    }

    private fun buildNotification(
        title: String,
        body: String,
        prayerAr: String
    ): Notification {
        val stopIntent = Intent(this, AdhanForegroundService::class.java).apply {
            action = ACTION_STOP_ADHAN
        }

        val stopPendingIntent = PendingIntent.getService(
            this,
            9991,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag()
        )

        val openIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        } ?: Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }

        val openPendingIntent = PendingIntent.getActivity(
            this,
            9992,
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag()
        )

        val displayTitle = if (prayerAr.isNotBlank()) {
            "🕌 حان وقت صلاة $prayerAr"
        } else {
            title
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(displayTitle)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(openPendingIntent)
            .addAction(
                android.R.drawable.ic_media_pause,
                "إيقاف الأذان",
                stopPendingIntent
            )
            .build()
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "الأذان الكامل",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "تشغيل الأذان الكامل عند وقت الصلاة"
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                setSound(null, null)
                enableVibration(true)
                enableLights(true)
            }

            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun acquireWakeLock() {
        try {
            if (wakeLock?.isHeld == true) return

            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

            wakeLock = powerManager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "KhaleekMomen:AdhanWakeLock"
            ).apply {
                setReferenceCounted(false)
                acquire(10 * 60 * 1000L)
            }
        } catch (e: Exception) {
            Log.e(TAG, "WakeLock acquire failed.", e)
        }
    }

    private fun releaseWakeLock() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }

            wakeLock = null
        } catch (e: Exception) {
            Log.e(TAG, "WakeLock release failed.", e)
        }
    }

    private fun stopCurrentPlayerOnly() {
        try {
            mediaPlayer?.stop()
        } catch (_: Exception) {
        }

        try {
            mediaPlayer?.release()
        } catch (_: Exception) {
        }

        mediaPlayer = null
    }

    private fun stopAdhan() {
        stopCurrentPlayerOnly()
        releaseWakeLock()

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                stopForeground(STOP_FOREGROUND_REMOVE)
            } else {
                @Suppress("DEPRECATION")
                stopForeground(true)
            }
        } catch (_: Exception) {
            try {
                @Suppress("DEPRECATION")
                stopForeground(true)
            } catch (_: Exception) {
            }
        }

        stopSelf()
        Log.d(TAG, "Native adhan stopped.")
    }

    override fun onDestroy() {
        stopCurrentPlayerOnly()
        releaseWakeLock()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun immutableFlag(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
    }
}