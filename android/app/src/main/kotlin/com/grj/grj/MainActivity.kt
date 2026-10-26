package com.grj.grj

import android.content.Intent
import android.content.ContentValues
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.pdf.PdfDocument
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "grjoffice_apps/downloads"
    private val settingsChannel = "grjoffice_apps/settings"

    override fun onCreate(savedInstanceState: Bundle?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT) {
            WebView.enableSlowWholeDocumentDraw()
        }
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, downloadsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName")
                        if (bytes == null || fileName.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "bytes and fileName are required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val saved = saveFileToDownloads(bytes, fileName)
                            result.success(saved)
                        } catch (e: Exception) {
                            result.error("SAVE_FAILED", e.message, null)
                        }
                    }

                    "captureWebViewPdf" -> {
                        val fileName = call.argument<String>("fileName")
                        if (fileName.isNullOrBlank()) {
                            result.error("INVALID_ARGS", "fileName is required", null)
                            return@setMethodCallHandler
                        }
                        runOnUiThread {
                            try {
                                val webView = findWebView(window?.decorView?.rootView)
                                    ?: throw IllegalStateException("WebView not found")
                                val saved = captureWebViewToPdf(webView, fileName)
                                result.success(saved)
                            } catch (e: Exception) {
                                result.error("CAPTURE_FAILED", e.message, null)
                            }
                        }
                    }

                    else -> result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, settingsChannel)
            .setMethodCallHandler { call, result ->
                if (call.method == "openWirelessSettings") {
                    try {
                        startActivity(Intent(Settings.ACTION_WIRELESS_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        try {
                            startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                            result.success(true)
                        } catch (e2: Exception) {
                            result.error("OPEN_FAILED", e2.message, null)
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun findWebView(view: View?): WebView? {
        if (view == null) return null
        if (view is WebView) return view
        if (view is ViewGroup) {
            for (index in 0 until view.childCount) {
                findWebView(view.getChildAt(index))?.let { return it }
            }
        }
        return null
    }

    private fun captureWebViewToPdf(webView: WebView, fileName: String): String {
        webView.scrollTo(0, 0)

        val scale = webView.scale
        val width = when {
            webView.width > 0 -> webView.width
            webView.measuredWidth > 0 -> webView.measuredWidth
            else -> resources.displayMetrics.widthPixels
        }.coerceAtLeast(1)

        val contentHeight = (webView.contentHeight * scale).toInt().coerceAtLeast(webView.height)
        val height = contentHeight.coerceAtLeast(1)

        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.WHITE)
        webView.draw(canvas)

        val pdfDocument = PdfDocument()
        try {
            val pageInfo = PdfDocument.PageInfo.Builder(width, height, 1).create()
            val page = pdfDocument.startPage(pageInfo)
            page.canvas.drawBitmap(bitmap, 0f, 0f, null)
            pdfDocument.finishPage(page)

            val output = ByteArrayOutputStream()
            pdfDocument.writeTo(output)
            return saveFileToDownloads(output.toByteArray(), fileName)
        } finally {
            pdfDocument.close()
            bitmap.recycle()
        }
    }

    private fun saveFileToDownloads(bytes: ByteArray, fileName: String): String {
        val mimeType = when {
            fileName.endsWith(".pdf", ignoreCase = true) -> "application/pdf"
            fileName.endsWith(".png", ignoreCase = true) -> "image/png"
            fileName.endsWith(".webp", ignoreCase = true) -> "image/webp"
            else -> "image/jpeg"
        }

        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(
                    MediaStore.Downloads.RELATIVE_PATH,
                    Environment.DIRECTORY_DOWNLOADS + "/GRJ_Purchases"
                )
                put(MediaStore.Downloads.IS_PENDING, 1)
            }

            val resolver = applicationContext.contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IllegalStateException("Unable to create Downloads entry")

            resolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
                output.flush()
            } ?: throw IllegalStateException("Unable to open Downloads output stream")

            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)

            // Return content:// URI — guessed File(...) paths are not readable under
            // scoped storage and cause PDF viewers to open then immediately close.
            uri.toString()
        } else {
            @Suppress("DEPRECATION")
            val downloads = Environment.getExternalStoragePublicDirectory(
                Environment.DIRECTORY_DOWNLOADS
            )
            val folder = File(downloads, "GRJ_Purchases")
            if (!folder.exists() && !folder.mkdirs()) {
                throw IllegalStateException("Unable to create Downloads/GRJ_Purchases")
            }
            val file = File(folder, fileName)
            FileOutputStream(file).use { output ->
                output.write(bytes)
                output.flush()
            }
            file.absolutePath
        }
    }
}
