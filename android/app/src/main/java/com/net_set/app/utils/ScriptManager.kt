package com.net_set.app.utils

import android.content.Context
import android.util.Log
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.io.BufferedReader
import java.io.InputStreamReader

class ScriptManager(private val context: Context) {
    private val TAG = "ScriptManager"
    
    init {
        copyScriptsToAppDirectory()
    }
    
    fun copyScriptsToAppDirectory() {
        try {
            val appDir = File(context.filesDir, "scripts")
            if (!appDir.exists()) {
                appDir.mkdirs()
            }

            // Copy net_set.sh
            copyAssetFile("net_set.sh", File(appDir, "net_set.sh"))
            // Copy network-verify.sh
            copyAssetFile("network-verify.sh", File(appDir, "network-verify.sh"))
            // Copy net_set.ps1
            copyAssetFile("net_set.ps1", File(appDir, "net_set.ps1"))

            // Make shell scripts executable
            File(appDir, "net_set.sh").setExecutable(true)
            File(appDir, "network-verify.sh").setExecutable(true)

            Log.d(TAG, "Scripts copied successfully to ${appDir.absolutePath}")
        } catch (e: Exception) {
            Log.e(TAG, "Error copying scripts", e)
        }
    }

    fun runNetSetScript(): String {
        return try {
            val scriptFile = File(context.filesDir, "scripts/net_set.sh")
            
            if (!scriptFile.exists()) {
                return "Error: net_set.sh not found at ${scriptFile.absolutePath}"
            }

            // Try to run as regular user first (non-root), then fallback to su
            var output = tryRunScript(scriptFile.absolutePath, false)
            if (output.contains("must be run as root", ignoreCase = true)) {
                output = tryRunScript(scriptFile.absolutePath, true)
            }
            
            output
        } catch (e: Exception) {
            "Error running script: ${e.message}"
        }
    }

    fun runNetworkVerifyScript(): String {
        return try {
            val scriptFile = File(context.filesDir, "scripts/network-verify.sh")
            
            if (!scriptFile.exists()) {
                return "Error: network-verify.sh not found at ${scriptFile.absolutePath}"
            }

            tryRunScript(scriptFile.absolutePath, false)
        } catch (e: Exception) {
            "Error running diagnostics: ${e.message}"
        }
    }

    private fun tryRunScript(scriptPath: String, useRoot: Boolean): String {
        val process = if (useRoot) {
            Runtime.getRuntime().exec(arrayOf("su", "-c", scriptPath))
        } else {
            Runtime.getRuntime().exec(arrayOf("/bin/sh", scriptPath))
        }
        
        process.waitFor()
        
        val output = BufferedReader(InputStreamReader(process.inputStream)).use { it.readText() }
        val error = BufferedReader(InputStreamReader(process.errorStream)).use { it.readText() }
        
        return if (error.isNotEmpty()) {
            "Error: $error"
        } else {
            output.ifEmpty { "Script completed successfully" }
        }
    }

    private fun copyAssetFile(assetName: String, destFile: File) {
        try {
            val inputStream: InputStream = context.assets.open(assetName)
            val outputStream = FileOutputStream(destFile)
            
            inputStream.copyTo(outputStream)
            inputStream.close()
            outputStream.close()
            
            Log.d(TAG, "Copied $assetName to ${destFile.absolutePath}")
        } catch (e: Exception) {
            Log.e(TAG, "Error copying $assetName", e)
            throw e
        }
    }
}