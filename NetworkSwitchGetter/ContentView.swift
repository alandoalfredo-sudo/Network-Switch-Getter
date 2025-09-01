import SwiftUI

struct ContentView: View {
    @StateObject private var networkManager = NetworkDiscoveryManager()
    @StateObject private var monitoringManager = NetworkMonitoringManager()
    @StateObject private var aiIntelligence = AINetworkIntelligence()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    @State private var selectedSwitch: NetworkSwitch?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Discovery Tab
            DiscoveryView(networkManager: networkManager, selectedSwitch: $selectedSwitch)
                .tabItem {
                    Image(systemName: "network")
                    Text("Discovery")
                }
                .tag(0)
            
            // Analytics Dashboard Tab
            NetworkAnalyticsDashboard()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Analytics")
                }
                .tag(1)
            
            // AI Configuration Tab
            AIConfigurationView()
                .tabItem {
                    Image(systemName: "brain.head.profile")
                    Text("AI Config")
                }
                .tag(2)
            
            // Troubleshooting Tab
            TroubleshootingView(networkManager: networkManager)
                .tabItem {
                    Image(systemName: "wrench.and.screwdriver")
                    Text("Troubleshoot")
                }
                .tag(3)
            
            // Settings Tab
            SettingsView(networkManager: networkManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
        }
        .sheet(item: $selectedSwitch) { switchDevice in
            SwitchDetailView(switchDevice: switchDevice, networkManager: networkManager)
        }
        .environmentObject(monitoringManager)
        .environmentObject(aiIntelligence)
    }
}

// MARK: - Discovery View
struct DiscoveryView: View {
    @ObservedObject var networkManager: NetworkDiscoveryManager
    @Binding var selectedSwitch: NetworkSwitch?
    @State private var searchText = ""
    
    var filteredSwitches: [NetworkSwitch] {
        if searchText.isEmpty {
            return networkManager.discoveredSwitches
        } else {
            return networkManager.discoveredSwitches.filter { switchDevice in
                switchDevice.ipAddress.localizedCaseInsensitiveContains(searchText) ||
                switchDevice.hostname?.localizedCaseInsensitiveContains(searchText) == true ||
                switchDevice.vendor?.localizedCaseInsensitiveContains(searchText) == true ||
                switchDevice.model?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Network Interface Info
                if let interface = networkManager.currentNetworkInterface {
                    NetworkInterfaceCard(interface: interface)
                        .padding(.horizontal)
                        .padding(.top, 8)
                }
                
                // Scan Controls
                ScanControlsView(networkManager: networkManager)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Progress Bar
                if networkManager.isScanning {
                    ProgressView(value: networkManager.scanProgress)
                        .progressViewStyle(LinearProgressViewStyle())
                        .padding(.horizontal)
                }
                
                // Search Bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Results
                if networkManager.discoveredSwitches.isEmpty && !networkManager.isScanning {
                    EmptyStateView()
                } else {
                    SwitchListView(
                        switches: filteredSwitches,
                        selectedSwitch: $selectedSwitch
                    )
                }
            }
            .navigationTitle("Network Discovery")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear") {
                        networkManager.clearResults()
                    }
                    .disabled(networkManager.discoveredSwitches.isEmpty)
                }
            }
        }
    }
}

// MARK: - Network Interface Card
struct NetworkInterfaceCard: View {
    let interface: NetworkInterface
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "wifi")
                    .foregroundColor(.blue)
                Text("Current Network")
                    .font(.headline)
                Spacer()
                Circle()
                    .fill(interface.isActive ? .green : .red)
                    .frame(width: 8, height: 8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Interface:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(interface.name)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("IP Address:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(interface.ipAddress)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Subnet:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(interface.subnetMask)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Scan Controls
struct ScanControlsView: View {
    @ObservedObject var networkManager: NetworkDiscoveryManager
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                if networkManager.isScanning {
                    networkManager.stopNetworkScan()
                } else {
                    networkManager.startNetworkScan()
                }
            }) {
                HStack {
                    Image(systemName: networkManager.isScanning ? "stop.circle.fill" : "play.circle.fill")
                    Text(networkManager.isScanning ? "Stop Scan" : "Start Scan")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(networkManager.isScanning ? Color.red : Color.blue)
                .cornerRadius(8)
            }
            .disabled(networkManager.currentNetworkInterface == nil)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Found: \(networkManager.discoveredSwitches.count) devices")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if networkManager.isScanning {
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search switches...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Switch List View
struct SwitchListView: View {
    let switches: [NetworkSwitch]
    @Binding var selectedSwitch: NetworkSwitch?
    
    var body: some View {
        List(switches) { switchDevice in
            SwitchRowView(switchDevice: switchDevice)
                .onTapGesture {
                    selectedSwitch = switchDevice
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button("Refresh") {
                        // Refresh logic would go here
                    }
                    .tint(.blue)
                    
                    Button("Delete") {
                        // Delete logic would go here
                    }
                    .tint(.red)
                }
        }
        .listStyle(PlainListStyle())
    }
}

// MARK: - Switch Row View
struct SwitchRowView: View {
    let switchDevice: NetworkSwitch
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(switchDevice.ipAddress)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let hostname = switchDevice.hostname {
                        Text(hostname)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    StatusIndicator(status: switchDevice.status)
                    
                    if let responseTime = switchDevice.responseTime {
                        Text("\(String(format: "%.1f", responseTime * 1000))ms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack {
                if let vendor = switchDevice.vendor {
                    Text(vendor)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
                
                if let model = switchDevice.model {
                    Text(model)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(4)
                }
                
                if let portCount = switchDevice.portCount {
                    Text("\(portCount) ports")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Spacer()
            }
            
            if !switchDevice.capabilities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(switchDevice.capabilities, id: \.self) { capability in
                            Text(capability.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(.systemGray5))
                                .cornerRadius(3)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Status Indicator
struct StatusIndicator: View {
    let status: SwitchStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color(status.color))
                .frame(width: 8, height: 8)
            
            Text(status.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "network")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Switches Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Start a network scan to discover switches and network devices on your network.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
