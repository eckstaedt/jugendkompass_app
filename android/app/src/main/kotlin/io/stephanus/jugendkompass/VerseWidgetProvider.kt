package io.stephanus.jugendkompass

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.Intent

class VerseWidgetProvider : AppWidgetProvider() {

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
        // Widget added to home screen for first time
    }

    override fun onDisabled(context: Context) {
        // Last widget removed from home screen
    }

    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs: SharedPreferences = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

            val verseText = prefs.getString("verse_text", "Öffne die App um den Vers des Tages zu laden")
            val verseReference = prefs.getString("verse_reference", "")

            val views = RemoteViews(context.packageName, R.layout.verse_widget_layout)
            views.setTextViewText(R.id.widget_verse, verseText)
            views.setTextViewText(R.id.widget_reference, if (verseReference.isNullOrEmpty()) "" else "— $verseReference")

            // Create intent to open app when widget is clicked
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
