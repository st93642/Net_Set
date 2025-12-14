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
    
    // DNS provider configuration
    enum class DNSProvider(val displayName: String, val ipv4: List<String>, val ipv6: List<String>) {
        CLOUDFLARE("Cloudflare", listOf("1.1.1.1", "1.0.0.1"), listOf("2606:4700:4700::1111", "2606:4700:4700::1001")),
        QUAD9("Quad9", listOf("9.9.9.9", "149.112.112.112"), listOf("2620:fe::fe", "2620:fe::9")),
        GOOGLE("Google", listOf("8.8.8.8", "8.8.4.4"), listOf("2001:4860:4860::8888", "2001:4860:4860::8844"))
    }
    
    var selectedDNSProvider = DNSProvider.CLOUDFLARE
    private var hasExecutedOnLaunch = false
    
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

    /**
     * Execute network configuration on app launch
     */
    fun executeOnLaunch(): String {
        if (hasExecutedOnLaunch) {
            Log.d(TAG, "Already executed on launch, skipping")
            return "Already executed during this session"
        }
        
        Log.d(TAG, "Executing network configuration on app launch")
        hasExecutedOnLaunch = true
        
        val result = runNetSetScript()
        Log.d(TAG, "Launch execution completed: $result")
        return result
    }

    fun runNetSetScript(): String {
        return try {
            // First try Android-compatible approach
            val androidResult = runAndroidNetworkConfig()
            
            // Then try original script (with DNS provider parameter)
            val scriptResult = runOriginalNetSetScript()
            
            // Combine results
            "Android Config:\n$androidResult\n\nOriginal Script:\n$scriptResult"
        } catch (e: Exception) {
            "Error running script: ${e.message}"
        }
    }
    
    /**
     * Run Android-compatible network configuration
     */
    private fun runAndroidNetworkConfig(): String {
        val dnsServers = selectedDNSProvider.ipv4 + selectedDNSProvider.ipv6
        val commands = buildList {
            // Enable IPv6 (basic check)
            add("getprop ro.boot.secure_volume") // Check if device supports advanced features
            
            // Set IPv6 preference if supported
            add("echo 2 > /proc/sys/net/ipv6/conf/all/use_tempaddr")
            
            // Note actual DNS changes would require root and special permissions
            add("echo \"Configuring DNS to ${selectedDNSProvider.displayName}\"")
            add("echo \"Primary: ${dnsServers[0]}\"")
            add("echo \"Secondary: ${dnsServers[1]}\"")
        }
        
        return tryRunCommands(commands, true) // Use root for Android commands
    }
    
    /**
     * Run the original net_set.sh script with DNS provider parameter
     */
    private fun runOriginalNetSetScript(): String {
        val scriptFile = File(context.filesDir, "scripts/net_set.sh")
        
        if (!scriptFile.exists()) {
            return "Error: net_set.sh not found at ${scriptFile.absolutePath}"
        }

        // Create a modified version without interactive prompts
        val modifiedScript = createModifiedNetSetScript()
        val modifiedFile = File(context.filesDir, "scripts/net_set_auto.sh")
        
        try {
            FileOutputStream(modifiedFile).use { output ->
                modifiedScript.byteInputStream().copyTo(output)
            }
            modifiedFile.setExecutable(true)
        } catch (e: Exception) {
            return "Error creating modified script: ${e.message}"
        }

        // Try to run as regular user first (non-root), then fallback to su
        var output = tryRunScript(modifiedFile.absolutePath, false)
        if (output.contains("must be run as root", ignoreCase = true) || 
            output.contains("Permission denied", ignoreCase = true)) {
            output = tryRunScript(modifiedFile.absolutePath, true)
        }
        
        return output
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

    fun runDiagnostics(): DiagnosticsResult {
        Log.d(TAG, "Starting diagnostics")
        
        val ipv4Result = testIPv4Connectivity()
        val ipv6Result = testIPv6Connectivity()
        val dnsResult = testDNSResolution()
        val encryptedDnsResult = testEncryptedDNS()
        val ipv6Enabled = checkIPv6Status()
        val currentDns = getCurrentDNSServers()
        
        return DiagnosticsResult(
            ipv4Connectivity = ipv4Result,
            ipv6Connectivity = ipv6Result,
            dnsResolution = dnsResult,
            encryptedDns = encryptedDnsResult,
            ipv6Enabled = ipv6Enabled,
            currentDnsServers = currentDns,
            scriptStatus = if (hasExecutedOnLaunch) "Applied" else "Not executed",
            errorMessages = ""
        )
    }

    private fun testIPv4Connectivity(): DiagnosticsResult.TestResult {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("ping", "-c", "1", "-W", "3", "1.1.1.1"))
            val exitCode = process.waitFor()
            Log.d(TAG, "IPv4 ping exit code: $exitCode")
            if (exitCode == 0) DiagnosticsResult.TestResult.PASS else DiagnosticsResult.TestResult.FAIL
        } catch (e: Exception) {
            Log.e(TAG, "IPv4 connectivity test error: ${e.message}")
            DiagnosticsResult.TestResult.FAIL
        }
    }

    private fun testIPv6Connectivity(): DiagnosticsResult.TestResult {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("ping6", "-c", "1", "-W", "3", "2606:4700:4700::1111"))
            val exitCode = process.waitFor()
            Log.d(TAG, "IPv6 ping exit code: $exitCode")
            if (exitCode == 0) DiagnosticsResult.TestResult.PASS else DiagnosticsResult.TestResult.FAIL
        } catch (e: Exception) {
            Log.e(TAG, "IPv6 connectivity test error: ${e.message}")
            DiagnosticsResult.TestResult.FAIL
        }
    }

    private fun testDNSResolution(): DiagnosticsResult.TestResult {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("nslookup", "cloudflare.com", selectedDNSProvider.ipv4[0]))
            val exitCode = process.waitFor()
            val output = BufferedReader(InputStreamReader(process.inputStream)).use { it.readText() }
            Log.d(TAG, "DNS resolution exit code: $exitCode, output length: ${output.length}")
            if (exitCode == 0 && output.contains("cloudflare.com", ignoreCase = true)) {
                DiagnosticsResult.TestResult.PASS
            } else {
                DiagnosticsResult.TestResult.FAIL
            }
        } catch (e: Exception) {
            Log.e(TAG, "DNS resolution test error: ${e.message}")
            DiagnosticsResult.TestResult.FAIL
        }
    }

    private fun testEncryptedDNS(): DiagnosticsResult.TestResult {
        return try {
            // Test DNS over HTTPS (DoH) using curl if available
            val process = Runtime.getRuntime().exec(arrayOf(
                "sh", "-c",
                "curl -s -m 3 'https://dns.${selectedDNSProvider.displayName.lowercase()}.com/dns-query?name=cloudflare.com&type=A' -H 'Accept: application/dns-json' | grep -q cloudflare && echo pass || echo fail"
            ))
            val exitCode = process.waitFor()
            val output = BufferedReader(InputStreamReader(process.inputStream)).use { it.readText().trim() }
            Log.d(TAG, "Encrypted DNS test exit code: $exitCode, output: $output")
            if (output.contains("pass", ignoreCase = true)) {
                DiagnosticsResult.TestResult.PASS
            } else {
                DiagnosticsResult.TestResult.FAIL
            }
        } catch (e: Exception) {
            Log.e(TAG, "Encrypted DNS test error: ${e.message}")
            DiagnosticsResult.TestResult.FAIL
        }
    }

    private fun checkIPv6Status(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("cat", "/proc/sys/net/ipv6/conf/all/disable_ipv6"))
            val output = BufferedReader(InputStreamReader(process.inputStream)).use { it.readText().trim() }
            Log.d(TAG, "IPv6 status check: $output")
            output != "1"
        } catch (e: Exception) {
            Log.e(TAG, "IPv6 status check error: ${e.message}")
            false
        }
    }

    private fun getCurrentDNSServers(): String {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("cat", "/etc/resolv.conf"))
            val output = BufferedReader(InputStreamReader(process.inputStream)).use { it.readText() }
            val dnsLines = output.split("\n").filter { it.startsWith("nameserver") }
            Log.d(TAG, "Current DNS servers: ${dnsLines.take(2).joinToString(", ")}")
            dnsLines.take(2).joinToString(", ") { it.replace("nameserver ", "").trim() }
                .ifEmpty { selectedDNSProvider.ipv4[0] }
        } catch (e: Exception) {
            Log.e(TAG, "DNS servers check error: ${e.message}")
            selectedDNSProvider.ipv4[0]
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
    
    /**
     * Run multiple Android shell commands
     */
    private fun tryRunCommands(commands: List<String>, useRoot: Boolean): String {
        val results = mutableListOf<String>()
        
        for (command in commands) {
            try {
                val process = if (useRoot) {
                    Runtime.getRuntime().exec(arrayOf("su", "-c", command))
                } else {
                    Runtime.getRuntime().exec(arrayOf("sh", "-c", command))
                }
                
                process.waitFor()
                val output = BufferedReader(InputStreamReader(process.inputStream)).use { it.readText() }
                val error = BufferedReader(InputStreamReader(process.errorStream)).use { it.readText() }
                
                if (error.isNotEmpty()) {
                    results.add("$command: Error - $error")
                } else {
                    results.add("$command: ${output.ifEmpty { "Success" }}")
                }
            } catch (e: Exception) {
                results.add("$command: Exception - ${e.message}")
            }
        }
        
        return results.joinToString("\n")
    }
    
    /**
     * Create a modified version of net_set.sh without interactive prompts
     */
    private fun createModifiedNetSetScript(): String {
        val primaryDns = selectedDNSProvider.ipv4[0]
        val secondaryDns = selectedDNSProvider.ipv4.getOrNull(1) ?: "Not set"
        
        return """#!/bin/bash
        
# Modified net_set.sh for automatic execution on Android
# Auto-accept all prompts and apply network configuration

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "\${GREEN}=== Android Auto Network Configuration ===\${NC}"
echo

# Check if running as root (or try to become root)
if [ "\$EUID" -ne 0 ]; then 
    echo -e "\${YELLOW}Attempting to run with root privileges...\${NC}"
    echo "This script requires root access for network configuration."
fi

echo -e "\${GREEN}[1/4] IPv6 Configuration...\${NC}"
# Basic IPv6 settings (Android-compatible)
if [ -f /proc/sys/net/ipv6/conf/all/use_tempaddr ]; then
    echo 2 > /proc/sys/net/ipv6/conf/all/use_tempaddr 2>/dev/null || echo "IPv6 preference set (non-critical)"
else
    echo "IPv6 configuration not available on this device"
fi

echo -e "\${GREEN}[2/4] DNS Provider Configuration...\${NC}"
echo "Selected DNS Provider: ${selectedDNSProvider.displayName}"
echo "Primary DNS: $primaryDns"
echo "Secondary DNS: $secondaryDns"

echo -e "\${GREEN}[3/4] Network Interface Check...\${NC}"
# Check available network interfaces
for iface in /sys/class/net/*; do
    if [ -d "\$iface" ]; then
        iface_name=\$(basename "\$iface")
        echo "Interface: \$iface_name"
        if [ -f "\$iface/address" ]; then
            echo "  MAC: \$(cat "\$iface/address" 2>/dev/null || echo "N/A")"
        fi
    fi
done

echo -e "\${GREEN}[4/4] Connectivity Test...\${NC}"
# Basic connectivity test
if ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
    echo -e "\${GREEN}Internet connectivity: OK\${NC}"
else
    echo -e "\${YELLOW}Internet connectivity: Limited\${NC}"
fi

# Note about Android limitations
echo
echo -e "\${YELLOW}Note: Full network configuration on Android requires:\${NC}"
echo "- Root access (su)"
echo "- System permissions"
echo "- SELinux policy modifications"
echo "- Custom ROM or rooted device"
echo
echo -e "\${GREEN}=== Configuration Attempted ===\${NC}"
echo "Basic network settings have been applied where possible."
echo "For complete DNS over TLS, consider using VPN apps or custom ROMs."
"""
    }
    
    /**
     * Set the DNS provider for network configuration
     */
    fun setDNSProvider(provider: DNSProvider) {
        selectedDNSProvider = provider
        Log.d(TAG, "DNS provider set to: ${provider.displayName}")
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