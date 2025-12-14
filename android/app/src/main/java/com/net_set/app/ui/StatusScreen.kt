package com.net_set.app.ui

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.dp
import com.net_set.app.utils.DiagnosticsResult
import com.net_set.app.utils.ScriptManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

@Composable
fun StatusScreen() {
    val context = androidx.compose.ui.platform.LocalContext.current
    val scriptManager = remember { ScriptManager(context) }
    val coroutineScope = rememberCoroutineScope()
    var isLoading by remember { mutableStateOf(false) }
    var scriptStatus by remember { mutableStateOf("Ready") }
    var showOutput by remember { mutableStateOf(false) }
    var scriptOutput by remember { mutableStateOf("") }
    var hasLaunchExecuted by remember { mutableStateOf(false) }
    var selectedProviderIndex by remember { mutableStateOf(0) }
    var diagnosticsResult by remember { mutableStateOf<DiagnosticsResult?>(null) }
    var isDiagnosticsLoading by remember { mutableStateOf(false) }
    
    val dnsProviders = remember {
        listOf(
            ScriptManager.DNSProvider.CLOUDFLARE,
            ScriptManager.DNSProvider.QUAD9,
            ScriptManager.DNSProvider.GOOGLE
        )
    }

    LaunchedEffect(Unit) {
        // Execute network configuration on app launch
            scriptStatus = "Executing on launch..."
            isLoading = true
            
            val result = withContext(Dispatchers.IO) {
                scriptManager.executeOnLaunch()
            }
            
            scriptOutput = result
            scriptStatus = "Launch execution completed"
            isLoading = false
            hasLaunchExecuted = true
            showOutput = true
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
            .verticalScroll(rememberScrollState()),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Header
        Text(
            text = "Net_Set Android",
            style = MaterialTheme.typography.headlineMedium,
            color = MaterialTheme.colorScheme.primary
        )
        
        Text(
            text = "Network configuration and diagnostics",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        // Applied Settings Section
        AppliedSettingsCard(diagnosticsResult, scriptStatus)

        // DNS Provider Selection
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.Dns,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "DNS Provider",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    dnsProviders.forEachIndexed { index, provider ->
                        FilterChip(
                            onClick = {
                                selectedProviderIndex = index
                                scriptManager.setDNSProvider(provider)
                            },
                            label = {
                                Text(provider.displayName)
                            },
                            selected = selectedProviderIndex == index,
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "Selected: ${dnsProviders[selectedProviderIndex].displayName}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }

        // Action Buttons
        if (!isLoading && !isDiagnosticsLoading) {
            Button(
                onClick = {
                    isLoading = true
                    scriptStatus = "Running..."
                    
                    coroutineScope.launch {
                        val result = withContext(Dispatchers.IO) {
                            scriptManager.runNetSetScript()
                        }
                        
                        scriptOutput = result
                        scriptStatus = "Completed"
                        isLoading = false
                        showOutput = true
                    }
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.Settings, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Run Network Configuration")
            }

            Button(
                onClick = {
                    isDiagnosticsLoading = true
                    
                    coroutineScope.launch {
                        val result = withContext(Dispatchers.IO) {
                            scriptManager.runDiagnostics()
                        }
                        
                        diagnosticsResult = result
                        isDiagnosticsLoading = false
                    }
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.NetworkCheck, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Run Diagnostics")
            }

            OutlinedButton(
                onClick = {
                    isLoading = true
                    scriptStatus = "Running legacy diagnostics..."
                    
                    coroutineScope.launch {
                        val result = withContext(Dispatchers.IO) {
                            scriptManager.runNetworkVerifyScript()
                        }
                        
                        scriptOutput = result
                        scriptStatus = "Legacy diagnostics completed"
                        isLoading = false
                        showOutput = true
                    }
                },
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.Info, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Run Network Verify Script")
            }
        } else {
            // Loading state
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(32.dp),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        }

        // Diagnostics Results
        if (diagnosticsResult != null) {
            DiagnosticsCard(diagnosticsResult!!)
        }

        // Script Output
        if (showOutput && scriptOutput.isNotEmpty()) {
            Card(
                modifier = Modifier.fillMaxWidth(),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Script Output",
                            style = MaterialTheme.typography.titleMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        TextButton(
                            onClick = { showOutput = false }
                        ) {
                            Text("Hide")
                        }
                    }
                    
                    Spacer(modifier = Modifier.height(8.dp))
                    
                    Text(
                        text = scriptOutput,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }

        // Information Card
        Card(
            modifier = Modifier.fillMaxWidth(),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Default.Info,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Information",
                        style = MaterialTheme.typography.titleMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                }
                
                Spacer(modifier = Modifier.height(8.dp))
                
                Text(
                    text = "This app automatically executes network configuration scripts on launch. Network settings are applied using the selected DNS provider. Note: Full features require root access for system-level DNS configuration.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
    }
}

@Composable
fun AppliedSettingsCard(diagnosticsResult: DiagnosticsResult?, scriptStatus: String) {
    Card(
        modifier = Modifier.fillMaxWidth()
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Applied Settings",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }

            Divider()

            SettingRow(
                label = "Script Status",
                value = diagnosticsResult?.scriptStatus ?: scriptStatus
            )

            SettingRow(
                label = "Current DNS",
                value = diagnosticsResult?.currentDnsServers ?: "Unknown"
            )

            SettingRow(
                label = "IPv6 Status",
                value = if (diagnosticsResult?.ipv6Enabled == true) "Enabled" else "Disabled"
            )
        }
    }
}

@Composable
fun SettingRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
fun DiagnosticsCard(result: DiagnosticsResult) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    Icons.Default.NetworkCheck,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Diagnostics Results",
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurface
                )
            }

            Divider()

            DiagnosticTestRow(
                test = "IPv4 Connectivity",
                result = result.ipv4Connectivity
            )

            DiagnosticTestRow(
                test = "IPv6 Connectivity",
                result = result.ipv6Connectivity
            )

            DiagnosticTestRow(
                test = "DNS Resolution",
                result = result.dnsResolution
            )

            DiagnosticTestRow(
                test = "Encrypted DNS",
                result = result.encryptedDns
            )

            if (result.errorMessages.isNotEmpty()) {
                Divider()
                Text(
                    text = "Errors:",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
                Text(
                    text = result.errorMessages,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.error
                )
            }
        }
    }
}

@Composable
fun DiagnosticTestRow(test: String, result: DiagnosticsResult.TestResult) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = test,
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface
        )
        Text(
            text = when (result) {
                DiagnosticsResult.TestResult.PASS -> "✓ Pass"
                DiagnosticsResult.TestResult.FAIL -> "✗ Fail"
                DiagnosticsResult.TestResult.PENDING -> "⏳ Pending"
            },
            style = MaterialTheme.typography.bodySmall,
            color = when (result) {
                DiagnosticsResult.TestResult.PASS -> MaterialTheme.colorScheme.primary
                DiagnosticsResult.TestResult.FAIL -> MaterialTheme.colorScheme.error
                DiagnosticsResult.TestResult.PENDING -> MaterialTheme.colorScheme.outline
            }
        )
    }
}
