package io.stephanus.jugendkompass

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import org.json.JSONArray
import java.io.File
import java.net.HttpURLConnection
import java.net.URL
import java.net.URLEncoder
import java.time.LocalDate

/** Today's verse for the widget (already in the app language). */
data class VerseWidgetData(
    val date: String,
    val verse: String,
    val reference: String,
    val language: String,
    val background: Bitmap?,
) {
    val template: Int get() = templateFor(date)

    companion object {
        private const val PREFS = "HomeWidgetPreferences" // written by home_widget
        const val TEMPLATE_COUNT = 6

        /** Same rule as iOS: days since 2000-01-01, modulo 6. */
        fun templateFor(isoDate: String): Int = try {
            val days = LocalDate.parse(isoDate).toEpochDay() - 10957
            (((days % TEMPLATE_COUNT) + TEMPLATE_COUNT) % TEMPLATE_COUNT).toInt()
        } catch (e: Exception) {
            0
        }

        private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        fun cached(context: Context): VerseWidgetData {
            val p = prefs(context)
            val lang = p.getString("app_language", null) ?: "de"
            val date = p.getString("verse_date", null) ?: LocalDate.now().toString()
            return VerseWidgetData(
                date = date,
                verse = p.getString("verse_text", null) ?: "",
                reference = p.getString("verse_reference", null) ?: "",
                language = lang,
                background = loadCachedImage(context, date),
            )
        }

        /** Fetches today's verse (+ translation, photo); falls back to cache. */
        fun load(context: Context): VerseWidgetData {
            val p = prefs(context)
            val lang = p.getString("app_language", null) ?: "de"
            val base = p.getString("supabase_url", null)
            val key = p.getString("supabase_anon_key", null)
            val today = LocalDate.now().toString()
            if (base.isNullOrEmpty() || key.isNullOrEmpty()) return cached(context)

            return try {
                val rows = JSONArray(
                    get(base, key, "/rest/v1/verse_of_the_day?select=content_id,verse,reference,background_image_url&date=eq.$today&limit=1")
                )
                if (rows.length() == 0) return cached(context)
                val row = rows.getJSONObject(0)
                var verse = clean(row.optString("verse"))
                var reference = clean(row.optString("reference"))
                val contentId = row.optString("content_id")
                if (lang != "de" && contentId.isNotEmpty()) {
                    val tr = JSONArray(
                        get(base, key, "/rest/v1/content_translations?select=field_name,value" +
                            "&content_id=eq.${enc(contentId)}&language=eq.${enc(lang)}")
                    )
                    for (i in 0 until tr.length()) {
                        val t = tr.getJSONObject(i)
                        val value = clean(t.optString("value"))
                        if (value.isEmpty()) continue
                        when (t.optString("field_name")) {
                            "verse" -> verse = value
                            "reference" -> reference = value
                        }
                    }
                }
                p.edit()
                    .putString("verse_text", verse)
                    .putString("verse_reference", reference)
                    .putString("verse_date", today)
                    .apply()

                var image = loadCachedImage(context, today)
                val bgUrl = row.optString("background_image_url")
                if (image == null && bgUrl.isNotEmpty() && bgUrl != "null") {
                    image = downloadImage(context, bgUrl, today)
                }
                VerseWidgetData(today, verse, reference, lang, image)
            } catch (e: Exception) {
                cached(context)
            }
        }

        private fun enc(s: String) = URLEncoder.encode(s, "UTF-8")

        private fun get(base: String, key: String, path: String): String {
            val conn = URL(base.trimEnd('/') + path).openConnection() as HttpURLConnection
            conn.connectTimeout = 15000
            conn.readTimeout = 15000
            conn.setRequestProperty("apikey", key)
            conn.setRequestProperty("Authorization", "Bearer $key")
            return try {
                if (conn.responseCode != 200) throw IllegalStateException("HTTP ${conn.responseCode}")
                conn.inputStream.bufferedReader().use { it.readText() }
            } finally {
                conn.disconnect()
            }
        }

        fun clean(s: String): String = s
            .replace(Regex("<[^>]+>"), "")
            .replace("&nbsp;", " ")
            .replace("&amp;", "&")
            .replace("&quot;", "\"")
            .replace("&#39;", "'")
            .trim()

        private fun cacheFile(context: Context, date: String) = File(context.filesDir, "widget_bg_$date.jpg")

        private fun loadCachedImage(context: Context, date: String): Bitmap? {
            val f = cacheFile(context, date)
            return if (f.exists()) BitmapFactory.decodeFile(f.absolutePath) else null
        }

        private fun downloadImage(context: Context, url: String, date: String): Bitmap? = try {
            var conn = URL(url).openConnection() as HttpURLConnection
            conn.instanceFollowRedirects = true
            conn.connectTimeout = 15000
            conn.readTimeout = 20000
            // picsum redirects to its CDN (https → https)
            var hops = 0
            while (conn.responseCode in 300..399 && hops < 5) {
                val next = conn.getHeaderField("Location")
                conn.disconnect()
                conn = URL(URL(url), next).openConnection() as HttpURLConnection
                hops++
            }
            val bytes = conn.inputStream.use { it.readBytes() }
            conn.disconnect()
            // Decode downscaled (max ~900 px) to keep the widget light.
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
            var sample = 1
            while (maxOf(bounds.outWidth, bounds.outHeight) / (sample * 2) >= 900) sample *= 2
            val bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size,
                BitmapFactory.Options().apply { inSampleSize = sample })
            if (bmp != null) {
                context.filesDir.listFiles()?.filter { it.name.startsWith("widget_bg_") }?.forEach { it.delete() }
                cacheFile(context, date).outputStream().use { bmp.compress(Bitmap.CompressFormat.JPEG, 85, it) }
            }
            bmp
        } catch (e: Exception) {
            null
        }
    }
}
