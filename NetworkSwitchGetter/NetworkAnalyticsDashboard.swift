import SwiftUI
import Charts

// MARK: - Network Analytics Dashboard
struct NetworkAnalyticsDashboard: View {
    @StateObject private var monitoringManager = NetworkMonitoringManager()
    @StateObject private var aiIntelligence = AINetworkIntelligence()
    @State private var selectedTimeRange: TimeRange = .lastHour
    @State private var selectedMetric: AnalyticsMetric = .bandwidth
    
    enum TimeRange: String, CaseIterable {
        case lastHour = "Last Hour"
        case lastDay = "Last Day"
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        
        var duration: TimeInterval {
            switch self {
            case .lastHour: return 3600
            case .lastDay: return 86400
            case .lastWeek: return 604800
            case .lastMonth: return 2592000
            }
        }
    }
    
    enum AnalyticsMetric: String, CaseIterable {
        case bandwidth = "Bandwidth"
        case latency = "Latency"
        case performance = "Performance"
        case utilization = "Utilization"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Time Range Selector
                    TimeRangeSelector(selectedTimeRange: $selectedTimeRange)
                    
                    // Metric Selector
                    MetricSelector(selectedMetric: $selectedMetric)
                    
                    // Real-time Metrics Cards
                    RealTimeMetricsCards(monitoringManager: monitoringManager)
                    
                    // Charts Section
                    ChartsSection(
                        monitoringManager: monitoringManager,
                        timeRange: selectedTimeRange,
                        metric: selectedMetric
                    )
                    
                    // AI Insights Section
                    AIInsightsSection(aiIntelligence: aiIntelligence)
                    
                    // Device Performance Table
                    DevicePerformanceTable(monitoringManager: monitoringManager)
                }
                .padding()
            }
            .navigationTitle("Network Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Export") {
                        exportAnalytics()
                    }
                }
            }
        }
        .onAppear {
            monitoringManager.startMonitoring()
        }
    }
    
    private func exportAnalytics() {
        // Export analytics data
    }
}

