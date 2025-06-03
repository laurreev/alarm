package com.example.alarm

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "alarm_channel"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "setAlarm") {
                val args = call.arguments as Map<String, Any>
                setAlarm(args)
                result.success(null)
            } else if (call.method == "stopNativeAlarm") {
                try {
                    AlarmReceiver.ringtone?.stop()
                } catch (e: Exception) {}
                result.success(null)
            }
        }
    }

    private fun setAlarm(args: Map<String, Any>) {
        val year = args["year"] as Int
        val month = args["month"] as Int
        val day = args["day"] as Int
        val hour = args["hour"] as Int
        val minute = args["minute"] as Int
        val label = args["label"] as String
        val alarmId = (args["alarmId"] as String).hashCode()

        val calendar = java.util.Calendar.getInstance().apply {
            set(java.util.Calendar.YEAR, year)
            set(java.util.Calendar.MONTH, month - 1)
            set(java.util.Calendar.DAY_OF_MONTH, day)
            set(java.util.Calendar.HOUR_OF_DAY, hour)
            set(java.util.Calendar.MINUTE, minute)
            set(java.util.Calendar.SECOND, 0)
            set(java.util.Calendar.MILLISECOND, 0)
        }

        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("label", label)
            putExtra("alarmId", args["alarmId"] as String)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            alarmId,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.setExactAndAllowWhileIdle(
            AlarmManager.RTC_WAKEUP,
            calendar.timeInMillis,
            pendingIntent
        )
    }
}
