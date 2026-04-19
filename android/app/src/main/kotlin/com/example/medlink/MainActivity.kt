package com.example.medlink

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterFragmentActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.medlink/downloads",
        ).setMethodCallHandler { call, result ->
            if (call.method != "savePdfToDownloads") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            try {
                val fileNameArg = call.argument<String>("fileName")
                if (fileNameArg.isNullOrBlank()) {
                    result.error("bad_args", "fileName required", null)
                    return@setMethodCallHandler
                }
                val bytes = readBytes(call) ?: run {
                    result.error("bad_args", "bytes required or invalid encoding", null)
                    return@setMethodCallHandler
                }
                val friendly = savePdfToDownloads(fileNameArg, bytes)
                result.success(friendly)
            } catch (e: Exception) {
                result.error("save_failed", e.message ?: e.toString(), null)
            }
        }
    }

    /** Flutter may send ByteArray or ArrayList<Int> for Uint8List depending on codec path. */
    private fun readBytes(call: MethodCall): ByteArray? {
        call.argument<ByteArray>("bytes")?.let { return it }
        @Suppress("UNCHECKED_CAST")
        val list = call.argument<ArrayList<*>>("bytes") ?: return null
        val out = ByteArray(list.size)
        for (i in list.indices) {
            out[i] = ((list[i] as Number).toInt() and 0xff).toByte()
        }
        return out
    }

    /**
     * Saves to user-visible Downloads (Files app): Download/Medlink/<file>.pdf
     * API 29+: MediaStore + [MediaStore.Downloads.getContentUri] (preferred over EXTERNAL_CONTENT_URI on many devices).
     */
    private fun savePdfToDownloads(fileNameArg: String, bytes: ByteArray): String {
        val safeName = if (fileNameArg.endsWith(".pdf", ignoreCase = true)) {
            fileNameArg
        } else {
            "$fileNameArg.pdf"
        }

        val resolver = applicationContext.contentResolver

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, safeName)
                put(MediaStore.MediaColumns.MIME_TYPE, "application/pdf")
                put(
                    MediaStore.MediaColumns.RELATIVE_PATH,
                    "${Environment.DIRECTORY_DOWNLOADS}/Medlink",
                )
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val primary = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            var uri = resolver.insert(primary, values)
            if (uri == null) {
                @Suppress("DEPRECATION")
                uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            }
            uri = uri ?: throw IllegalStateException("MediaStore insert failed (Downloads)")

            val stream = resolver.openOutputStream(uri)
                ?: throw IllegalStateException("Could not open output stream")
            stream.use { out ->
                out.write(bytes)
                out.flush()
            }

            val reveal = ContentValues().apply {
                put(MediaStore.MediaColumns.IS_PENDING, 0)
            }
            resolver.update(uri, reveal, null, null)

            return "Download/Medlink/$safeName"
        }

        @Suppress("DEPRECATION")
        val downloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
        val dir = File(downloads, "Medlink")
        if (!dir.exists() && !dir.mkdirs()) {
            throw IllegalStateException("Cannot create ${dir.absolutePath}")
        }
        val file = File(dir, safeName)
        FileOutputStream(file).use { it.write(bytes) }
        return file.absolutePath
    }
}
