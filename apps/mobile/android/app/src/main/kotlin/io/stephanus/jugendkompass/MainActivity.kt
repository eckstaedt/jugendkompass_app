package io.stephanus.jugendkompass

import android.app.WallpaperManager
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Enable edge-to-edge for Android 15+ compatibility
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.VANILLA_ICE_CREAM) {
            WindowCompat.setDecorFitsSystemWindows(window, false)
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // "Als Hintergrundbild": open the system wallpaper screen directly
        // (home / lock screen choice) with the rendered verse image.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "jugendkompass/wallpaper")
            .setMethodCallHandler { call, result ->
                if (call.method != "setWallpaper") { result.notImplemented(); return@setMethodCallHandler }
                val path = call.argument<String>("path")
                if (path == null) { result.error("no_path", "path missing", null); return@setMethodCallHandler }
                val file = File(path)
                val wm = WallpaperManager.getInstance(this)
                try {
                    val uri = FileProvider.getUriForFile(this, "$packageName.wallpaper_provider", file)
                    val intent = wm.getCropAndSetWallpaperIntent(uri)
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    startActivity(intent)
                    result.success("picker")
                } catch (e: Exception) {
                    // Some devices have no crop screen: set it on home + lock screen.
                    try {
                        wm.setBitmap(BitmapFactory.decodeFile(path))
                        result.success("set")
                    } catch (e2: Exception) {
                        result.error("failed", e2.message, null)
                    }
                }
            }
    }
}
