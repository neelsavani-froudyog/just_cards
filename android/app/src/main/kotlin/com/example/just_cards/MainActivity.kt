package com.forudyog.justcards

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity : FlutterActivity() {
    private val downloadsChannel = "com.forudyog.justcards/downloads"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            downloadsChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method != "saveFileToDownloadFolder") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val folderName = call.argument<String>("folderName") ?: "JustCards"
            val fileName = call.argument<String>("fileName")
            val bytes = call.argument<ByteArray>("bytes")
            val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
            if (fileName.isNullOrBlank() || bytes == null) {
                result.error("bad_args", "fileName and bytes required", null)
                return@setMethodCallHandler
            }
            try {
                val path = saveFileToPublicDownloads(folderName, fileName, bytes, mimeType)
                result.success(path)
            } catch (e: Exception) {
                result.error("save_failed", e.message, null)
            }
        }
    }

    private fun saveFileToPublicDownloads(
        folderName: String,
        fileName: String,
        bytes: ByteArray,
        mimeType: String,
    ): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    "${Environment.DIRECTORY_DOWNLOADS}/$folderName",
                )
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IOException("Could not create file in Downloads")
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: throw IOException("Could not write file")
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "${Environment.DIRECTORY_DOWNLOADS}/$folderName/$fileName"
        }

        @Suppress("DEPRECATION")
        val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val folder = File(downloadsDir, folderName)
        if (!folder.exists() && !folder.mkdirs()) {
            throw IOException("Could not create folder in Downloads")
        }
        val file = File(folder, fileName)
        file.writeBytes(bytes)
        return file.absolutePath
    }
}
