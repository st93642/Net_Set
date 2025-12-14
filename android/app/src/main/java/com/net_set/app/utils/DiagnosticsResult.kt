package com.net_set.app.utils

data class DiagnosticsResult(
    val ipv4Connectivity: TestResult = TestResult.PENDING,
    val ipv6Connectivity: TestResult = TestResult.PENDING,
    val dnsResolution: TestResult = TestResult.PENDING,
    val encryptedDns: TestResult = TestResult.PENDING,
    val ipv6Enabled: Boolean = false,
    val currentDnsServers: String = "Unknown",
    val scriptStatus: String = "Not executed",
    val errorMessages: String = ""
) {
    enum class TestResult {
        PENDING, PASS, FAIL
    }
    
    fun getDisplayText(result: TestResult): String {
        return when (result) {
            TestResult.PENDING -> "⏳ Pending"
            TestResult.PASS -> "✓ Pass"
            TestResult.FAIL -> "✗ Fail"
        }
    }
}
