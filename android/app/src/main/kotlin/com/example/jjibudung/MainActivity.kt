package com.example.jjibudung

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "jjibudung/posture_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                // 🔥 포그라운드 자세 감지 서비스 시작
                "startService" -> {
                    val args = call.arguments as Map<*, *>
                    val baseline = (args["baselineAngle"] as? Double)?.toFloat() ?: 0f
                    val mode = args["mode"] as? String ?: "sit"

                    val intent = Intent(this, PostureService::class.java).apply {
                        putExtra("baselineAngle", baseline)
                        putExtra("mode", mode)
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        ContextCompat.startForegroundService(this, intent)
                    } else {
                        startService(intent)
                    }

                    result.success(true)
                }

                // 🔥 서비스 종료
                "stopService" -> {
                    val intent = Intent(this, PostureService::class.java)
                    stopService(intent)
                    result.success(true)
                }

                // 🔥 배터리 최적화 해제 요청 (갤럭시 필수)
                "requestIgnoreBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        val pkg = packageName

                        if (!pm.isIgnoringBatteryOptimizations(pkg)) {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS)
                            intent.data = android.net.Uri.parse("package:$pkg")
                            startActivity(intent)
                        }
                    }
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }
}