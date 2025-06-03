package com.example.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class StopAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("StopAlarmReceiver", "Stop action received")
        // Stop the ringtone if playing
        try {
            com.example.alarm.AlarmReceiver.ringtone?.stop()
        } catch (e: Exception) {
            Log.e("StopAlarmReceiver", "Failed to stop ringtone", e)
        }
        // Cancel the alarm notification
        val alarmId = intent.getIntExtra("alarmId", 0)
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
        notificationManager.cancel(alarmId)
    }
}
