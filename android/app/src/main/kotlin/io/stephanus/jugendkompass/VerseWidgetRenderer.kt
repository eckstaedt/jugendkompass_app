package io.stephanus.jugendkompass

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.net.Uri
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.widget.RemoteViews
import kotlin.math.max
import kotlin.math.min
import kotlin.math.roundToInt

/**
 * Draws the "Vers des Tages" widget as one bitmap. Six layouts (same as on
 * iOS, based on the design examples); the layout changes every day. The
 * nature photo of the day is used as background whenever it exists.
 */
object VerseWidgetRenderer {

    private val LABELS = mapOf(
        "de" to "VERS DES TAGES", "en" to "VERSE OF THE DAY", "ru" to "СТИХ ДНЯ",
        "es" to "VERSÍCULO DEL DÍA", "pl" to "WERSET DNIA", "tr" to "GÜNÜN AYETİ", "he" to "פסוק היום",
    )
    private val EMPTY = mapOf(
        "de" to "Öffne die App, um den Vers des Tages zu laden.",
        "en" to "Open the app to load the verse of the day.",
        "ru" to "Открой приложение, чтобы загрузить стих дня.",
        "es" to "Abre la app para cargar el versículo del día.",
        "pl" to "Otwórz aplikację, aby wczytać werset dnia.",
        "tr" to "Günün ayetini yüklemek için uygulamayı aç.",
        "he" to "פתח את האפליקציה כדי לטעון את פסוק היום.",
    )

    private fun quote(verse: String, lang: String) = when (lang) {
        "de" -> "„$verse“"
        "pl" -> "„$verse”"
        "ru" -> "«$verse»"
        "he" -> verse
        else -> "“$verse”"
    }

