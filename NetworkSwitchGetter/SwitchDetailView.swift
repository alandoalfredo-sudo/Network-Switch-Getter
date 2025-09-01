import SwiftUI

struct SwitchDetailView: View {
    let switchDevice: NetworkSwitch
    @ObservedObject var networkManager: NetworkDiscoveryManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingTroubleshooting = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // Overview Tab
                SwitchOverviewTab(switchDevice: switchDevice, networkManager: networkManager)
                    .tabItem {
                        Image(systemName: "info.circle")
                        Text("Overview")
                    }
                    .tag(0)
                
                // Ports Tab
                SwitchPortsTab(switchDevice: switchDevice)
                    .tabItem {
                        Image(systemName: "cable.connector")
                        Text("Ports")
                    }
                    .tag(1)
                
                // Troubleshooting Tab
                SwitchTroubleshootingTab(switchDevice: switchDevice, networkManager: networkManager)
                    .tabItem {
                        Image(systemName: "wrench.and.screwdriver")
                        Text("Diagnostics")
                    }
                    .tag(2)
            }
            .navigationTitle(switchDevice.hostname ?? switchDevice.ipAddress)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        networkManager.refreshSwitch(switchDevice)
                    }
                }
            }
        }
    }
}

// MARK: - Switch Overview Tab
struct SwitchOverviewTab: View {
    let switchDevice: NetworkSwitch
    @ObservedObject var networkManager: NetworkDiscoveryManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Status Card
                StatusCard(switchDevice: switchDevice)
                
                // Basic Information
                BasicInfoCard(switchDevice: switchDevice)
                
                // Network Information
                NetworkInfoCard(switchDevice: switchDevice)
                
                // Capabilities
                CapabilitiesCard(switchDevice: switchDevice)
                
                // Performance Metrics
                PerformanceCard(switchDevice: switchDevice)
            }
            .padding()
        }
    }
}

