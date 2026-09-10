package com.webelight.poc

import android.content.Intent
import android.os.Build
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var title = "Compressing video"
    private var subtitle = ""
    private var loggedTenth = -1

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                // Android can always hold the process up, so the Dart side
                // never has to warn the user about leaving the app.
                "supportsBackground" -> result.success(true)

                "start" -> {
                    title = call.argument<String>("title") ?: title
                    subtitle = call.argument<String>("subtitle").orEmpty()
                    Log.i(TAG, "start: $title / $subtitle")
                    startService()
                    result.success(null)
                }

                "update" -> {
                    val progress = call.argument<Double>("progress") ?: 0.0
                    val percent = (progress * 100).toInt()
                    // Every tenth only: this arrives for each whole percent.
                    if (percent / 10 != loggedTenth) {
                        loggedTenth = percent / 10
                        Log.i(TAG, "progress $percent%")
                    }
                    CompressionService.updateProgress(this, title, subtitle, percent)
                    result.success(null)
                }

                "stop" -> {
                    Log.i(TAG, "stop")
                    loggedTenth = -1
                    stopService(Intent(this, CompressionService::class.java))
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Only ever called while the app is on screen (the user just tapped
     * Compress), which is what makes the foreground start legal on Oreo and
     * above.
     */
    private fun startService() {
        val intent = Intent(this, CompressionService::class.java)
            .putExtra(CompressionService.EXTRA_TITLE, title)
            .putExtra(CompressionService.EXTRA_SUBTITLE, subtitle)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        Log.i(TAG, "foreground service requested")
    }

    private companion object {
        const val CHANNEL = "com.webelight.poc/background_task"
        const val TAG = "background_task"
    }
}
