package com.webelight.poc

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Notification
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

/**
 * Holds the app in the foreground while Media3 encodes.
 *
 * The compression itself is not moved here. It already runs in this process
 * off the activity (the compressor plugin holds the application context and
 * only stops on engine detach), so all that is missing is the priority that
 * stops the system freezing or killing a cached process mid-encode. A
 * foreground service is exactly that priority, and the notification is the
 * price the platform charges for it.
 */
class CompressionService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        Log.i(TAG, "foreground service stopped")
        super.onDestroy()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: DEFAULT_TITLE
        val subtitle = intent?.getStringExtra(EXTRA_SUBTITLE).orEmpty()
        val notification = buildNotification(this, title, subtitle, progressPercent = 0)

        if (!enterForeground(notification)) {
            // None of this is worth taking the app down for. The encode is
            // already running and carries on regardless; it just loses the
            // protection that keeps it alive off screen.
            Log.w(TAG, "could not enter the foreground; encode continues unprotected")
            stopSelf()
        }

        // Restarting ourselves after a kill would encode nothing: the Dart
        // side that owns the job is gone too.
        return START_NOT_STICKY
    }

    /**
     * Enters the foreground under the best type this platform will accept.
     *
     * Passing a type the running platform does not know throws
     * `InvalidForegroundServiceTypeException` rather than being ignored, and
     * the constants are not all the same vintage, so the candidates are tried
     * in order and every failure is survivable.
     */
    private fun enterForeground(notification: Notification): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            return runCatching { startForeground(NOTIFICATION_ID, notification) }
                .onSuccess { Log.i(TAG, "foreground service running (untyped, pre-API 29)") }
                .onFailure { Log.w(TAG, "startForeground failed", it) }
                .isSuccess
        }

        for ((label, type) in serviceTypes()) {
            val attempt = runCatching { startForeground(NOTIFICATION_ID, notification, type) }
            if (attempt.isSuccess) {
                Log.i(TAG, "foreground service running, type=$label")
                return true
            }
            Log.w(TAG, "foreground type $label rejected", attempt.exceptionOrNull())
        }

        return false
    }

    /**
     * Best fit first.
     *
     * `mediaProcessing` describes this work exactly but only exists from API
     * 35; `dataSync` is the closest type the platform has accepted since 29.
     */
    private fun serviceTypes(): List<Pair<String, Int>> = buildList {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            add("mediaProcessing" to ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROCESSING)
        }
        add("dataSync" to ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC)
    }

    companion object {
        const val EXTRA_TITLE = "title"
        const val EXTRA_SUBTITLE = "subtitle"

        private const val TAG = "background_task"
        private const val DEFAULT_TITLE = "Compressing video"
        private const val CHANNEL_ID = "compression"
        private const val NOTIFICATION_ID = 42

        /**
         * Updates the progress bar on the running service's notification.
         *
         * Posted straight to the notification manager rather than by
         * restarting the service: same notification id, so the foreground
         * service keeps its hold, and this is legal to call from anywhere.
         */
        fun updateProgress(context: Context, title: String, subtitle: String, progressPercent: Int) {
            if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) {
                Log.w(TAG, "notifications are disabled; service runs but shows nothing")
                return
            }
            NotificationManagerCompat.from(context)
                .notify(NOTIFICATION_ID, buildNotification(context, title, subtitle, progressPercent))
        }

        private fun buildNotification(
            context: Context,
            title: String,
            subtitle: String,
            progressPercent: Int,
        ): Notification {
            createChannel(context)
            return NotificationCompat.Builder(context, CHANNEL_ID)
                .setContentTitle(title)
                .setContentText(subtitle)
                .setSmallIcon(android.R.drawable.stat_sys_upload)
                .setOngoing(true)
                .setOnlyAlertOnce(true)
                .setProgress(100, progressPercent, progressPercent <= 0)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build()
        }

        private fun createChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Video compression",
                NotificationManager.IMPORTANCE_LOW,
            ).apply { setShowBadge(false) }
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}
