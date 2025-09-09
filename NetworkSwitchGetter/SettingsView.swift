import SwiftUI

struct SettingsView: View {
    @ObservedObject var networkManager: NetworkDiscoveryManager
    @StateObject private var monitoringManager = NetworkMonitoringManager()
    @State private var showingAbout = false
    @State private var showingExportOptions = false
    @State private var showingAISettings = false
    @State private var showingWidgetSettings = false
    
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
                
                // AI Configuration Section
                Section("AI Configuration") {
                    NavigationLink("AI Settings") {
                        AISettingsView()
                    }
                    
                    NavigationLink("VPN Configuration") {
                        VPNConfigurationView()
                    }
                    
                    NavigationLink("Trunk Port Management") {
                        TrunkPortManagementView()
                    }
                }
                
                // Widget Configuration Section
                Section("Widget Configuration") {
                    NavigationLink("Widget Settings") {
                        WidgetSettingsView()
                    }
                    
                    NavigationLink("Customize Display") {
                        WidgetCustomizationView()
                    }
                }
                
                // Data Management Section
                Section("Data Management") {
                    Button("Export Discovery Data") {
                        exportDiscoveryData()
                    }
                    
                    Button("Export Monitoring Data") {
                        exportMonitoringData()
                    }
                    
                    Button("Export All Data") {
                        exportAllData()
                    }
                    
                    Button("Clear All Data") {
                        clearAllData()
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
    
    private func exportDiscoveryData() {
        let data = networkManager.discoveredSwitches
        let csvData = generateCSV(from: data)
        shareData(csvData, filename: "network_discovery.csv")
    }
    
    private func exportMonitoringData() {
        if let data = monitoringManager.exportAllData() {
            shareData(data, filename: "network_monitoring.json")
        }
    }
    
    private func exportAllData() {
        let discoveryData = networkManager.discoveredSwitches
        let monitoringData = monitoringManager.exportAllData()
        
        let combinedData: [String: Any] = [
            "discovery": discoveryData,
            "monitoring": monitoringData ?? Data()
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: combinedData, options: .prettyPrinted) {
            shareData(jsonData, filename: "network_data_export.json")
        }
    }
    
    private func clearAllData() {
        networkManager.clearResults()
        monitoringManager.clearAllData()
    }
    
    private func generateCSV(from switches: [NetworkSwitch]) -> Data {
        var csvString = "IP Address,Hostname,Vendor,Model,Status,Response Time,Capabilities\n"
        
        for switchDevice in switches {
            let capabilities = switchDevice.capabilities.map { $0.rawValue }.joined(separator: ";")
            csvString += "\(switchDevice.ipAddress),\(switchDevice.hostname ?? ""),\(switchDevice.vendor ?? ""),\(switchDevice.model ?? ""),\(switchDevice.status.rawValue),\(switchDevice.responseTime ?? 0),\(capabilities)\n"
        }
        
        return csvString.data(using: .utf8) ?? Data()
    }
    
    private func shareData(_ data: Data, filename: String) {
        // This would typically use UIActivityViewController
        // For now, we'll just log the action
        print("Sharing data: \(filename) (\(data.count) bytes)")
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

// MARK: - AI Settings View
struct AISettingsView: View {
    @State private var enableAIAnalysis = true
    @State private var analysisInterval: Double = 300 // 5 minutes
    @State private var confidenceThreshold: Double = 0.7
    @State private var enablePredictiveAnalytics = true
    @State private var enableAutoRemediation = false
    
    var body: some View {
        Form {
            Section("AI Analysis") {
                Toggle("Enable AI Analysis", isOn: $enableAIAnalysis)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Analysis Interval")
                        Spacer()
                        Text("\(Int(analysisInterval / 60)) minutes")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $analysisInterval,
                        in: 60...3600,
                        step: 60
                    )
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Confidence Threshold")
                        Spacer()
                        Text("\(String(format: "%.1f", confidenceThreshold))")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $confidenceThreshold,
                        in: 0.1...1.0,
                        step: 0.1
                    )
                }
            }
            
            Section("Advanced Features") {
                Toggle("Predictive Analytics", isOn: $enablePredictiveAnalytics)
                Toggle("Auto Remediation", isOn: $enableAutoRemediation)
            }
            
            Section("AI Recommendations") {
                Text("AI will analyze your network performance and provide intelligent recommendations for optimization.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("AI Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - VPN Configuration View
struct VPNConfigurationView: View {
    @State private var vpnConfigurations: [VPNConfiguration] = []
    @State private var showingAddVPN = false
    
    var body: some View {
        List {
            ForEach(vpnConfigurations) { config in
                VPNConfigurationRow(config: config)
            }
            
            Button("Add VPN Configuration") {
                showingAddVPN = true
            }
        }
        .navigationTitle("VPN Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddVPN) {
            AddVPNConfigurationView { newConfig in
                vpnConfigurations.append(newConfig)
            }
        }
    }
}

// MARK: - VPN Configuration Row
struct VPNConfigurationRow: View {
    let config: VPNConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(config.name)
                    .font(.headline)
                
                Spacer()
                
                Circle()
                    .fill(config.isActive ? .green : .gray)
                    .frame(width: 12, height: 12)
            }
            
            Text("\(config.type.rawValue) - \(config.serverAddress)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Encryption: \(config.encryption.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add VPN Configuration View
struct AddVPNConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (VPNConfiguration) -> Void
    
    @State private var name = ""
    @State private var serverAddress = ""
    @State private var username = ""
    @State private var password = ""
    @State private var selectedType = VPNConfiguration.VPNType.openvpn
    @State private var selectedEncryption = VPNConfiguration.EncryptionType.aes256
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Configuration Name", text: $name)
                    TextField("Server Address", text: $serverAddress)
                }
                
                Section("Authentication") {
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                }
                
                Section("Protocol Settings") {
                    Picker("VPN Type", selection: $selectedType) {
                        ForEach(VPNConfiguration.VPNType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    
                    Picker("Encryption", selection: $selectedEncryption) {
                        ForEach(VPNConfiguration.EncryptionType.allCases, id: \.self) { encryption in
                            Text(encryption.rawValue).tag(encryption)
                        }
                    }
                }
            }
            .navigationTitle("Add VPN")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newConfig = VPNConfiguration(
                            name: name,
                            type: selectedType,
                            serverAddress: serverAddress,
                            username: username,
                            password: password,
                            encryption: selectedEncryption,
                            authentication: .usernamePassword,
                            isActive: false,
                            bandwidthLimit: nil,
                            latencyThreshold: nil
                        )
                        onSave(newConfig)
                        dismiss()
                    }
                    .disabled(name.isEmpty || serverAddress.isEmpty)
                }
            }
        }
    }
}

// MARK: - Trunk Port Management View
struct TrunkPortManagementView: View {
    @State private var trunkConfigurations: [TrunkPortConfiguration] = []
    @State private var showingAddTrunk = false
    
