import SwiftUI

// MARK: - AI Configuration View
struct AIConfigurationView: View {
    @StateObject private var aiIntelligence = AINetworkIntelligence()
    @State private var selectedTab = 0
    @State private var showingVPNConfig = false
    @State private var showingTrunkConfig = false
    
    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                // AI Recommendations Tab
                AIRecommendationsView(aiIntelligence: aiIntelligence)
                    .tabItem {
                        Image(systemName: "brain.head.profile")
                        Text("AI Insights")
                    }
                    .tag(0)
                
                // VPN Configuration Tab
                VPNConfigurationView(aiIntelligence: aiIntelligence)
                    .tabItem {
                        Image(systemName: "shield.lefthalf.filled")
                        Text("VPN Config")
                    }
                    .tag(1)
                
                // Trunk Port Configuration Tab
                TrunkPortConfigurationView(aiIntelligence: aiIntelligence)
                    .tabItem {
                        Image(systemName: "cable.connector.horizontal")
                        Text("Trunk Ports")
                    }
                    .tag(2)
            }
            .navigationTitle("AI Configuration")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - AI Recommendations View
struct AIRecommendationsView: View {
    @ObservedObject var aiIntelligence: AINetworkIntelligence
    @State private var isAnalyzing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Analysis Status
                if aiIntelligence.isAnalyzing {
                    AnalysisProgressView(progress: aiIntelligence.analysisProgress)
                }
                
                // Network Health Summary
                NetworkHealthSummaryCard(aiIntelligence: aiIntelligence)
                
                // AI Recommendations
                if aiIntelligence.recommendations.isEmpty && !aiIntelligence.isAnalyzing {
                    EmptyRecommendationsView()
                } else {
                    RecommendationsListView(recommendations: aiIntelligence.recommendations)
                }
                
                // Action Buttons
                ActionButtonsView(aiIntelligence: aiIntelligence, isAnalyzing: $isAnalyzing)
            }
            .padding()
        }
        .navigationTitle("AI Network Intelligence")
        .navigationBarTitleDisplayMode(.large)
    }
}

