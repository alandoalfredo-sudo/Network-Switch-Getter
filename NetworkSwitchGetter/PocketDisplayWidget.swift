import SwiftUI
import WidgetKit

// MARK: - Pocket Display Widget
struct PocketDisplayWidget: Widget {
    let kind: String = "PocketDisplayWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PocketDisplayProvider()) { entry in
            PocketDisplayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Network Status")
        .description("Monitor your network devices and performance at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Entry
struct PocketDisplayEntry: TimelineEntry {
    let date: Date
    let pocketData: PocketDisplayData?
    let configuration: PocketDisplayConfigurationIntent?
}

// MARK: - Widget Provider
struct PocketDisplayProvider: IntentTimelineProvider {
    func placeholder(in context: Context) -> PocketDisplayEntry {
        PocketDisplayEntry(
            date: Date(),
            pocketData: generatePlaceholderData(),
            configuration: nil
        )
    }
    
    func getSnapshot(for configuration: PocketDisplayConfigurationIntent, in context: Context, completion: @escaping (PocketDisplayEntry) -> ()) {
        let entry = PocketDisplayEntry(
            date: Date(),
            pocketData: generatePlaceholderData(),
            configuration: configuration
        )
        completion(entry)
    }
    
    func getTimeline(for configuration: PocketDisplayConfigurationIntent, in context: Context, completion: @escaping (Timeline<PocketDisplayEntry>) -> ()) {
        let currentDate = Date()
        let entry = PocketDisplayEntry(
            date: currentDate,
            pocketData: generatePlaceholderData(),
            configuration: configuration
        )
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func generatePlaceholderData() -> PocketDisplayData {
        return PocketDisplayData(
            timestamp: Date(),
            totalDevices: 8,
            onlineDevices: 7,
            averageLatency: 15.5,
            totalBandwidth: 245.7,
            networkHealth: .good,
            topDevices: [
                PocketDisplayData.DeviceSummary(
                    ipAddress: "192.168.1.1",
                    hostname: "router-01",
                    status: .online,
                    latency: 5.2,
                    bandwidth: 150.5,
                    utilization: 75.0
                ),
                PocketDisplayData.DeviceSummary(
                    ipAddress: "192.168.1.100",
                    hostname: "switch-01",
                    status: .online,
                    latency: 8.1,
                    bandwidth: 89.3,
                    utilization: 45.0
                )
            ],
            alerts: [
                PocketDisplayData.NetworkAlert(
                    type: .highLatency,
                    severity: .warning,
                    message: "High latency detected on switch-02",
                    timestamp: Date(),
                    deviceIP: "192.168.1.101"
                )
            ]
        )
    }
}

// MARK: - Widget Entry View
struct PocketDisplayWidgetEntryView: View {
    var entry: PocketDisplayProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: PocketDisplayEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Network Health Indicator
            HStack {
                Circle()
                    .fill(Color(entry.pocketData?.networkHealth.color ?? "gray"))
                    .frame(width: 12, height: 12)
                
                Text(entry.pocketData?.networkHealth.rawValue ?? "Unknown")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            // Device Count
            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.pocketData?.onlineDevices ?? 0)/\(entry.pocketData?.totalDevices ?? 0)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Devices Online")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Latency
            HStack {
                Image(systemName: "speedometer")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("\(String(format: "%.1f", entry.pocketData?.averageLatency ?? 0))ms")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: PocketDisplayEntry
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Network Status")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(entry.pocketData?.networkHealth.rawValue ?? "Unknown")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(Color(entry.pocketData?.networkHealth.color ?? "gray"))
                    .frame(width: 16, height: 16)
            }
            
            // Metrics Row
            HStack(spacing: 20) {
                MetricView(
                    title: "Devices",
                    value: "\(entry.pocketData?.onlineDevices ?? 0)/\(entry.pocketData?.totalDevices ?? 0)",
                    icon: "network"
                )
                
                MetricView(
                    title: "Latency",
                    value: "\(String(format: "%.1f", entry.pocketData?.averageLatency ?? 0))ms",
                    icon: "speedometer"
                )
                
                MetricView(
                    title: "Bandwidth",
                    value: "\(String(format: "%.1f", entry.pocketData?.totalBandwidth ?? 0))Mbps",
                    icon: "arrow.up.arrow.down"
                )
            }
            
            // Alerts
            if let alerts = entry.pocketData?.alerts, !alerts.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    
                    Text("\(alerts.count) alert\(alerts.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: PocketDisplayEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Network Dashboard")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Last updated: \(entry.date, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(entry.pocketData?.networkHealth.color ?? "gray"))
                        .frame(width: 12, height: 12)
                    
                    Text(entry.pocketData?.networkHealth.rawValue ?? "Unknown")
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            // Top Devices
            VStack(alignment: .leading, spacing: 8) {
                Text("Top Devices")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                ForEach(entry.pocketData?.topDevices.prefix(3) ?? []) { device in
                    DeviceRowView(device: device)
                }
            }
            
            // Alerts
            if let alerts = entry.pocketData?.alerts, !alerts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Alerts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ForEach(alerts.prefix(2)) { alert in
                        AlertRowView(alert: alert)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Metric View
struct MetricView: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Device Row View
struct DeviceRowView: View {
    let device: PocketDisplayData.DeviceSummary
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(device.status.color))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(device.hostname ?? device.ipAddress)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(device.ipAddress)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(String(format: "%.1f", device.latency))ms")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("\(String(format: "%.0f", device.utilization))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Alert Row View
struct AlertRowView: View {
    let alert: PocketDisplayData.NetworkAlert
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: alertIcon(for: alert.severity))
                .font(.caption)
                .foregroundColor(Color(alert.severity.color))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(alert.message)
                    .font(.caption)
                    .lineLimit(2)
                
                Text(alert.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private func alertIcon(for severity: PocketDisplayData.NetworkAlert.AlertSeverity) -> String {
        switch severity {
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.circle"
        case .critical: return "exclamationmark.octagon"
        }
    }
}

// MARK: - Widget Bundle
@main
struct PocketDisplayWidgetBundle: WidgetBundle {
    var body: some Widget {
        PocketDisplayWidget()
    }
}

// MARK: - Configuration Intent
import Intents

class PocketDisplayConfigurationIntent: INIntent {
    @NSManaged public var refreshInterval: NSNumber?
    @NSManaged public var showAlerts: NSNumber?
    @NSManaged public var showBandwidth: NSNumber?
}

// MARK: - Preview
struct PocketDisplayWidget_Previews: PreviewProvider {
    static var previews: some View {
        let entry = PocketDisplayEntry(
            date: Date(),
            pocketData: PocketDisplayData(
                timestamp: Date(),
                totalDevices: 8,
                onlineDevices: 7,
                averageLatency: 15.5,
                totalBandwidth: 245.7,
                networkHealth: .good,
                topDevices: [
                    PocketDisplayData.DeviceSummary(
                        ipAddress: "192.168.1.1",
                        hostname: "router-01",
                        status: .online,
                        latency: 5.2,
                        bandwidth: 150.5,
                        utilization: 75.0
                    )
                ],
                alerts: []
            ),
            configuration: nil
        )
        
        Group {
            PocketDisplayWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Widget")
            
            PocketDisplayWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Widget")
            
            PocketDisplayWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large Widget")
        }
    }
}