// MARK: - Status Card
struct StatusCard: View {
    let switchDevice: NetworkSwitch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "circle.fill")
                    .foregroundColor(Color(switchDevice.status.color))
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Status")
                        .font(.headline)
                    Text(switchDevice.status.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Last Seen")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(switchDevice.lastSeen, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Basic Info Card
struct BasicInfoCard: View {
    let switchDevice: NetworkSwitch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Basic Information")
                .font(.headline)
            
            VStack(spacing: 8) {
                InfoRow(label: "IP Address", value: switchDevice.ipAddress)
                InfoRow(label: "MAC Address", value: switchDevice.macAddress)
                
                if let hostname = switchDevice.hostname {
                    InfoRow(label: "Hostname", value: hostname)
                }
                
                if let vendor = switchDevice.vendor {
                    InfoRow(label: "Vendor", value: vendor)
                }
                
                if let model = switchDevice.model {
                    InfoRow(label: "Model", value: model)
                }
                
                if let firmwareVersion = switchDevice.firmwareVersion {
                    InfoRow(label: "Firmware", value: firmwareVersion)
                }
                
                if let portCount = switchDevice.portCount {
                    InfoRow(label: "Port Count", value: "\(portCount)")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Network Info Card
struct NetworkInfoCard: View {
    let switchDevice: NetworkSwitch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Network Information")
                .font(.headline)
            
            VStack(spacing: 8) {
                InfoRow(label: "IP Address", value: switchDevice.ipAddress)
                InfoRow(label: "MAC Address", value: switchDevice.macAddress)
                
                if let responseTime = switchDevice.responseTime {
                    InfoRow(label: "Response Time", value: "\(String(format: "%.1f", responseTime * 1000)) ms")
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Capabilities Card
struct CapabilitiesCard: View {
    let switchDevice: NetworkSwitch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Capabilities")
                .font(.headline)
            
            if switchDevice.capabilities.isEmpty {
                Text("No capabilities detected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(switchDevice.capabilities, id: \.self) { capability in
                        CapabilityBadge(capability: capability)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Capability Badge
struct CapabilityBadge: View {
    let capability: SwitchCapability
    
    var body: some View {
        HStack {
            Image(systemName: capabilityIcon(for: capability))
                .font(.caption)
            Text(capability.rawValue)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.2))
        .cornerRadius(6)
    }
    
    private func capabilityIcon(for capability: SwitchCapability) -> String {
        switch capability {
        case .snmp: return "gear"
        case .ssh: return "terminal"
        case .telnet: return "terminal"
        case .webInterface: return "globe"
        case .cdp: return "network"
        case .lldp: return "network"
        case .stp: return "tree"
        case .vlan: return "rectangle.3.group"
        case .qos: return "speedometer"
        case .poe: return "bolt"
        case .stacking: return "square.stack.3d.up"
        case .lacp: return "link"
        case .spanningTree: return "tree"
        case .portMirroring: return "eye"
        case .accessControl: return "lock"
        case .monitoring: return "chart.line.uptrend.xyaxis"
        }
    }
}

// MARK: - Performance Card
struct PerformanceCard: View {
    let switchDevice: NetworkSwitch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
            
            VStack(spacing: 8) {
                if let responseTime = switchDevice.responseTime {
                    InfoRow(label: "Response Time", value: "\(String(format: "%.1f", responseTime * 1000)) ms")
                }
                
                InfoRow(label: "Uptime", value: "Unknown")
                InfoRow(label: "CPU Usage", value: "Unknown")
                InfoRow(label: "Memory Usage", value: "Unknown")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Switch Ports Tab
struct SwitchPortsTab: View {
    let switchDevice: NetworkSwitch
    @State private var ports: [PortInfo] = []
    
    var body: some View {
        NavigationView {
            List(ports) { port in
                PortRowView(port: port)
            }
            .navigationTitle("Ports")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadPorts()
            }
            .refreshable {
                loadPorts()
            }
        }
    }
    
    private func loadPorts() {
        // Simulate loading ports - in a real implementation, this would query the switch
        ports = (1...(switchDevice.portCount ?? 24)).map { portNumber in
            PortInfo(
                portNumber: portNumber,
                status: [.up, .down, .disabled].randomElement() ?? .unknown,
                speed: ["100M", "1G", "10G"].randomElement(),
                duplex: ["Full", "Half"].randomElement(),
                vlan: "VLAN\(Int.random(in: 1...10))",
                connectedDevice: Bool.random() ? "Device \(Int.random(in: 1...100))" : nil,
                macAddress: Bool.random() ? generateRandomMAC() : nil
            )
        }
    }
    
    private func generateRandomMAC() -> String {
        let hexChars = "0123456789ABCDEF"
        return (0..<6).map { _ in
            (0..<2).map { _ in hexChars.randomElement()! }.joined()
        }.joined(separator: ":")
    }
}

// MARK: - Port Row View
struct PortRowView: View {
    let port: PortInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Port \(port.portNumber)")
                    .font(.headline)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(port.status.color))
                        .frame(width: 8, height: 8)
                    
                    Text(port.status.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                if let speed = port.speed {
                    Text(speed)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
                
                if let duplex = port.duplex {
                    Text(duplex)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
                
                if let vlan = port.vlan {
                    Text(vlan)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
            if let connectedDevice = port.connectedDevice {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connected Device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(connectedDevice)
                        .font(.subheadline)
                    
                    if let macAddress = port.macAddress {
                        Text(macAddress)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Switch Troubleshooting Tab
struct SwitchTroubleshootingTab: View {
    let switchDevice: NetworkSwitch
    @ObservedObject var networkManager: NetworkDiscoveryManager
    @State private var isRunningTests = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Run Tests Button
                Button(action: {
                    isRunningTests = true
                    networkManager.runTroubleshooting(for: switchDevice)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isRunningTests = false
                    }
                }) {
                    HStack {
                        if isRunningTests {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "play.circle.fill")
                        }
                        Text(isRunningTests ? "Running Tests..." : "Run Diagnostics")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                .disabled(isRunningTests)
                .padding(.horizontal)
                
                // Test Results
                if networkManager.troubleshootingResults.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "wrench.and.screwdriver")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Test Results")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Run diagnostics to check the health and connectivity of this switch.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(networkManager.troubleshootingResults) { result in
                        TroubleshootingResultRow(result: result)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Diagnostics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Troubleshooting Result Row
struct TroubleshootingResultRow: View {
    let result: TroubleshootingResult
    
    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            Image(systemName: statusIcon(for: result.status))
                .foregroundColor(Color(result.status.color))
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.testType.rawValue)
                    .font(.headline)
                
                Text(result.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(result.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(result.status.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(result.status.color).opacity(0.2))
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
    
    private func statusIcon(for status: TestStatus) -> String {
        switch status {
        case .passed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .skipped: return "minus.circle.fill"
        }
    }
}

// MARK: - Preview
struct SwitchDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleSwitch = NetworkSwitch(
            ipAddress: "192.168.1.100",
            macAddress: "00:11:22:33:44:55",
            hostname: "switch-01",
            vendor: "Cisco",
            model: "Catalyst 2960",
            firmwareVersion: "15.2.4",
            portCount: 24,
            capabilities: [.snmp, .ssh, .webInterface, .vlan]
        )
        
        SwitchDetailView(switchDevice: sampleSwitch, networkManager: NetworkDiscoveryManager())
    }
}