// MARK: - Analysis Progress View
struct AnalysisProgressView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Analysis in Progress")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("Analyzing network performance and generating recommendations...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            
            Text("\(Int(progress * 100))% Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Network Health Summary Card
struct NetworkHealthSummaryCard: View {
    @ObservedObject var aiIntelligence: AINetworkIntelligence
    
    private var overallHealth: NetworkHealth {
        // Calculate overall health based on recommendations
        let criticalCount = aiIntelligence.recommendations.filter { $0.priority == .critical }.count
        let highCount = aiIntelligence.recommendations.filter { $0.priority == .high }.count
        
        if criticalCount > 0 {
            return .critical
        } else if highCount > 2 {
            return .poor
        } else if highCount > 0 {
            return .fair
        } else {
            return .good
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Network Health")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(overallHealth.rawValue)
                        .font(.subheadline)
                        .foregroundColor(Color(overallHealth.color))
                }
                
                Spacer()
                
                Circle()
                    .fill(Color(overallHealth.color))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text("\(overallHealth.score)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
            }
            
            HStack(spacing: 20) {
                HealthMetricView(
                    title: "Critical",
                    count: aiIntelligence.recommendations.filter { $0.priority == .critical }.count,
                    color: .red
                )
                
                HealthMetricView(
                    title: "High",
                    count: aiIntelligence.recommendations.filter { $0.priority == .high }.count,
                    color: .orange
                )
                
                HealthMetricView(
                    title: "Medium",
                    count: aiIntelligence.recommendations.filter { $0.priority == .medium }.count,
                    color: .blue
                )
                
                HealthMetricView(
                    title: "Low",
                    count: aiIntelligence.recommendations.filter { $0.priority == .low }.count,
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Health Metric View
struct HealthMetricView: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Empty Recommendations View
struct EmptyRecommendationsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No AI Recommendations")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Run AI analysis to get intelligent recommendations for optimizing your network configuration.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Recommendations List View
struct RecommendationsListView: View {
    let recommendations: [AINetworkRecommendation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Recommendations")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVStack(spacing: 12) {
                ForEach(recommendations) { recommendation in
                    RecommendationCard(recommendation: recommendation)
                }
            }
        }
    }
}

// MARK: - Recommendation Card
struct RecommendationCard: View {
    let recommendation: AINetworkRecommendation
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(recommendation.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(recommendation.priority.rawValue)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(recommendation.priority.color).opacity(0.2))
                        .cornerRadius(6)
                    
                    Text("\(Int(recommendation.confidence * 100))% confidence")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Description
            Text(recommendation.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Action and Impact
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Recommended Action:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(recommendation.action)
                            .font(.subheadline)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated Impact:")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text(recommendation.estimatedImpact)
                            .font(.subheadline)
                    }
                }
            }
            
            // Expand/Collapse Button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(isExpanded ? "Show Less" : "Show More")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Action Buttons View
struct ActionButtonsView: View {
    @ObservedObject var aiIntelligence: AINetworkIntelligence
    @Binding var isAnalyzing: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                isAnalyzing = true
                Task {
                    // Simulate analysis with sample data
                    await aiIntelligence.analyzeNetworkPerformance(
                        switches: [],
                        metrics: []
                    )
                    isAnalyzing = false
                }
            }) {
                HStack {
                    if isAnalyzing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "brain.head.profile")
                    }
                    Text(isAnalyzing ? "Analyzing..." : "Run AI Analysis")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(isAnalyzing)
            
            HStack(spacing: 12) {
                Button("Apply All") {
                    // Apply all recommendations
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
                
                Button("Clear All") {
                    aiIntelligence.recommendations.removeAll()
                }
                .foregroundColor(.red)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - VPN Configuration View
struct VPNConfigurationView: View {
    @ObservedObject var aiIntelligence: AINetworkIntelligence
    @State private var showingAddVPN = false
    
    var body: some View {
        NavigationView {
            List {
                Section("AI-Generated VPN Configurations") {
                    ForEach(aiIntelligence.vpnConfigurations) { config in
                        VPNConfigurationRow(config: config)
                    }
                }
                
                Section("Quick Actions") {
                    Button("Generate AI VPN Config") {
                        showingAddVPN = true
                    }
                    
                    Button("Test All VPN Connections") {
                        // Test all VPN connections
                    }
                }
            }
            .navigationTitle("VPN Configuration")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddVPN) {
                AddVPNConfigurationView(aiIntelligence: aiIntelligence)
            }
        }
    }
}

// MARK: - VPN Configuration Row
struct VPNConfigurationRow: View {
    let config: VPNConfiguration
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(config.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(config.type.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Circle()
                        .fill(config.isActive ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Text(config.isActive ? "Active" : "Inactive")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    
                    DetailRow(label: "Server", value: config.serverAddress)
                    DetailRow(label: "Encryption", value: config.encryption.rawValue)
                    DetailRow(label: "Authentication", value: config.authentication.rawValue)
                    
                    if let bandwidthLimit = config.bandwidthLimit {
                        DetailRow(label: "Bandwidth Limit", value: "\(String(format: "%.1f", bandwidthLimit)) Mbps")
                    }
                }
            }
            
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                Text(isExpanded ? "Show Less" : "Show More")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add VPN Configuration View
struct AddVPNConfigurationView: View {
    @ObservedObject var aiIntelligence: AINetworkIntelligence
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var selectedType = VPNConfiguration.VPNType.ipsec
    @State private var serverAddress = ""
    @State private var username = ""
    @State private var password = ""
    @State private var selectedEncryption = VPNConfiguration.EncryptionType.aes256
    @State private var selectedAuth = VPNConfiguration.AuthenticationType.certificate
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Configuration Name", text: $name)
                    TextField("Server Address", text: $serverAddress)
                }
                
                Section("VPN Settings") {
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
                    
                    Picker("Authentication", selection: $selectedAuth) {
                        ForEach(VPNConfiguration.AuthenticationType.allCases, id: \.self) { auth in
                            Text(auth.rawValue).tag(auth)
                        }
                    }
                }
                
                Section("Credentials") {
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                }
            }
            .navigationTitle("Add VPN Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let config = VPNConfiguration(
                            name: name,
                            type: selectedType,
                            serverAddress: serverAddress,
                            username: username,
                            password: password,
                            encryption: selectedEncryption,
                            authentication: selectedAuth,
                            isActive: false,
                            bandwidthLimit: nil,
                            latencyThreshold: nil
                        )
                        
                        Task {
                            await aiIntelligence.applyVPNConfiguration(config)
                        }
                        
                        dismiss()
                    }
                    .disabled(name.isEmpty || serverAddress.isEmpty)
                }
            }
        }
    }
}