    fun renderAll(context: Context, data: VerseWidgetData) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, VerseWidgetProvider::class.java))
        for (id in ids) {
            try {
                manager.updateAppWidget(id, views(context, manager, id, data))
            } catch (e: Exception) {
                // never crash the launcher process
            }
        }
    }

    private fun views(context: Context, manager: AppWidgetManager, id: Int, data: VerseWidgetData): RemoteViews {
        val density = context.resources.displayMetrics.density
        val options = manager.getAppWidgetOptions(id)
        val wDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 320).coerceAtLeast(110)
        val hDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, 160).coerceAtLeast(80)
        // Keep the bitmap well below the RemoteViews memory limit.
        var scale = density
        while (wDp * scale * hDp * scale > 1_100_000f && scale > 1f) scale -= 0.25f

        val bitmap = Bitmap.createBitmap((wDp * scale).roundToInt(), (hDp * scale).roundToInt(), Bitmap.Config.ARGB_8888)
        val label = LABELS[data.language] ?: LABELS.getValue("de")
        val verse = if (data.verse.isBlank()) EMPTY[data.language] ?: EMPTY.getValue("de") else quote(data.verse, data.language)
        Drawer(Canvas(bitmap), scale, data.background).draw(data.template, verse, data.reference, label)

        val views = RemoteViews(context.packageName, R.layout.verse_widget_layout)
        views.setImageViewBitmap(R.id.widget_image, bitmap)
        views.setContentDescription(R.id.widget_image, "$label: ${data.verse} ${data.reference}")
        val intent = Intent(Intent.ACTION_VIEW, Uri.parse("jugendkompass://verse"), context, MainActivity::class.java)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        views.setOnClickPendingIntent(
            R.id.widget_container,
            PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE),
        )
        return views
    }

    // ─── Drawing ───────────────────────────────────────────────────────────

    private class Drawer(val c: Canvas, val s: Float, val photo: Bitmap?) {
        val w = c.width.toFloat()
        val h = c.height.toFloat()
        val small = w / s < 200f
        val pad = (if (small) 14f else 18f) * s
        val radius = 22f * s
        val sans: Typeface = Typeface.create("sans-serif", Typeface.NORMAL)
        val sansMedium: Typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        val serif: Typeface = Typeface.create(Typeface.SERIF, Typeface.NORMAL)

        fun draw(template: Int, verse: String, reference: String, label: String) {
            val clip = Path().apply { addRoundRect(RectF(0f, 0f, w, h), radius, radius, Path.Direction.CW) }
            c.save()
            c.clipPath(clip)
            when (template) {
                1 -> tile(verse, reference, label)
                2 -> paper(verse, reference)
                3 -> split(verse, reference, label)
                4 -> bottom(verse, reference, label)
                5 -> center(verse, reference)
                else -> glass(verse, reference, label)
            }
            c.restore()
        }

        // ── helpers ──
        fun dp(v: Float) = v * s

        fun photoOrGradient(rect: RectF, dim: Int) {
            val p = photo
            if (p != null) {
                val scale = max(rect.width() / p.width, rect.height() / p.height)
                val sw = rect.width() / scale
                val sh = rect.height() / scale
                val sx = (p.width - sw) / 2f
                val sy = (p.height - sh) / 2f
                c.drawBitmap(p, Rect(sx.toInt(), sy.toInt(), (sx + sw).toInt(), (sy + sh).toInt()), rect, Paint(Paint.FILTER_BITMAP_FLAG))
            } else {
                c.drawRect(rect, Paint().apply {
                    shader = LinearGradient(rect.left, rect.top, rect.right, rect.bottom,
                        Color.rgb(102, 122, 158), Color.rgb(199, 184, 168), Shader.TileMode.CLAMP)
                })
            }
            if (dim > 0) c.drawRect(rect, Paint().apply { color = Color.argb(dim, 0, 0, 0) })
        }

        fun vGradient(top: Int, bottom: Int) {
            c.drawRect(0f, 0f, w, h, Paint().apply {
                shader = LinearGradient(0f, 0f, 0f, h, Color.argb(top, 0, 0, 0), Color.argb(bottom, 0, 0, 0), Shader.TileMode.CLAMP)
            })
        }

        fun paint(size: Float, color: Int, face: Typeface = sans, spacing: Float = 0f) = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            textSize = dp(size); this.color = color; typeface = face; letterSpacing = spacing
        }

        /** Multi-line text shrunk until it fits [maxH]; returns its height. */
        fun block(text: String, x: Float, y: Float, width: Float, maxH: Float, size: Float, color: Int,
                  face: Typeface = sansMedium, align: Layout.Alignment = Layout.Alignment.ALIGN_NORMAL,
                  shadow: Boolean = false, fromBottom: Boolean = false): Float {
            var sz = size
            var layout: StaticLayout
            while (true) {
                val tp = paint(sz, color, face)
                if (shadow) tp.setShadowLayer(dp(4f), 0f, dp(1f), Color.argb(70, 0, 0, 0))
                layout = StaticLayout.Builder.obtain(text, 0, text.length, tp, max(1, width.toInt()))
                    .setAlignment(align).setLineSpacing(0f, 1.12f).setIncludePad(false).build()
                if (layout.height <= maxH || sz <= 9f) break
                sz -= 0.5f
            }
            if (layout.height > maxH) {
                // still too long: cut at the last fitting line with an ellipsis
                val tp = paint(sz, color, face)
                layout = StaticLayout.Builder.obtain(text, 0, text.length, tp, max(1, width.toInt()))
                    .setAlignment(align).setLineSpacing(0f, 1.12f).setIncludePad(false)
                    .setEllipsize(android.text.TextUtils.TruncateAt.END)
                    .setMaxLines(max(1, (maxH / (layout.height / layout.lineCount.toFloat())).toInt())).build()
            }
            c.save()
            c.translate(x, if (fromBottom) y - layout.height else y)
            layout.draw(c)
            c.restore()
            return layout.height.toFloat()
        }

        fun line(text: String, x: Float, baseline: Float, size: Float, color: Int, spacing: Float = 0f,
                 face: Typeface = sansMedium, maxW: Float = w - 2 * pad, alignRight: Boolean = false) {
            val tp = paint(size, color, face, spacing)
            val t = android.text.TextUtils.ellipsize(text, tp, maxW, android.text.TextUtils.TruncateAt.END).toString()
            val dx = if (alignRight) x - tp.measureText(t) else x
            c.drawText(t, dx, baseline, tp)
        }

        fun cross(cx: Float, cy: Float, size: Float, color: Int, stroke: Float) {
            val p = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color; strokeWidth = stroke; strokeCap = Paint.Cap.ROUND }
            c.drawLine(cx, cy - size / 2, cx, cy + size / 2, p)
            c.drawLine(cx - size * 0.33f, cy - size * 0.18f, cx + size * 0.33f, cy - size * 0.18f, p)
        }

        fun book(cx: Float, cy: Float, size: Float, color: Int) {
            val p = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = color; style = Paint.Style.STROKE; strokeWidth = dp(1.4f); strokeJoin = Paint.Join.ROUND
            }
            val hw = size / 2; val hh = size * 0.36f
            val left = Path().apply {
                moveTo(cx, cy - hh + dp(2f)); quadTo(cx - hw * 0.5f, cy - hh - dp(1f), cx - hw, cy - hh + dp(1f))
                lineTo(cx - hw, cy + hh); quadTo(cx - hw * 0.5f, cy + hh - dp(2f), cx, cy + hh); close()
            }
            val right = Path().apply {
                moveTo(cx, cy - hh + dp(2f)); quadTo(cx + hw * 0.5f, cy - hh - dp(1f), cx + hw, cy - hh + dp(1f))
                lineTo(cx + hw, cy + hh); quadTo(cx + hw * 0.5f, cy + hh - dp(2f), cx, cy + hh); close()
            }
            c.drawPath(left, p); c.drawPath(right, p)
        }

        val white = Color.WHITE
        fun white(a: Int) = Color.argb(a, 255, 255, 255)

        // ── 0: Glass ──
        fun glass(verse: String, ref: String, label: String) {
            photoOrGradient(RectF(0f, 0f, w, h), 70)
            val top = pad + dp(10f)
            cross(pad + dp(8f), top, dp(if (small) 14f else 20f), white(230), dp(2f))
            if (!small) {
                line(label, pad + dp(26f), top + dp(4f), 10f, white(210), 0.22f)
                book(w - pad - dp(10f), top, dp(20f), white(215))
            }
            val refBase = h - pad
            line(ref, pad, refBase, if (small) 9f else 11f, white(210), 0.18f, maxW = w - 2 * pad - dp(50f))
            if (!small) c.drawRoundRect(RectF(w - pad - dp(40f), refBase - dp(4f), w - pad, refBase - dp(2f)), dp(1f), dp(1f), Paint().apply { color = white(150) })
            val areaTop = top + dp(18f)
            val areaBottom = refBase - dp(18f)
            block(verse, pad, areaTop, w - 2 * pad, areaBottom - areaTop, if (small) 13f else 17f, white, shadow = true)
        }

        // ── 1: Tile ──
        fun tile(verse: String, ref: String, label: String) {
            photoOrGradient(RectF(0f, 0f, w, h), 105)
            if (small) {
                line(label, pad, pad + dp(9f), 9f, white(200), 0.18f)
                block(verse, pad, pad + dp(18f), w - 2 * pad, h - 2 * pad - dp(34f), 13f, white)
                line(ref, pad, h - pad, 10f, white(210), 0.1f)
                return
            }
            val tileH = min(h - 2 * pad, dp(112f))
            val tileW = tileH * 0.92f
            val tile = RectF(pad, (h - tileH) / 2f, pad + tileW, (h + tileH) / 2f)
            c.drawRoundRect(tile, dp(16f), dp(16f), Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(235, 238, 236, 233) })
            cross(tile.centerX(), tile.top + tileH * 0.36f, tileH * 0.36f, Color.rgb(35, 35, 38), dp(2.4f))
            block(ref.uppercase(), tile.left + dp(6f), tile.top + tileH * 0.62f, tileW - dp(12f), tileH * 0.34f,
                10.5f, Color.rgb(50, 50, 54), sansMedium, Layout.Alignment.ALIGN_CENTER)
            val divX = tile.right + dp(14f)
            c.drawRect(divX, tile.top + dp(4f), divX + dp(1f), tile.bottom - dp(4f), Paint().apply { color = white(90) })
            val tx = divX + dp(14f)
            val tw = w - tx - pad
            line(label, tx, tile.top + dp(12f), 10f, white(190), 0.2f, maxW = tw)
            block(verse, tx, tile.top + dp(22f), tw, tile.bottom - tile.top - dp(22f), 15f, white)
        }

        // ── 2: Paper ──
        fun paper(verse: String, ref: String) {
            c.drawColor(Color.rgb(240, 240, 239))
            val p = photo
            if (p != null) {
                // photo fades in on the right (instead of the leaf)
                val rect = RectF(w * 0.45f, 0f, w, h)
                val layer = c.saveLayer(rect, null)
                photoOrGradient(rect, 0)
                c.drawRect(rect, Paint().apply {
                    shader = LinearGradient(rect.left, 0f, rect.right, 0f,
                        intArrayOf(Color.argb(255, 0, 0, 0), Color.argb(120, 0, 0, 0), Color.argb(0, 0, 0, 0)),
                        floatArrayOf(0f, 0.55f, 1f), Shader.TileMode.CLAMP)
                    xfermode = android.graphics.PorterDuffXfermode(android.graphics.PorterDuff.Mode.DST_OUT)
                })
                c.restoreToCount(layer)
            } else {
                val leaf = paint(80f, Color.argb(120, 115, 133, 107), serif)
                c.save(); c.rotate(-25f, w - dp(40f), h - dp(30f)); c.drawText("❦", w - dp(90f), h + dp(4f), leaf); c.restore()
            }
            line("“", pad - dp(2f), pad + dp(if (small) 26f else 36f), if (small) 34f else 48f, Color.rgb(150, 150, 150), face = Typeface.create(Typeface.SERIF, Typeface.BOLD))
            val top = pad + dp(if (small) 30f else 42f)
            val refBase = h - pad
            val textW = (if (small) w - 2 * pad else w * 0.62f - pad)
            block(verse, pad, top, textW, refBase - dp(18f) - top, if (small) 13f else 15f, Color.rgb(25, 25, 27))
            c.drawRect(pad, refBase - dp(4f), pad + dp(24f), refBase - dp(3f), Paint().apply { color = Color.rgb(60, 60, 62) })
            line(ref, pad + dp(34f), refBase, if (small) 10f else 12f, Color.rgb(75, 75, 78), 0.05f, maxW = textW - dp(34f))
        }

        // ── 3: Split ──
        fun split(verse: String, ref: String, label: String) {
            c.drawColor(Color.rgb(30, 33, 40))
            val left = RectF(0f, 0f, if (small) w else w * 0.6f, h)
            val layer = c.saveLayer(left, null)
            photoOrGradient(left, if (small) 110 else 10)
            if (!small) c.drawRect(left, Paint().apply {
                shader = LinearGradient(left.left, 0f, left.right, 0f,
                    intArrayOf(Color.argb(0, 0, 0, 0), Color.argb(0, 0, 0, 0), Color.argb(255, 0, 0, 0)),
                    floatArrayOf(0f, 0.45f, 1f), Shader.TileMode.CLAMP)
                xfermode = android.graphics.PorterDuffXfermode(android.graphics.PorterDuff.Mode.DST_OUT)
            })
            c.restoreToCount(layer)
            if (photo == null && !small) cross(dp(70f), h / 2f, dp(56f), Color.argb(200, 0, 0, 0), dp(6f))
            val tx = if (small) pad else w * 0.38f
            val tw = w - tx - pad
            if (!small) line(label, tx, pad + dp(10f), 10f, white(180), 0.2f, maxW = tw)
            val top = pad + dp(if (small) 4f else 22f)
            val refBase = h - pad
            block(verse, tx, top, tw, refBase - dp(18f) - top, if (small) 13f else 15f, white)
            line(ref, tx, refBase, if (small) 10f else 12f, white(195), maxW = tw)
        }

        // ── 4: Bottom ──
        fun bottom(verse: String, ref: String, label: String) {
            photoOrGradient(RectF(0f, 0f, w, h), 0)
            vGradient(35, 190)
            if (!small) {
                val tp = paint(9f, white, sansMedium, 0.16f)
                val lw = tp.measureText(label)
                val pill = RectF(pad, pad, pad + lw + dp(16f), pad + dp(20f))
                c.drawRoundRect(pill, dp(10f), dp(10f), Paint(Paint.ANTI_ALIAS_FLAG).apply { color = white(60) })
                c.drawText(label, pad + dp(8f), pill.bottom - dp(6.5f), tp)
            }
            val refBase = h - pad
            line(ref, pad, refBase, if (small) 10f else 12f, white(210))
            val maxH = h - pad - dp(if (small) 18f else 46f) - dp(20f)
            block(verse, pad, refBase - dp(18f), w - 2 * pad, maxH, if (small) 13f else 16f, white, fromBottom = true)
        }

        // ── 5: Center ──
        fun center(verse: String, ref: String) {
            photoOrGradient(RectF(0f, 0f, w, h), 125)
            cross(w / 2f, pad + dp(8f), dp(if (small) 12f else 16f), white(220), dp(1.6f))
            val refBase = h - pad
            val tp = paint(if (small) 9f else 10f, white(210), sansMedium, 0.2f)
            val refText = android.text.TextUtils.ellipsize(ref.uppercase(), tp, w - 2 * pad, android.text.TextUtils.TruncateAt.END).toString()
            c.drawText(refText, (w - tp.measureText(refText)) / 2f, refBase, tp)
            val top = pad + dp(24f)
            val maxH = refBase - dp(20f) - top
            block(verse, pad, top, w - 2 * pad, maxH, if (small) 13f else 17f, white, serif, Layout.Alignment.ALIGN_CENTER)
        }
    }
}
