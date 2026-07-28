package com.fldev.dilalquran

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.RingtoneManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val channelName = "dilalquran/ringtone"
    private val powerChannelName = "dilalquran/power"
    private val pickRequestCode = 4231
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        configurePowerChannel(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pickRingtone" -> {
                        if (pendingResult != null) {
                            result.error("BUSY", "Pemilih suara sudah terbuka", null)
                            return@setMethodCallHandler
                        }
                        pendingResult = result
                        val current = call.argument<String>("current")
                        val intent = Intent(RingtoneManager.ACTION_RINGTONE_PICKER).apply {
                            putExtra(
                                RingtoneManager.EXTRA_RINGTONE_TITLE,
                                "Pilih Suara Notifikasi"
                            )
                            putExtra(
                                RingtoneManager.EXTRA_RINGTONE_TYPE,
                                RingtoneManager.TYPE_ALL
                            )
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_DEFAULT, true)
                            putExtra(RingtoneManager.EXTRA_RINGTONE_SHOW_SILENT, false)
                            if (!current.isNullOrEmpty()) {
                                putExtra(
                                    RingtoneManager.EXTRA_RINGTONE_EXISTING_URI,
                                    Uri.parse(current)
                                )
                            }
                        }
                        try {
                            startActivityForResult(intent, pickRequestCode)
                        } catch (e: Exception) {
                            pendingResult = null
                            result.error(
                                "UNAVAILABLE",
                                "Pemilih ringtone tidak tersedia",
                                null
                            )
                        }
                    }

                    "getRingtoneTitle" -> {
                        val uriStr = call.argument<String>("uri")
                        if (uriStr.isNullOrEmpty()) {
                            result.success(null)
                            return@setMethodCallHandler
                        }
                        val title = try {
                            RingtoneManager.getRingtone(this, Uri.parse(uriStr))
                                ?.getTitle(this)
                        } catch (e: Exception) {
                            null
                        }
                        result.success(title)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    // Channel untuk membebaskan aplikasi dari optimasi baterai agar
    // alarm/notifikasi shalat tetap berjalan meski aplikasi ditutup.
    private fun configurePowerChannel(flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, powerChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isIgnoringBatteryOptimizations" -> {
                        result.success(isIgnoringBatteryOptimizations())
                    }

                    "requestIgnoreBatteryOptimizations" -> {
                        if (isIgnoringBatteryOptimizations()) {
                            result.success(true)
                            return@setMethodCallHandler
                        }
                        try {
                            @Suppress("BatteryLife")
                            val intent = Intent(
                                Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                                Uri.parse("package:$packageName")
                            )
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            // Fallback: buka daftar pengaturan optimasi baterai.
                            try {
                                startActivity(
                                    Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
                                )
                                result.success(true)
                            } catch (e2: Exception) {
                                result.success(false)
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }

    private fun isIgnoringBatteryOptimizations(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return true
        val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
        return pm?.isIgnoringBatteryOptimizations(packageName) ?: true
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickRequestCode) return

        val res = pendingResult
        pendingResult = null
        if (res == null) return

        if (resultCode == Activity.RESULT_OK) {
            val uri: Uri? =
                data?.getParcelableExtra(RingtoneManager.EXTRA_RINGTONE_PICKED_URI)
            if (uri == null) {
                // "Diam" / tidak ada yang dipilih.
                res.success(null)
            } else {
                val title = try {
                    RingtoneManager.getRingtone(this, uri)?.getTitle(this)
                } catch (e: Exception) {
                    null
                }
                res.success(
                    mapOf(
                        "uri" to uri.toString(),
                        "title" to (title ?: "Suara terpilih")
                    )
                )
            }
        } else {
            // Dibatalkan.
            res.success(null)
        }
    }
}
