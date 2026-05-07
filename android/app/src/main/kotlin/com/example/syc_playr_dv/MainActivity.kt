package com.example.syc_playr_dv

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "com.sycplayr.music/command"
    }

    private var methodChannel: MethodChannel? = null

    private val musicStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            when (intent?.action) {
                "com.sycplayr.music.STATE_CHANGED" -> {
                    val isPlaying = intent.getBooleanExtra("isPlaying", false)
                    methodChannel?.invokeMethod("onStateChanged", mapOf("isPlaying" to isPlaying))
                }
                "com.sycplayr.music.ACTION_PREVIOUS" -> {
                    methodChannel?.invokeMethod("onPrevious", null)
                }
                "com.sycplayr.music.ACTION_NEXT" -> {
                    methodChannel?.invokeMethod("onNext", null)
                }
            }
        }
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "play" -> {
                    val title = call.argument<String>("title") ?: "Unknown Song"
                    val artist = call.argument<String>("artist") ?: "Unknown Artist"
                    val uri = call.argument<String>("uri") ?: ""
                    val intent = Intent(this, MusicService::class.java).apply {
                        action = "START"
                        putExtra("title", title)
                        putExtra("artist", artist)
                        putExtra("uri", uri)
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        startForegroundService(intent)
                    } else {
                        startService(intent)
                    }
                    result.success(null)
                }
                "pause" -> {
                    val intent = Intent(this, MusicService::class.java).apply {
                        action = "PAUSE"
                    }
                    startService(intent)
                    result.success(null)
                }
                "stop" -> {
                    val intent = Intent(this, MusicService::class.java).apply {
                        action = "STOP"
                    }
                    startService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onStart() {
        super.onStart()
        val filter = IntentFilter().apply {
            addAction("com.sycplayr.music.STATE_CHANGED")
            addAction("com.sycplayr.music.ACTION_PREVIOUS")
            addAction("com.sycplayr.music.ACTION_NEXT")
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(musicStateReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(musicStateReceiver, filter)
        }
    }

    override fun onResume() {
        super.onResume()
        MusicService.isAppActive = true
    }

    override fun onPause() {
        MusicService.isAppActive = false
        super.onPause()
    }

    override fun onStop() {
        unregisterReceiver(musicStateReceiver)
        super.onStop()
    }
}
