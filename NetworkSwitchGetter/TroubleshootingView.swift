import SwiftUI

struct TroubleshootingView: View {
    @ObservedObject var networkManager: NetworkDiscoveryManager
    @State private var selectedSwitch: NetworkSwitch?
    @State private var isRunningGlobalTests = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if networkManager.discoveredSwitches.isEmpty {
                    EmptyTroubleshootingView()
                } else {
                    // Switch Selection
                    SwitchSelectionView(
                        switches: networkManager.discoveredSwitches,
                        selectedSwitch: $selectedSwitch
                    )
                    
                    if let selectedSwitch = selectedSwitch {
                        // Troubleshooting Controls
                        TroubleshootingControlsView(
                            switchDevice: selectedSwitch,
                            networkManager: networkManager,
                            isRunningTests: $isRunningGlobalTests
                        )
                        
                        // Test Results
                        TroubleshootingResultsView(
                            results: networkManager.troubleshootingResults
                        )
                    }
                }
            }
            .navigationTitle("Troubleshooting")
            .navigationBarTitleDisplayMode(.large)
            .padding()
        }
    }
}

// MARK: - Empty Troubleshooting View
struct EmptyTroubleshootingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Switches to Troubleshoot")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Discover network switches first to run diagnostic tests and troubleshoot connectivity issues.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Switch Selection View
struct SwitchSelectionView: View {
    let switches: [NetworkSwitch]
    @Binding var selectedSwitch: NetworkSwitch?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Switch")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(switches) { switchDevice in
                        SwitchSelectionCard(
                            switchDevice: switchDevice,
                            isSelected: selectedSwitch?.id == switchDevice.id
                        ) {
                            selectedSwitch = switchDevice
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
}

// MARK: - Switch Selection Card
struct SwitchSelectionCard: View {
    let switchDevice: NetworkSwitch
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(switchDevice.ipAddress)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    StatusIndicator(status: switchDevice.status)
                }
                
                if let hostname = switchDevice.hostname {
                    Text(hostname)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let vendor = switchDevice.vendor {
                    Text(vendor)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let responseTime = switchDevice.responseTime {
                        Text("\(String(format: "%.1f", responseTime * 1000))ms")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("\(switchDevice.capabilities.count) capabilities")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(width: 200)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Troubleshooting Controls View
struct TroubleshootingControlsView: View {
    let switchDevice: NetworkSwitch
    @ObservedObject var networkManager: NetworkDiscoveryManager
    @Binding var isRunningTests: Bool
    @State private var selectedTests: Set<TroubleshootingTest> = Set(TroubleshootingTest.allCases)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Diagnostic Tests")
                .font(.headline)
            
            // Test Selection
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(TroubleshootingTest.allCases, id: \.self) { test in
                    TestSelectionButton(
                        test: test,
                        isSelected: selectedTests.contains(test)
                    ) {
                        if selectedTests.contains(test) {
                            selectedTests.remove(test)
                        } else {
                            selectedTests.insert(test)
                        }
                    }
                }
            }
            
            // Run Tests Button
            Button(action: {
                runSelectedTests()
            }) {
                HStack {
                    if isRunningTests {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.circle.fill")
                    }
                    Text(isRunningTests ? "Running Tests..." : "Run Selected Tests")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(selectedTests.isEmpty ? Color.gray : Color.blue)
                .cornerRadius(10)
            }
            .disabled(selectedTests.isEmpty || isRunningTests)
            
            // Quick Actions
            HStack(spacing: 12) {
                Button("Select All") {
                    selectedTests = Set(TroubleshootingTest.allCases)
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Button("Clear All") {
                    selectedTests.removeAll()
                }
                .font(.caption)
                .foregroundColor(.blue)
                
                Spacer()
            }
        }
    }
    
    private func runSelectedTests() {
        isRunningTests = true
        networkManager.runTroubleshooting(for: switchDevice)
        
        // Simulate test completion
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            isRunningTests = false
        }
    }
}

// MARK: - Test Selection Button
struct TestSelectionButton: View {
    let test: TroubleshootingTest
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: testIcon(for: test))
                    .font(.caption)
                
                Text(test.rawValue)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.blue.opacity(0.2) : Color(.systemGray5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func testIcon(for test: TroubleshootingTest) -> String {
        switch test {
        case .ping: return "network"
        case .portScan: return "magnifyingglass"
        case .snmpQuery: return "gear"
        case .sshConnection: return "terminal"
        case .webInterface: return "globe"
        case .dnsResolution: return "globe"
        case .arpTable: return "table"
        case .routingTable: return "map"
        case .interfaceStatus: return "wifi"
        case .bandwidthTest: return "speedometer"
        }
    }
}

// MARK: - Troubleshooting Results View
struct TroubleshootingResultsView: View {
    let results: [TroubleshootingResult]
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Test Results")
                    .font(.headline)
                
                Spacer()
                
                if !results.isEmpty {
                    Button("Details") {
                        showingDetails.toggle()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            if results.isEmpty {
                Text("No test results available. Run diagnostic tests to see results.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(results) { result in
                        TroubleshootingResultCard(result: result, showDetails: showingDetails)
                    }
                }
            }
        }
    }
}

// MARK: - Troubleshooting Result Card
struct TroubleshootingResultCard: View {
    let result: TroubleshootingResult
    let showDetails: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: statusIcon(for: result.status))
                    .foregroundColor(Color(result.status.color))
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.testType.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(result.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(showDetails ? nil : 2)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(result.status.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(result.status.color).opacity(0.2))
                        .cornerRadius(4)
                    
                    Text(result.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if showDetails && !result.details.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    
                    ForEach(Array(result.details.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(result.details[key] ?? "")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
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

// MARK: - Network Health Summary
struct NetworkHealthSummary: View {
    let results: [TroubleshootingResult]
    
    private var healthScore: Int {
        let totalTests = results.count
        guard totalTests > 0 else { return 0 }
        
        let passedTests = results.filter { $0.status == .passed }.count
        return Int((Double(passedTests) / Double(totalTests)) * 100)
    }
    
    private var healthStatus: (color: Color, text: String) {
        switch healthScore {
        case 80...100:
            return (.green, "Excellent")
        case 60..<80:
            return (.orange, "Good")
        case 40..<60:
            return (.yellow, "Fair")
        default:
            return (.red, "Poor")
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Network Health")
                    .font(.headline)
                
                Spacer()
                
                Text("\(healthScore)%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(healthStatus.color)
            }
            
            HStack {
                Text(healthStatus.text)
                    .font(.subheadline)
                    .foregroundColor(healthStatus.color)
                
                Spacer()
                
                Text("\(results.filter { $0.status == .passed }.count)/\(results.count) tests passed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: Double(healthScore), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: healthStatus.color))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct TroubleshootingView_Previews: PreviewProvider {
    static var previews: some View {
        TroubleshootingView(networkManager: NetworkDiscoveryManager())
    }
}
