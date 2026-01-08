package com.example.nc_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import es.antonborri.home_widget.HomeWidgetPlugin

/**
 * Today Widget Provider for Neural Calendar
 * Displays today's tasks summary on home screen
 */
class TodayWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }

    companion object {
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Get widget data from SharedPreferences
            val widgetData = HomeWidgetPlugin.getData(context)
            
            // Get data with defaults
            val date = widgetData.getString("date", "Today")
            val tasksText = widgetData.getString("tasks_text", "0/0")
            val progress = widgetData.getInt("progress", 0)
            val urgentCount = widgetData.getInt("urgent_count", 0)
            
            // Determine which layout to use based on widget size
            val views = RemoteViews(context.packageName, R.layout.widget_today_small)
            
            // Update views
            views.setTextViewText(R.id.widget_date, date)
            views.setTextViewText(R.id.widget_tasks_count, tasksText)
            views.setTextViewText(R.id.widget_progress_text, "$progress%")
            views.setProgressBar(R.id.widget_progress_bar, 100, progress, false)
            
            // Setup tap to open app
            val intent = Intent(context, MainActivity::class.java).apply {
                action = "OPEN_TODAY"
            }
            val pendingIntent = PendingIntent.getActivity(
                context, 
                0, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            
            // Update tasks if available
            if (urgentCount > 0) {
                updateTaskViews(views, widgetData, 0)
                if (urgentCount > 1) {
                    updateTaskViews(views, widgetData, 1)
                }
                if (urgentCount > 2) {
                    updateTaskViews(views, widgetData, 2)
                }
            }
            
            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
        
        private fun updateTaskViews(
            views: RemoteViews,
            widgetData: SharedPreferences,
            index: Int
        ) {
            val taskId = widgetData.getString("task_${index}_id", "")
            val taskTitle = widgetData.getString("task_${index}_title", "")
            val taskTime = widgetData.getString("task_${index}_time", "")
            val taskCompleted = widgetData.getBoolean("task_${index}_completed", false)
            
            if (taskId?.isNotEmpty() == true && taskTitle?.isNotEmpty() == true) {
                // Set task title
                val displayText = if (taskTime?.isNotEmpty() == true) {
                    "$taskTime - $taskTitle"
                } else {
                    taskTitle
                }
                
                // Update task views based on index
                when (index) {
                    0 -> {
                        views.setTextViewText(R.id.widget_task_1, displayText)
                        views.setInt(
                            R.id.widget_task_1,
                            "setBackgroundResource",
                            if (taskCompleted) R.drawable.task_completed_bg else R.drawable.task_bg
                        )
                    }
                    1 -> {
                        views.setTextViewText(R.id.widget_task_2, displayText)
                        views.setInt(
                            R.id.widget_task_2,
                            "setBackgroundResource",
                            if (taskCompleted) R.drawable.task_completed_bg else R.drawable.task_bg
                        )
                    }
                    2 -> {
                        views.setTextViewText(R.id.widget_task_3, displayText)
                        views.setInt(
                            R.id.widget_task_3,
                            "setBackgroundResource",
                            if (taskCompleted) R.drawable.task_completed_bg else R.drawable.task_bg
                        )
                    }
                }
            }
        }
    }
}
