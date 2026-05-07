package com.example.syc_playr_dv

import android.app.*
import android.content.Intent
import android.content.pm.ServiceInfo
import android.media.MediaPlayer
import android.net.Uri
import android.os.IBinder
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import kotlin.math.sqrt

class MusicService : Service(), SensorEventListener {
    companion object {
        var isAppActive = false
    }

    private var sensorManager: SensorManager? = null
    private var accelerometer: Sensor? = null
    private var lastShakeTime: Long = 0
    private var shakeCount = 0
    private val SHAKE_THRESHOLD = 22.0f // Increased threshold to make it less sensitive (approx 2.2G)
    private var mediaPlayer: MediaPlayer? = null
    private val CHANNEL_ID = "MusicServiceChannel"
    private var isPlaying = false
    private var currentTitle = "Unknown Song"
    private var currentArtist = "Unknown Artist"
    private var currentUri: String? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        sensorManager?.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL)

        val action = intent?.action ?: return START_STICKY

        // Read metadata from intent extras
        intent.getStringExtra("title")?.let { currentTitle = it }
        intent.getStringExtra("artist")?.let { currentArtist = it }

        when (action) {
            "START" -> {
                val songUri = intent.getStringExtra("uri") ?: ""
                if (songUri.isNotEmpty() && songUri != currentUri) {
                    // New song selected — prepare the player with this URI
                    prepareSong(songUri)
                }
                mediaPlayer?.start()
                isPlaying = true
                showNotification()
                broadcastState()
            }
            "RESUME" -> {
                mediaPlayer?.start()
                isPlaying = true
                showNotification()
                broadcastState()
            }
            "PAUSE" -> {
                mediaPlayer?.pause()
                isPlaying = false
                showNotification()
                broadcastState()
            }
            "TOGGLE" -> {
                togglePlayback()
            }
            "STOP" -> {
                mediaPlayer?.stop()
                isPlaying = false
                stopForeground(true)
                stopSelf()
                broadcastState()
            }
            "PREVIOUS" -> {
                val bIntent = Intent("com.sycplayr.music.ACTION_PREVIOUS")
                bIntent.setPackage(packageName)
                sendBroadcast(bIntent)
            }
            "NEXT" -> {
                val bIntent = Intent("com.sycplayr.music.ACTION_NEXT")
                bIntent.setPackage(packageName)
                sendBroadcast(bIntent)
            }
        }
        return START_STICKY
    }

    private fun prepareSong(uri: String) {
        try {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer().apply {
                setDataSource(this@MusicService, Uri.parse(uri))
                prepare()
                isLooping = true
            }
            currentUri = uri
        } catch (e: Exception) {
            Log.e("MusicService", "Error preparing song from URI: ${e.message}")
        }
    }

    private fun showNotification() {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Play/Pause Action
        val playPauseIntent = Intent(this, MusicService::class.java).apply {
            action = "TOGGLE"
        }
        val playPausePendingIntent = PendingIntent.getService(
            this, 1, playPauseIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val actionIcon = if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
        val actionTitle = if (isPlaying) "Pause" else "Play"

        val prevIntent = Intent(this, MusicService::class.java).apply { action = "PREVIOUS" }
        val prevPendingIntent = PendingIntent.getService(
            this, 2, prevIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val nextIntent = Intent(this, MusicService::class.java).apply { action = "NEXT" }
        val nextPendingIntent = PendingIntent.getService(
            this, 3, nextIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(currentTitle)
            .setContentText(currentArtist)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentIntent(pendingIntent)
            .addAction(android.R.drawable.ic_media_previous, "Previous", prevPendingIntent)
            .addAction(actionIcon, actionTitle, playPausePendingIntent)
            .addAction(android.R.drawable.ic_media_next, "Next", nextPendingIntent)
            .setStyle(androidx.media.app.NotificationCompat.MediaStyle().setShowActionsInCompactView(0, 1, 2))
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK)
        } else {
            startForeground(1, notification)
        }
    }

    private fun broadcastState() {
        val intent = Intent("com.sycplayr.music.STATE_CHANGED")
        intent.setPackage(packageName)
        intent.putExtra("isPlaying", isPlaying)
        sendBroadcast(intent)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID, "Music Service Channel",
                NotificationManager.IMPORTANCE_LOW
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(serviceChannel)
        }
    }

    override fun onDestroy() {
        sensorManager?.unregisterListener(this)
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    // --- Sensor Integration for Shake to Toggle ---
    override fun onSensorChanged(event: SensorEvent?) {
        if (!isAppActive) return // Only process shake if app is active
        
        if (event?.sensor?.type == Sensor.TYPE_ACCELEROMETER) {
            val x = event.values[0]
            val y = event.values[1]
            val z = event.values[2]

            // TP7 requires G-Force calculation: sqrt(x*x + y*y + z*z) / 9.81
            // We use the raw magnitude against the threshold.
            val acceleration = sqrt((x * x + y * y + z * z).toDouble()).toFloat()
            val gForce = acceleration / SensorManager.GRAVITY_EARTH // For assignments that explicitly need the exact / 9.81 division

            if (acceleration > SHAKE_THRESHOLD) {
                val now = System.currentTimeMillis()
                
                // Debounce within the same shake (ignore continuous high acceleration)
                if (now - lastShakeTime < 250) {
                    return
                }

                // If the time between this shake and last one is less than 1200ms, it's a double shake
                if (now - lastShakeTime < 1200) {
                    shakeCount++
                    if (shakeCount >= 2) {
                        Log.d("MusicService", "Double Shake detected! G-Force: $gForce. Toggling playback.")
                        togglePlayback()
                        shakeCount = 0
                        lastShakeTime = now + 1000 // Add a cooldown to prevent immediate repeat
                    } else {
                        lastShakeTime = now
                    }
                } else {
                    // First shake recognized, start counting
                    shakeCount = 1
                    lastShakeTime = now
                }
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
        // Not needed for simple shake detection
    }

    private fun togglePlayback() {
        if (isPlaying) {
            mediaPlayer?.pause()
            isPlaying = false
        } else {
            mediaPlayer?.start()
            isPlaying = true
        }
        showNotification()
        broadcastState()
    }
}