// MARK: - Trunk Port Configuration View
struct TrunkPortConfigurationView: View {
    @ObservedObject var aiIntelligence: AINetworkIntelligence
    @State private var showingAddTrunk = false
    
    var body: some View {
        NavigationView {
            List {
                Section("AI-Optimized Trunk Ports") {
                    ForEach(aiIntelligence.trunkPortConfigurations) { config in
                        TrunkPortConfigurationRow(config: config)
                    }
                }
                
                Section("Quick Actions") {
                    Button("Generate AI Trunk Config") {
                        showingAddTrunk = true
                    }
                    
                    Button("Optimize All Trunk Ports") {
                        // Optimize all trunk ports
                    }
                }
            }
            .navigationTitle("Trunk Port Configuration")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingAddTrunk) {
                AddTrunkPortConfigurationView(aiIntelligence: aiIntelligence)
            }
        }
    }
}

// MARK: - Trunk Port Configuration Row
struct TrunkPortConfigurationRow: View {
    let config: TrunkPortConfiguration
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Port \(config.portNumber)")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text(config.trunkingProtocol.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Circle()
                        .fill(config.isActive ? .green : .red)
                        .frame(width: 8, height: 8)
                    
                    Text("\(String(format: "%.1f", config.utilization))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    Divider()
                    
                    DetailRow(label: "Native VLAN", value: "\(config.nativeVlan)")
                    DetailRow(label: "Allowed VLANs", value: config.allowedVlans.map(String.init).joined(separator: ", "))
                    DetailRow(label: "Load Balancing", value: config.loadBalancing.rawValue)
                    DetailRow(label: "Bandwidth", value: "\(String(format: "%.1f", config.bandwidth)) Mbps")
                }
            }
            
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                Text(isExpanded ? "Show Less" : "Show More")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Trunk Port Configuration View
struct AddTrunkPortConfigurationView: View {
    @ObservedObject var aiIntelligence: AINetworkIntelligence
    @Environment(\.dismiss) private var dismiss
    
    @State private var portNumber = 1
    @State private var nativeVlan = 1
    @State private var allowedVlans = "1,10,20,30"
    @State private var selectedProtocol = TrunkPortConfiguration.TrunkingProtocol.dot1q
    @State private var selectedLoadBalancing = TrunkPortConfiguration.LoadBalancingType.srcDstMac
    
    var body: some View {
        NavigationView {
            Form {
                Section("Port Configuration") {
                    Stepper("Port Number: \(portNumber)", value: $portNumber, in: 1...48)
                    Stepper("Native VLAN: \(nativeVlan)", value: $nativeVlan, in: 1...4094)
                }
                
                Section("Trunking Settings") {
                    Picker("Trunking Protocol", selection: $selectedProtocol) {
                        ForEach(TrunkPortConfiguration.TrunkingProtocol.allCases, id: \.self) { protocol in
                            Text(protocol.rawValue).tag(protocol)
                        }
                    }
                    
                    Picker("Load Balancing", selection: $selectedLoadBalancing) {
                        ForEach(TrunkPortConfiguration.LoadBalancingType.allCases, id: \.self) { lb in
                            Text(lb.rawValue).tag(lb)
                        }
                    }
                }
                
                Section("VLAN Configuration") {
                    TextField("Allowed VLANs (comma-separated)", text: $allowedVlans)
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
                        let vlanList = allowedVlans.split(separator: ",").compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }
                        
                        let config = TrunkPortConfiguration(
                            portNumber: portNumber,
                            vlans: vlanList,
                            allowedVlans: vlanList,
                            nativeVlan: nativeVlan,
                            trunkingProtocol: selectedProtocol,
                            loadBalancing: selectedLoadBalancing,
                            isActive: true,
                            bandwidth: 1000.0,
                            utilization: 0.0
                        )
                        
                        Task {
                            await aiIntelligence.applyTrunkPortConfiguration(config)
                        }
                        
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Detail Row
struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Preview
struct AIConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        AIConfigurationView()
    }
}
