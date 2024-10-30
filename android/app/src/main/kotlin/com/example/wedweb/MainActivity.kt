package com.example.wedweb

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.InputStream
import java.io.OutputStream

class MainActivity: FlutterActivity()  {
    private val CHANNEL = "com.example/storage"
    private var sourceFilePath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "copyFileToExternalStorage") {
                sourceFilePath = call.argument<String>("sourceFilePath")
                val targetFileName = call.argument<String>("targetFileName")
                if (sourceFilePath != null && targetFileName != null) {
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
                        putExtra(Intent.EXTRA_TITLE, targetFileName)
                    }
                    startActivityForResult(intent, CREATE_FILE_REQUEST_CODE)
                    result.success(true) // Indicate that the request has been made
                } else {
                    result.error("INVALID_ARGUMENT", "Invalid arguments", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == CREATE_FILE_REQUEST_CODE && resultCode == RESULT_OK) {
            val uri: Uri? = data?.data
            if (uri != null && sourceFilePath != null) {
                try {
                    val inputStream: InputStream? = contentResolver.openInputStream(Uri.fromFile(File(sourceFilePath!!)))
                    val outputStream: OutputStream? = contentResolver.openOutputStream(uri)
                    inputStream?.use { input ->
                        outputStream?.use { output ->
                            input.copyTo(output)
                        }
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    companion object {
        private const val CREATE_FILE_REQUEST_CODE = 1
    }
}
