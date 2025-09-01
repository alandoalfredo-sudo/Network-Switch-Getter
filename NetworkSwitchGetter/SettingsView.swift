import SwiftUI

struct SettingsView: View {
    @ObservedObject var networkManager: NetworkDiscoveryManager
    @State private var showingAbout = false
    @State private var showingExportOptions = false
    
    var body: some View {
        NavigationView {
            List {
                // Network Settings Section
                Section("Network Discovery") {
                    NavigationLink("Scan Settings") {
                        ScanSettingsView(networkManager: networkManager)
                    }
                    
                    NavigationLink("Protocol Settings") {
                        ProtocolSettingsView(networkManager: networkManager)
                    }
                }
                
                // Data Management Section
                Section("Data Management") {
                    Button("Export Results") {
                        showingExportOptions = true
                    }
                    
                    Button("Clear All Data") {
                        networkManager.clearResults()
                    }
                    .foregroundColor(.red)
                }
                
                // App Information Section
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("About") {
                        showingAbout = true
                    }
                }
                
                // Help Section
                Section("Help & Support") {
                    NavigationLink("User Guide") {
                        UserGuideView()
                    }
                    
                    NavigationLink("Troubleshooting Guide") {
                        TroubleshootingGuideView()
                    }
                    
                    Button("Contact Support") {
                        // Open email or support link
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .actionSheet(isPresented: $showingExportOptions) {
            ActionSheet(
                title: Text("Export Options"),
                message: Text("Choose how to export your network discovery results"),
                buttons: [
                    .default(Text("Export as CSV")) {
                        exportAsCSV()
                    },
                    .default(Text("Export as JSON")) {
                        exportAsJSON()
                    },
                    .cancel()
                ]
            )
        }
    }
    
    private func exportAsCSV() {
        // Implement CSV export
    }
    
    private func exportAsJSON() {
        // Implement JSON export
    }
}

// MARK: - Scan Settings View
struct ScanSettingsView: View {
    @ObservedObject var networkManager: NetworkDiscoveryManager
    
    var body: some View {
        Form {
            Section("Scan Range") {
                HStack {
                    Text("Network Range")
                    Spacer()
                    TextField("192.168.1.0/24", text: $networkManager.settings.scanRange)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 150)
                }
            }
            
            Section("Performance") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Timeout")
                        Spacer()
                        Text("\(String(format: "%.1f", networkManager.settings.timeout))s")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $networkManager.settings.timeout,
                        in: 1...30,
                        step: 0.5
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Max Concurrent Scans")
                        Spacer()
                        Text("\(networkManager.settings.maxConcurrentScans)")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(networkManager.settings.maxConcurrentScans) },
                            set: { networkManager.settings.maxConcurrentScans = Int($0) }
                        ),
                        in: 1...100,
                        step: 1
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Retry Count")
                        Spacer()
                        Text("\(networkManager.settings.retryCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: Binding(
                            get: { Double(networkManager.settings.retryCount) },
                            set: { networkManager.settings.retryCount = Int($0) }
                        ),
                        in: 1...5,
                        step: 1
                    )
                }
            }
            
            Section("Custom Ports") {
                ForEach(networkManager.settings.customPorts.indices, id: \.self) { index in
                    HStack {
                        Text("Port \(index + 1)")
                        Spacer()
                        TextField("Port", value: $networkManager.settings.customPorts[index], format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 80)
                    }
                }
                
                Button("Add Port") {
                    networkManager.settings.customPorts.append(80)
                }
            }
        }
        .navigationTitle("Scan Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Protocol Settings View
struct ProtocolSettingsView: View {
    @ObservedObject var networkManager: NetworkDiscoveryManager
    
    var body: some View {
        Form {
            Section("Discovery Protocols") {
                Toggle("Enable SNMP", isOn: $networkManager.settings.enableSNMP)
                
                Toggle("Enable SSH", isOn: $networkManager.settings.enableSSH)
                
                Toggle("Enable Web Interface", isOn: $networkManager.settings.enableWebInterface)
            }
            
            Section("SNMP Settings") {
                HStack {
                    Text("Community String")
                    Spacer()
                    TextField("public", text: .constant("public"))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                }
                
                HStack {
                    Text("SNMP Version")
                    Spacer()
                    Picker("Version", selection: .constant("2c")) {
                        Text("v1").tag("1")
                        Text("v2c").tag("2c")
                        Text("v3").tag("3")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 150)
                }
            }
            
            Section("SSH Settings") {
                HStack {
                    Text("Default Username")
                    Spacer()
                    TextField("admin", text: .constant("admin"))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 120)
                }
                
                HStack {
                    Text("Default Port")
                    Spacer()
                    TextField("22", value: .constant(22), format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
            }
            
            Section("Web Interface Settings") {
                HStack {
                    Text("HTTP Port")
                    Spacer()
                    TextField("80", value: .constant(80), format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
                
                HStack {
                    Text("HTTPS Port")
                    Spacer()
                    TextField("443", value: .constant(443), format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                }
            }
        }
        .navigationTitle("Protocol Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Icon
                Image(systemName: "network")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                VStack(spacing: 8) {
                    Text("Network Switch Getter")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.headline)
                    
                    Text("Network Switch Getter is a comprehensive iOS application for discovering, monitoring, and troubleshooting network switches and devices. It provides real-time network scanning, device identification, and diagnostic capabilities.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Features")
                        .font(.headline)
                    
                    FeatureRow(icon: "network", title: "Network Discovery", description: "Automatically discover switches and network devices")
                    FeatureRow(icon: "wrench.and.screwdriver", title: "Troubleshooting", description: "Comprehensive diagnostic tools and health checks")
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Monitoring", description: "Real-time monitoring and performance metrics")
                    FeatureRow(icon: "gear", title: "Management", description: "Configure and manage network devices")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - User Guide View
struct UserGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GuideSection(
                    title: "Getting Started",
                    content: "Network Switch Getter helps you discover and manage network switches on your local network. Follow these steps to get started:"
                )
                
                GuideStep(number: 1, title: "Check Network Connection", description: "Ensure your iOS device is connected to the same network as the switches you want to discover.")
                
                GuideStep(number: 2, title: "Start Network Scan", description: "Tap the 'Start Scan' button in the Discovery tab to begin scanning for network devices.")
                
                GuideStep(number: 3, title: "Review Results", description: "View discovered switches in the list. Tap on any switch to see detailed information.")
                
                GuideSection(
                    title: "Understanding Results",
                    content: "Each discovered switch shows important information including IP address, status, capabilities, and response time."
                )
                
                GuideSection(
                    title: "Troubleshooting",
                    content: "Use the Troubleshooting tab to run diagnostic tests on discovered switches. This helps identify connectivity issues and device health."
                )
            }
            .padding()
        }
        .navigationTitle("User Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Troubleshooting Guide View
struct TroubleshootingGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GuideSection(
                    title: "Common Issues",
                    content: "Here are solutions to common problems you might encounter:"
                )
                
                TroubleshootingItem(
                    issue: "No switches discovered",
                    solution: "Check your network connection and ensure you're on the same network as the switches. Verify the scan range in settings."
                )
                
                TroubleshootingItem(
                    issue: "Slow scan performance",
                    solution: "Reduce the number of concurrent scans in settings or increase the timeout value."
                )
                
                TroubleshootingItem(
                    issue: "Switch shows as offline",
                    solution: "Check if the switch is powered on and connected to the network. Try running diagnostic tests."
                )
                
                TroubleshootingItem(
                    issue: "Missing device information",
                    solution: "Enable SNMP, SSH, or web interface protocols in settings to gather more detailed information."
                )
            }
            .padding()
        }
        .navigationTitle("Troubleshooting Guide")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Guide Section
struct GuideSection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Guide Step
struct GuideStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Troubleshooting Item
struct TroubleshootingItem: View {
    let issue: String
    let solution: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                Text(issue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Text(solution)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.leading, 24)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(networkManager: NetworkDiscoveryManager())
    }
}
