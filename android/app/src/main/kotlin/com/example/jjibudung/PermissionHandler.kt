package com.example.jjibudung

import android.app.*
import android.content.*
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class PermissionHandler(private val context: Context) {

    fun registerChannel(flutterEngine: FlutterEngine) {
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "jjibudung/permissions"
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAll" -> result.success(checkAll())
                "openBattery" -> { openBattery(); result.success(true) }
                "openBackground" -> { openBackground(); result.success(true) }
                "openNotification" -> { openNotification(); result.success(true) }
                else -> result.notImplemented()
            }
        }
    }

    // 전체 권한 상태 체크
    private fun checkAll(): Map<String, Boolean> {
        return mapOf(
            "battery" to !isBatteryOptimizationOn(),
            "background" to isBackgroundAllowed(),
            "notification" to isNotificationAllowed()
        )
    }

    // ① 배터리 최적화 해제 여부
    private fun isBatteryOptimizationOn(): Boolean {
        val pm = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        return !pm.isIgnoringBatteryOptimizations(context.packageName)
    }

    // ② 백그라운드 활동 허용 여부
    private fun isBackgroundAllowed(): Boolean {
        val am = context.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return am.isBackgroundRestricted.not()
    }

    // ③ 알림 권한 체크
    private fun isNotificationAllowed(): Boolean {
        val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        return nm.areNotificationsEnabled()
    }

    // 설정 화면 이동
    private fun openBattery() {
        val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    private fun openBackground() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
        intent.data = android.net.Uri.parse("package:${context.packageName}")
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }

    private fun openNotification() {
        val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
            putExtra("android.provider.extra.APP_PACKAGE", context.packageName)
        }
        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        context.startActivity(intent)
    }
}