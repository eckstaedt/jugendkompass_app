package io.stephanus.jugendkompass

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle

/**
 * "Vers des Tages" home-screen widget.
 *
 * Draws immediately from the cached verse and starts a background job that
 * loads today's verse (app language) and the nature photo of the day. A
 * periodic job keeps checking for a new verse, so the widget updates
 * without opening the app.
 */
class VerseWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        VerseWidgetRenderer.renderAll(context, VerseWidgetData.cached(context))
        VerseWidgetWorker.refreshNow(context)
        VerseWidgetWorker.schedulePeriodic(context)
    }

    override fun onEnabled(context: Context) {
        VerseWidgetWorker.schedulePeriodic(context)
        VerseWidgetWorker.refreshNow(context)
    }

    override fun onDisabled(context: Context) {
        VerseWidgetWorker.cancel(context)
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        // Resized → redraw at the new size.
        VerseWidgetRenderer.renderAll(context, VerseWidgetData.cached(context))
    }
}
