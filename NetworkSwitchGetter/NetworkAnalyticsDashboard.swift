import SwiftUI

// MARK: - Network Analytics Dashboard
@available(macOS 11.0, *)
struct NetworkAnalyticsDashboard: View {
    @StateObject private var monitoringManager = NetworkMonitoringManager()
    @State private var selectedTimeRange: TimeRange = .hour
    @State private var selectedMetric: MetricType = .bandwidth
    @State private var showingExportSheet = false
    @State private var exportData: Data?
    
    enum TimeRange: String, CaseIterable {
        case hour = "1 Hour"
        case day = "1 Day"
        case week = "1 Week"
        case month = "1 Month"
        
        var duration: TimeInterval {
            switch self {
            case .hour: return 3600
            case .day: return 86400
            case .week: return 604800
            case .month: return 2592000
            }
        }
    }
    
    enum MetricType: String, CaseIterable {
        case bandwidth = "Bandwidth"
        case latency = "Latency"
        case performance = "Performance"
        case utilization = "Port Utilization"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Controls
                headerControls
                
                // Metric Selection
                metricSelection
                
                // Time Range Selection
                timeRangeSelection
                
                // Charts Section
                chartsSection
                
                Spacer()
            }
            .navigationTitle("Network Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Export Data") {
                            exportAllData()
                        }
                        Button("Clear Data") {
                            monitoringManager.clearAllData()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView(data: exportData)
            }
        }
        .environmentObject(monitoringManager)
    }
    
    // MARK: - Header Controls
    private var headerControls: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Network Health")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(healthColor)
                        .frame(width: 12, height: 12)
                    
                    Text(healthStatus)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Monitoring")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("", isOn: $monitoringManager.isMonitoring)
                    .labelsHidden()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Metric Selection
    private var metricSelection: some View {
        Picker("Metric", selection: $selectedMetric) {
            ForEach(MetricType.allCases, id: \.self) { metric in
                Text(metric.rawValue).tag(metric)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    // MARK: - Time Range Selection
    private var timeRangeSelection: some View {
        Picker("Time Range", selection: $selectedTimeRange) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
    }
    
    // MARK: - Charts Section
    private var chartsSection: some View {
        ScrollView {
            VStack(spacing: 20) {
                switch selectedMetric {
                case .bandwidth:
                    bandwidthCharts
                case .latency:
                    latencyCharts
                case .performance:
                    performanceCharts
                case .utilization:
                    utilizationCharts
                }
            }
            .padding()
        }
    }
    
    // MARK: - Bandwidth Charts
    private var bandwidthCharts: some View {
        VStack(spacing: 16) {
            Text("Bandwidth Usage")
                .font(.title2)
                .fontWeight(.bold)
            
            if monitoringManager.bandwidthUsage.isEmpty {
                emptyStateView
            } else {
                // Simple data visualization without Charts
                bandwidthDataView
                
                // Bandwidth Summary
                bandwidthSummary
            }
        }
    }
    
    // MARK: - Latency Charts
    private var latencyCharts: some View {
        VStack(spacing: 16) {
            Text("Latency Measurements")
                .font(.title2)
                .fontWeight(.bold)
            
            if monitoringManager.latencyMeasurements.isEmpty {
                emptyStateView
            } else {
                // Simple data visualization without Charts
                latencyDataView
                
                // Latency Summary
                latencySummary
            }
        }
    }
    
    // MARK: - Performance Charts
    private var performanceCharts: some View {
        VStack(spacing: 16) {
            Text("Performance Metrics")
                .font(.title2)
                .fontWeight(.bold)
            
            if monitoringManager.performanceMetrics.isEmpty {
                emptyStateView
            } else {
                // Simple data visualization without Charts
                performanceDataView
                
                // Performance Summary
                performanceSummary
            }
        }
    }
    
    // MARK: - Utilization Charts
    private var utilizationCharts: some View {
        VStack(spacing: 16) {
            Text("Port Utilization")
                .font(.title2)
                .fontWeight(.bold)
            
            if monitoringManager.performanceMetrics.isEmpty {
                emptyStateView
            } else {
                // Simple data visualization without Charts
                utilizationDataView
                
                // Utilization Summary
                utilizationSummary
            }
        }
    }
    
    // MARK: - Data Views (Simplified without Charts)
    private var bandwidthDataView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Bandwidth Usage")
                .font(.headline)
            
            ForEach(filteredBandwidthData.suffix(10)) { usage in
                HStack {
                    Text(usage.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", usage.totalBandwidthMbps)) Mbps")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var latencyDataView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Latency Measurements")
                .font(.headline)
            
            ForEach(filteredLatencyData.suffix(10)) { measurement in
                HStack {
                    Text(measurement.targetIP)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.1f", measurement.latencyMs)) ms")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(measurement.status == .excellent ? .green : measurement.status == .good ? .blue : .orange)
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var performanceDataView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Performance Metrics")
                .font(.headline)
            
            ForEach(filteredPerformanceData.suffix(10)) { metric in
                HStack {
                    Text(metric.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("CPU: \(String(format: "%.1f", metric.cpuUsage))%")
                            .font(.caption)
                            .foregroundColor(metric.cpuUsage > 80 ? .red : .green)
                        
                        Text("Memory: \(String(format: "%.1f", metric.memoryUsage))%")
                            .font(.caption)
                            .foregroundColor(metric.memoryUsage > 80 ? .red : .green)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var utilizationDataView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Port Utilization")
                .font(.headline)
            
            if let latest = monitoringManager.performanceMetrics.last {
                ForEach(latest.portUtilization.prefix(12)) { port in
                    HStack {
                        Text("Port \(port.portNumber)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(String(format: "%.1f", port.utilizationPercent))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(port.utilizationPercent > 80 ? .red : port.utilizationPercent > 60 ? .orange : .green)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Summary Views
    private var bandwidthSummary: some View {
        HStack(spacing: 20) {
            SummaryCard(
                title: "Total Bandwidth",
                value: String(format: "%.1f Mbps", totalBandwidth),
                icon: "arrow.up.arrow.down",
                color: .blue
            )
            
            SummaryCard(
                title: "Peak Usage",
                value: String(format: "%.1f Mbps", peakBandwidth),
                icon: "chart.line.uptrend.xyaxis",
                color: .red
            )
            
            SummaryCard(
                title: "Average Usage",
                value: String(format: "%.1f Mbps", averageBandwidth),
                icon: "chart.bar.fill",
                color: .green
            )
        }
    }
    
    private var latencySummary: some View {
        HStack(spacing: 20) {
            SummaryCard(
                title: "Average Latency",
                value: String(format: "%.1f ms", averageLatency),
                icon: "speedometer",
                color: .green
            )
            
            SummaryCard(
                title: "Max Latency",
                value: String(format: "%.1f ms", maxLatency),
                icon: "exclamationmark.triangle",
                color: .red
            )
            
            SummaryCard(
                title: "Packet Loss",
                value: String(format: "%.1f%%", averagePacketLoss),
                icon: "wifi.slash",
                color: .orange
            )
        }
    }
    
    private var performanceSummary: some View {
        HStack(spacing: 20) {
            SummaryCard(
                title: "CPU Usage",
                value: String(format: "%.1f%%", averageCPU),
                icon: "cpu",
                color: .red
            )
            
            SummaryCard(
                title: "Memory Usage",
                value: String(format: "%.1f%%", averageMemory),
                icon: "memorychip",
                color: .orange
            )
            
            SummaryCard(
                title: "Temperature",
                value: String(format: "%.1f°C", averageTemperature),
                icon: "thermometer",
                color: .blue
            )
        }
    }
    
    private var utilizationSummary: some View {
        HStack(spacing: 20) {
            SummaryCard(
                title: "Active Ports",
                value: "\(activePortsCount)",
                icon: "network",
                color: .green
            )
            
            SummaryCard(
                title: "High Usage",
                value: "\(highUsagePortsCount)",
                icon: "exclamationmark.triangle",
                color: .red
            )
            
            SummaryCard(
                title: "Average Usage",
                value: String(format: "%.1f%%", averagePortUtilization),
                icon: "chart.bar.fill",
                color: .blue
            )
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Data Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start monitoring to see analytics data")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
    
    // MARK: - Computed Properties
    private var healthColor: Color {
        guard let health = monitoringManager.pocketDisplayData?.networkHealth else {
            return .gray
        }
        
        switch health {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        case .critical: return .purple
        }
    }
    
    private var healthStatus: String {
        monitoringManager.pocketDisplayData?.networkHealth.rawValue ?? "Unknown"
    }
    
    private var filteredBandwidthData: [BandwidthUsage] {
        let cutoff = Date().addingTimeInterval(-selectedTimeRange.duration)
        return monitoringManager.bandwidthUsage.filter { $0.timestamp >= cutoff }
    }
    
    private var filteredLatencyData: [LatencyMeasurement] {
        let cutoff = Date().addingTimeInterval(-selectedTimeRange.duration)
        return monitoringManager.latencyMeasurements.filter { $0.timestamp >= cutoff }
    }
    
    private var filteredPerformanceData: [NetworkPerformanceMetrics] {
        let cutoff = Date().addingTimeInterval(-selectedTimeRange.duration)
        return monitoringManager.performanceMetrics.filter { $0.timestamp >= cutoff }
    }
    
    private var totalBandwidth: Double {
        filteredBandwidthData.map { $0.totalBandwidthMbps }.reduce(0, +)
    }
    
    private var peakBandwidth: Double {
        filteredBandwidthData.map { $0.totalBandwidthMbps }.max() ?? 0
    }
    
    private var averageBandwidth: Double {
        let data = filteredBandwidthData.map { $0.totalBandwidthMbps }
        return data.isEmpty ? 0 : data.reduce(0, +) / Double(data.count)
    }
    
    private var averageLatency: Double {
        let data = filteredLatencyData.map { $0.latencyMs }
        return data.isEmpty ? 0 : data.reduce(0, +) / Double(data.count)
    }
    
    private var maxLatency: Double {
        filteredLatencyData.map { $0.latencyMs }.max() ?? 0
    }
    
    private var averagePacketLoss: Double {
        let data = filteredLatencyData.map { $0.packetLoss }
        return data.isEmpty ? 0 : data.reduce(0, +) / Double(data.count)
    }
    
    private var averageCPU: Double {
        let data = filteredPerformanceData.map { $0.cpuUsage }
        return data.isEmpty ? 0 : data.reduce(0, +) / Double(data.count)
    }
    
    private var averageMemory: Double {
        let data = filteredPerformanceData.map { $0.memoryUsage }
        return data.isEmpty ? 0 : data.reduce(0, +) / Double(data.count)
    }
    
    private var averageTemperature: Double {
        let data = filteredPerformanceData.compactMap { $0.temperature }
        return data.isEmpty ? 0 : data.reduce(0, +) / Double(data.count)
    }
    
    private var activePortsCount: Int {
        guard let latest = monitoringManager.performanceMetrics.last else { return 0 }
        return latest.portUtilization.filter { $0.utilizationPercent > 0 }.count
    }
    
    private var highUsagePortsCount: Int {
        guard let latest = monitoringManager.performanceMetrics.last else { return 0 }
        return latest.portUtilization.filter { $0.utilizationPercent > 80 }.count
    }
    
    private var averagePortUtilization: Double {
        guard let latest = monitoringManager.performanceMetrics.last else { return 0 }
        let data = latest.portUtilization.map { $0.utilizationPercent }
        return data.isEmpty ? 0 : data.reduce(0, +) / Double(data.count)
    }
    
    // MARK: - Actions
    private func exportAllData() {
        exportData = monitoringManager.exportAllData()
        showingExportSheet = true
    }
}

// MARK: - Summary Card
struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    let data: Data?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let data = data {
                    Text("Export Data")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Data exported successfully!")
                        .font(.body)
                        .foregroundColor(.green)
                    
                    Text("\(data.count) bytes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Share Data") {
                        // Share functionality would go here
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("No data to export")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview
struct NetworkAnalyticsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        if #available(macOS 11.0, *) {
            NetworkAnalyticsDashboard()
        } else {
            Text("Requires macOS 11.0 or later")
        }
    }
}