    var body: some View {
        List {
            ForEach(trunkConfigurations) { config in
                TrunkPortConfigurationRow(config: config)
            }
            
            Button("Add Trunk Configuration") {
                showingAddTrunk = true
            }
        }
        .navigationTitle("Trunk Port Management")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddTrunk) {
            AddTrunkPortConfigurationView { newConfig in
                trunkConfigurations.append(newConfig)
            }
        }
    }
}

// MARK: - Trunk Port Configuration Row
struct TrunkPortConfigurationRow: View {
    let config: TrunkPortConfiguration
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Port \(config.portNumber)")
                    .font(.headline)
                
                Spacer()
                
                Circle()
                    .fill(config.isActive ? .green : .gray)
                    .frame(width: 12, height: 12)
            }
            
            Text("Protocol: \(config.trunkingProtocol.rawValue)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("VLANs: \(config.vlans.map(String.init).joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("Utilization: \(String(format: "%.1f", config.utilization))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Trunk Port Configuration View
struct AddTrunkPortConfigurationView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (TrunkPortConfiguration) -> Void
    
    @State private var portNumber = 1
    @State private var vlans: [Int] = []
    @State private var nativeVlan = 1
    @State private var selectedProtocol = TrunkPortConfiguration.TrunkingProtocol.dot1q
    @State private var selectedLoadBalancing = TrunkPortConfiguration.LoadBalancingType.srcMac
    
    var body: some View {
        NavigationView {
            Form {
                Section("Port Configuration") {
                    Stepper("Port Number: \(portNumber)", value: $portNumber, in: 1...48)
                }
                
                Section("VLAN Configuration") {
                    TextField("VLANs (comma-separated)", text: Binding(
                        get: { vlans.map(String.init).joined(separator: ", ") },
                        set: { vlans = $0.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) } }
                    ))
                    
                    Stepper("Native VLAN: \(nativeVlan)", value: $nativeVlan, in: 1...4094)
                }
                
                Section("Protocol Settings") {
                    Picker("Trunking Protocol", selection: $selectedProtocol) {
                        ForEach(TrunkPortConfiguration.TrunkingProtocol.allCases, id: \.self) { protocol in
                            Text(protocol.rawValue).tag(protocol)
                        }
                    }
                    
                    Picker("Load Balancing", selection: $selectedLoadBalancing) {
                        ForEach(TrunkPortConfiguration.LoadBalancingType.allCases, id: \.self) { balancing in
                            Text(balancing.rawValue).tag(balancing)
                        }
                    }
                }
            }
            .navigationTitle("Add Trunk Port")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let newConfig = TrunkPortConfiguration(
                            portNumber: portNumber,
                            vlans: vlans,
                            allowedVlans: vlans,
                            nativeVlan: nativeVlan,
                            trunkingProtocol: selectedProtocol,
                            loadBalancing: selectedLoadBalancing,
                            isActive: false,
                            bandwidth: 1000.0,
                            utilization: 0.0
                        )
                        onSave(newConfig)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Widget Settings View
struct WidgetSettingsView: View {
    @State private var refreshInterval: Double = 300 // 5 minutes
    @State private var showAlerts = true
    @State private var showBandwidth = true
    @State private var showLatency = true
    @State private var showDeviceCount = true
    
    var body: some View {
        Form {
            Section("Refresh Settings") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Refresh Interval")
                        Spacer()
                        Text("\(Int(refreshInterval / 60)) minutes")
                            .foregroundColor(.secondary)
                    }
                    
                    Slider(
                        value: $refreshInterval,
                        in: 60...1800,
                        step: 60
                    )
                }
            }
            
            Section("Display Options") {
                Toggle("Show Alerts", isOn: $showAlerts)
                Toggle("Show Bandwidth", isOn: $showBandwidth)
                Toggle("Show Latency", isOn: $showLatency)
                Toggle("Show Device Count", isOn: $showDeviceCount)
            }
            
            Section("Widget Sizes") {
                Text("Available in Small, Medium, and Large sizes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Widget Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Widget Customization View
struct WidgetCustomizationView: View {
    @State private var selectedWidgetSize = "Medium"
    @State private var showNetworkHealth = true
    @State private var showTopDevices = true
    @State private var showAlerts = true
    @State private var maxDevicesToShow = 3
    
    var body: some View {
        Form {
            Section("Widget Size") {
                Picker("Size", selection: $selectedWidgetSize) {
                    Text("Small").tag("Small")
                    Text("Medium").tag("Medium")
                    Text("Large").tag("Large")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section("Content Options") {
                Toggle("Show Network Health", isOn: $showNetworkHealth)
                Toggle("Show Top Devices", isOn: $showTopDevices)
                Toggle("Show Alerts", isOn: $showAlerts)
                
                if showTopDevices {
                    Stepper("Max Devices: \(maxDevicesToShow)", value: $maxDevicesToShow, in: 1...5)
                }
            }
            
            Section("Preview") {
                WidgetPreviewView(
                    size: selectedWidgetSize,
                    showNetworkHealth: showNetworkHealth,
                    showTopDevices: showTopDevices,
                    showAlerts: showAlerts,
                    maxDevices: maxDevicesToShow
                )
            }
        }
        .navigationTitle("Customize Widget")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Widget Preview View
struct WidgetPreviewView: View {
    let size: String
    let showNetworkHealth: Bool
    let showTopDevices: Bool
    let showAlerts: Bool
    let maxDevices: Int
    
    var body: some View {
        VStack {
            Text("Widget Preview")
                .font(.headline)
            
            // This would show a preview of the widget
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: size == "Large" ? 200 : size == "Medium" ? 150 : 100)
                .overlay(
                    VStack {
                        if showNetworkHealth {
                            Text("Network Health: Good")
                                .font(.caption)
                        }
                        
                        if showTopDevices {
                            Text("Top \(maxDevices) Devices")
                                .font(.caption)
                        }
                        
                        if showAlerts {
                            Text("2 Alerts")
                                .font(.caption)
                        }
                    }
                )
        }
        .padding()
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(networkManager: NetworkDiscoveryManager())
    }
}
