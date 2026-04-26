package com.example.jjibudung

import android.app.*
import android.content.Context
import android.content.Intent
import android.hardware.*
import android.os.*
import androidx.core.app.NotificationCompat
import kotlin.math.abs
import java.util.*

class PostureService : Service(), SensorEventListener {

    companion object {
        private var totalSeconds = 0
        private var badTotalSeconds = 0
        private var badContinuousSeconds = 0

        fun getCurrentTimes(): Map<String, Int> = mapOf(
            "total" to totalSeconds,
            "badTotal" to badTotalSeconds,
            "badContinuous" to badContinuousSeconds
        )

        fun resetTimes() {
            totalSeconds = 0
            badTotalSeconds = 0
            badContinuousSeconds = 0
        }
    }

    private lateinit var sensorManager: SensorManager
    private var baselineAngle: Float = 0f
    private var lastAngle: Float = 0f
    private val threshold = 15f
    private val channelId = "posture_channel"
    private var timer: Timer? = null

    override fun onCreate() {
        super.onCreate()
        sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
        baselineAngle = intent.getFloatExtra("baselineAngle", 0f)

        createNotification()
        startForeground(1, notification("찌뿌둥 자세 감지 중"))

        sensorManager.registerListener(
            this,
            sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER),
            SensorManager.SENSOR_DELAY_NORMAL
        )

        startTimer()
        return START_STICKY
    }

    private fun startTimer() {
        timer = Timer()
        timer!!.scheduleAtFixedRate(object : TimerTask() {
            override fun run() {
                totalSeconds++

                val diff = abs(lastAngle - baselineAngle)
                if (diff >= threshold) {
                    badTotalSeconds++
                    badContinuousSeconds++
                } else {
                    badContinuousSeconds = 0
                }

                if (badContinuousSeconds >= 1800) vibrateWarning()
            }
        }, 0, 1000)
    }

    override fun onSensorChanged(event: SensorEvent) {
        lastAngle = event.values[1] * 10
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun vibrateWarning() {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        val effect = longArrayOf(0, 800, 400, 800)

        if (Build.VERSION.SDK_INT >= 26)
            vibrator.vibrate(VibrationEffect.createWaveform(effect, -1))
        else
            vibrator.vibrate(effect, -1)
    }

    private fun createNotification() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "찌뿌둥",
                NotificationManager.IMPORTANCE_LOW
            )
            getSystemService(NotificationManager::class.java)
                .createNotificationChannel(channel)
        }
    }

    private fun notification(text: String): Notification {
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("찌뿌둥")
            .setContentText(text)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        sensorManager.unregisterListener(this)
        timer?.cancel()
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}