// MARK: - Time Range Selector
struct TimeRangeSelector: View {
    @Binding var selectedTimeRange: NetworkAnalyticsDashboard.TimeRange
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Range")
                .font(.headline)
                .fontWeight(.medium)
            
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(NetworkAnalyticsDashboard.TimeRange.allCases, id: \.self) { range in
                    Text(range.rawValue).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

// MARK: - Metric Selector
struct MetricSelector: View {
    @Binding var selectedMetric: NetworkAnalyticsDashboard.AnalyticsMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analytics Metric")
                .font(.headline)
                .fontWeight(.medium)
            
            Picker("Metric", selection: $selectedMetric) {
                ForEach(NetworkAnalyticsDashboard.AnalyticsMetric.allCases, id: \.self) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
}

// MARK: - Real-time Metrics Cards
struct RealTimeMetricsCards: View {
    @ObservedObject var monitoringManager: NetworkMonitoringManager
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            MetricCard(
                title: "Total Bandwidth",
                value: "\(String(format: "%.1f", monitoringManager.pocketDisplayData?.totalBandwidth ?? 0)) Mbps",
                icon: "arrow.up.arrow.down",
                color: .blue
            )
            
            MetricCard(
                title: "Average Latency",
                value: "\(String(format: "%.1f", monitoringManager.pocketDisplayData?.averageLatency ?? 0)) ms",
                icon: "speedometer",
                color: .green
            )
            
            MetricCard(
                title: "Online Devices",
                value: "\(monitoringManager.pocketDisplayData?.onlineDevices ?? 0)/\(monitoringManager.pocketDisplayData?.totalDevices ?? 0)",
                icon: "network",
                color: .orange
            )
            
            MetricCard(
                title: "Network Health",
                value: monitoringManager.pocketDisplayData?.networkHealth.rawValue ?? "Unknown",
                icon: "heart.fill",
                color: Color(monitoringManager.pocketDisplayData?.networkHealth.color ?? "gray")
            )
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Charts Section
struct ChartsSection: View {
    @ObservedObject var monitoringManager: NetworkMonitoringManager
    let timeRange: NetworkAnalyticsDashboard.TimeRange
    let metric: NetworkAnalyticsDashboard.AnalyticsMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Charts")
                .font(.headline)
                .fontWeight(.medium)
            
            switch metric {
            case .bandwidth:
                BandwidthChart(data: monitoringManager.bandwidthUsage, timeRange: timeRange)
            case .latency:
                LatencyChart(data: monitoringManager.latencyMeasurements, timeRange: timeRange)
            case .performance:
                PerformanceChart(data: monitoringManager.performanceMetrics, timeRange: timeRange)
            case .utilization:
                UtilizationChart(data: monitoringManager.performanceMetrics, timeRange: timeRange)
            }
        }
    }
}

// MARK: - Bandwidth Chart
struct BandwidthChart: View {
    let data: [BandwidthUsage]
    let timeRange: NetworkAnalyticsDashboard.TimeRange
    
    private var filteredData: [BandwidthUsage] {
        let cutoffDate = Date().addingTimeInterval(-timeRange.duration)
        return data.filter { $0.timestamp >= cutoffDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Bandwidth Usage Over Time")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if filteredData.isEmpty {
                EmptyChartView(message: "No bandwidth data available")
            } else {
                Chart(filteredData, id: \.id) { usage in
                    LineMark(
                        x: .value("Time", usage.timestamp),
                        y: .value("Bandwidth", usage.totalBandwidthMbps)
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Latency Chart
struct LatencyChart: View {
    let data: [LatencyMeasurement]
    let timeRange: NetworkAnalyticsDashboard.TimeRange
    
    private var filteredData: [LatencyMeasurement] {
        let cutoffDate = Date().addingTimeInterval(-timeRange.duration)
        return data.filter { $0.timestamp >= cutoffDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latency Over Time")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if filteredData.isEmpty {
                EmptyChartView(message: "No latency data available")
            } else {
                Chart(filteredData, id: \.id) { measurement in
                    LineMark(
                        x: .value("Time", measurement.timestamp),
                        y: .value("Latency", measurement.latencyMs)
                    )
                    .foregroundStyle(.green)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Performance Chart
struct PerformanceChart: View {
    let data: [NetworkPerformanceMetrics]
    let timeRange: NetworkAnalyticsDashboard.TimeRange
    
    private var filteredData: [NetworkPerformanceMetrics] {
        let cutoffDate = Date().addingTimeInterval(-timeRange.duration)
        return data.filter { $0.timestamp >= cutoffDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CPU and Memory Usage")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if filteredData.isEmpty {
                EmptyChartView(message: "No performance data available")
            } else {
                Chart(filteredData, id: \.id) { metrics in
                    LineMark(
                        x: .value("Time", metrics.timestamp),
                        y: .value("CPU", metrics.cpuUsage)
                    )
                    .foregroundStyle(.red)
                    
                    LineMark(
                        x: .value("Time", metrics.timestamp),
                        y: .value("Memory", metrics.memoryUsage)
                    )
                    .foregroundStyle(.orange)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour)) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.hour())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Utilization Chart
struct UtilizationChart: View {
    let data: [NetworkPerformanceMetrics]
    let timeRange: NetworkAnalyticsDashboard.TimeRange
    
    private var latestMetrics: NetworkPerformanceMetrics? {
        data.max(by: { $0.timestamp < $1.timestamp })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Port Utilization")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if let metrics = latestMetrics, !metrics.portUtilization.isEmpty {
                Chart(metrics.portUtilization, id: \.id) { portUtil in
                    BarMark(
                        x: .value("Port", portUtil.portNumber),
                        y: .value("Utilization", portUtil.utilizationPercent)
                    )
                    .foregroundStyle(.purple)
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel()
                    }
                }
            } else {
                EmptyChartView(message: "No utilization data available")
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Empty Chart View
struct EmptyChartView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - AI Insights Section
struct AIInsightsSection: View {
    @ObservedObject var aiIntelligence: AINetworkIntelligence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Insights")
                .font(.headline)
                .fontWeight(.medium)
            
            if aiIntelligence.recommendations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No AI insights available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Generate AI Insights") {
                        Task {
                            await aiIntelligence.analyzeNetworkPerformance(switches: [], metrics: [])
                        }
                    }
                    .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(aiIntelligence.recommendations.prefix(3)) { recommendation in
                        AIInsightCard(recommendation: recommendation)
                    }
                }
            }
        }
    }
}

// MARK: - AI Insight Card
struct AIInsightCard: View {
    let recommendation: AINetworkRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(recommendation.priority.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(recommendation.priority.color).opacity(0.2))
                    .cornerRadius(4)
                
                Text("\(Int(recommendation.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Device Performance Table
struct DevicePerformanceTable: View {
    @ObservedObject var monitoringManager: NetworkMonitoringManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Device Performance")
                .font(.headline)
                .fontWeight(.medium)
            
            if monitoringManager.performanceMetrics.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "server.rack")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No performance data available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(monitoringManager.performanceMetrics.suffix(5)) { metrics in
                        DevicePerformanceRow(metrics: metrics)
                    }
                }
            }
        }
    }
}

// MARK: - Device Performance Row
struct DevicePerformanceRow: View {
    let metrics: NetworkPerformanceMetrics
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(metrics.deviceIP)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Uptime: \(formatUptime(metrics.uptime))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 12) {
                    PerformanceIndicator(
                        title: "CPU",
                        value: metrics.cpuUsage,
                        color: .red
                    )
                    
                    PerformanceIndicator(
                        title: "Memory",
                        value: metrics.memoryUsage,
                        color: .orange
                    )
                    
                    if let temperature = metrics.temperature {
                        PerformanceIndicator(
                            title: "Temp",
                            value: temperature,
                            color: .blue,
                            unit: "°C"
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatUptime(_ uptime: TimeInterval) -> String {
        let hours = Int(uptime) / 3600
        let minutes = (Int(uptime) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - Performance Indicator
struct PerformanceIndicator: View {
    let title: String
    let value: Double
    let color: Color
    let unit: String
    
    init(title: String, value: Double, color: Color, unit: String = "%") {
        self.title = title
        self.value = value
        self.color = color
        self.unit = unit
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(String(format: "%.1f", value))\(unit)")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

// MARK: - Preview
struct NetworkAnalyticsDashboard_Previews: PreviewProvider {
    static var previews: some View {
        NetworkAnalyticsDashboard()
    }
}
