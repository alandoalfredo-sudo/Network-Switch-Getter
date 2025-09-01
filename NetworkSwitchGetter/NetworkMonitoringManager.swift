import Foundation
import Network
import Combine
import SystemConfiguration

// MARK: - Network Monitoring Manager
@MainActor
class NetworkMonitoringManager: ObservableObject {
    @Published var bandwidthUsage: [BandwidthUsage] = []
    @Published var latencyMeasurements: [LatencyMeasurement] = []
    @Published var performanceMetrics: [NetworkPerformanceMetrics] = []
    @Published var pocketDisplayData: PocketDisplayData?
    @Published var isMonitoring = false
    @Published var monitoringInterval: TimeInterval = 5.0
    
    private var monitoringTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let networkMonitor = NWPathMonitor()
    private var previousInterfaceStats: [String: InterfaceStats] = [:]
    
    struct InterfaceStats {
        let bytesIn: UInt64
        let bytesOut: UInt64
        let timestamp: Date
    }
    
    init() {
        setupNetworkMonitoring()
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
        networkMonitor.cancel()
    }
    
    // MARK: - Monitoring Control
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.collectNetworkData()
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    func setMonitoringInterval(_ interval: TimeInterval) {
        monitoringInterval = interval
        if isMonitoring {
            stopMonitoring()
            startMonitoring()
        }
    }
    
    // MARK: - Network Data Collection
    private func collectNetworkData() async {
        await collectBandwidthUsage()
        await collectLatencyMeasurements()
        await collectPerformanceMetrics()
        await updatePocketDisplayData()
    }
    
    // MARK: - Bandwidth Monitoring
    private func collectBandwidthUsage() async {
        let currentStats = getCurrentInterfaceStats()
        
        for (interfaceName, currentStat) in currentStats {
            if let previousStat = previousInterfaceStats[interfaceName] {
                let bytesInDelta = currentStat.bytesIn - previousStat.bytesIn
                let bytesOutDelta = currentStat.bytesOut - previousStat.bytesOut
                let timeDelta = currentStat.timestamp.timeIntervalSince(previousStat.timestamp)
                
                // Only add if there's actual data transfer
                if bytesInDelta > 0 || bytesOutDelta > 0 {
                    let bandwidthUsage = BandwidthUsage(
                        timestamp: currentStat.timestamp,
                        bytesIn: bytesInDelta,
                        bytesOut: bytesOutDelta,
                        interfaceName: interfaceName,
                        deviceIP: getCurrentIPAddress() ?? "unknown"
                    )
                    
                    bandwidthUsage.append(bandwidthUsage)
                    
                    // Keep only last 100 measurements
                    if bandwidthUsage.count > 100 {
                        bandwidthUsage.removeFirst()
                    }
                }
            }
            
            previousInterfaceStats[interfaceName] = currentStat
        }
    }
    
    private func getCurrentInterfaceStats() -> [String: InterfaceStats] {
        var stats: [String: InterfaceStats] = [:]
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return stats }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)
            
            // Skip loopback and inactive interfaces
            if name == "lo0" || (interface.ifa_flags & UInt32(IFF_UP)) == 0 {
                continue
            }
            
            if let data = interface.ifa_data {
                let ifData = data.assumingMemoryBound(to: if_data.self).pointee
                
                stats[name] = InterfaceStats(
                    bytesIn: UInt64(ifData.ifi_ibytes),
                    bytesOut: UInt64(ifData.ifi_obytes),
                    timestamp: Date()
                )
            }
        }
        
        return stats
    }
    
    // MARK: - Latency Monitoring
    private func collectLatencyMeasurements() async {
        let targetIPs = getTargetIPs()
        
        for targetIP in targetIPs {
            let measurement = await measureLatency(to: targetIP)
            latencyMeasurements.append(measurement)
            
            // Keep only last 50 measurements per IP
            let measurementsForIP = latencyMeasurements.filter { $0.targetIP == targetIP }
            if measurementsForIP.count > 50 {
                latencyMeasurements.removeAll { $0.targetIP == targetIP }
                latencyMeasurements.append(contentsOf: measurementsForIP.suffix(50))
            }
        }
    }
    
    private func getTargetIPs() -> [String] {
        // Get IPs from discovered switches and common network targets
        var targets: [String] = []
        
        // Add common network targets
        targets.append(contentsOf: ["8.8.8.8", "1.1.1.1", "208.67.222.222"])
        
        // Add discovered switch IPs (this would be injected from the main app)
        // For now, we'll use placeholder IPs
        targets.append(contentsOf: ["192.168.1.1", "192.168.1.100"])
        
        return targets
    }
    
    private func measureLatency(to targetIP: String) async -> LatencyMeasurement {
        let startTime = Date()
        var latency: Double = 0.0
        var packetLoss: Double = 0.0
        var jitter: Double = 0.0
        
        // Perform multiple ping measurements for accuracy
        let pingCount = 5
        var latencies: [Double] = []
        
        for _ in 0..<pingCount {
            let pingLatency = await performPing(to: targetIP)
            if pingLatency > 0 {
                latencies.append(pingLatency)
            } else {
                packetLoss += 1.0
            }
        }
        
        if !latencies.isEmpty {
            latency = latencies.reduce(0, +) / Double(latencies.count)
            
            // Calculate jitter (standard deviation of latencies)
            let mean = latency
            let variance = latencies.map { pow($0 - mean, 2) }.reduce(0, +) / Double(latencies.count)
            jitter = sqrt(variance)
        }
        
        packetLoss = (packetLoss / Double(pingCount)) * 100.0
        
        let status = LatencyMeasurement.LatencyStatus.status(for: latency)
        
        return LatencyMeasurement(
            timestamp: startTime,
            targetIP: targetIP,
            latencyMs: latency,
            packetLoss: packetLoss,
            jitter: jitter,
            status: status
        )
    }
    
    private func performPing(to targetIP: String) async -> Double {
        return await withCheckedContinuation { continuation in
            let connection = NWConnection(host: NWEndpoint.Host(targetIP), port: 80, using: .tcp)
            let startTime = Date()
            
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let latency = Date().timeIntervalSince(startTime) * 1000.0 // Convert to milliseconds
                    connection.cancel()
                    continuation.resume(returning: latency)
                case .failed(_):
                    connection.cancel()
                    continuation.resume(returning: -1.0)
                case .cancelled:
                    continuation.resume(returning: -1.0)
                default:
                    break
                }
            }
            
            connection.start(queue: .global())
            
            // Timeout after 5 seconds
            DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) {
                connection.cancel()
                continuation.resume(returning: -1.0)
            }
        }
    }
    
    // MARK: - Performance Metrics
    private func collectPerformanceMetrics() async {
        // This would typically collect metrics from SNMP or other management protocols
        // For now, we'll simulate some metrics
        
        let simulatedMetrics = NetworkPerformanceMetrics(
            timestamp: Date(),
            deviceIP: getCurrentIPAddress() ?? "192.168.1.1",
            cpuUsage: Double.random(in: 10...90),
            memoryUsage: Double.random(in: 20...80),
            temperature: Double.random(in: 30...70),
            uptime: TimeInterval.random(in: 3600...86400),
            portUtilization: generateSimulatedPortUtilization(),
            errorCount: Int.random(in: 0...10),
            packetCount: UInt64.random(in: 1000...100000)
        )
        
        performanceMetrics.append(simulatedMetrics)
        
        // Keep only last 20 measurements
        if performanceMetrics.count > 20 {
            performanceMetrics.removeFirst()
        }
    }
    
    private func generateSimulatedPortUtilization() -> [NetworkPerformanceMetrics.PortUtilization] {
        var portUtils: [NetworkPerformanceMetrics.PortUtilization] = []
        
        for portNum in 1...24 {
            portUtils.append(NetworkPerformanceMetrics.PortUtilization(
                portNumber: portNum,
                utilizationPercent: Double.random(in: 0...100),
                bytesTransferred: UInt64.random(in: 1000...1000000),
                packetsTransferred: UInt64.random(in: 100...10000),
                errors: Int.random(in: 0...5)
            ))
        }
        
        return portUtils
    }
    
    // MARK: - Pocket Display Data
    private func updatePocketDisplayData() async {
        let totalDevices = 10 // This would come from the main app
        let onlineDevices = 8 // This would come from the main app
        
        let averageLatency = latencyMeasurements.isEmpty ? 0.0 : 
            latencyMeasurements.map { $0.latencyMs }.reduce(0, +) / Double(latencyMeasurements.count)
        
        let totalBandwidth = bandwidthUsage.isEmpty ? 0.0 :
            bandwidthUsage.map { $0.totalBandwidthMbps }.reduce(0, +)
        
        let networkHealth = calculateNetworkHealth()
        
        let topDevices = generateTopDevices()
        let alerts = generateNetworkAlerts()
        
        pocketDisplayData = PocketDisplayData(
            timestamp: Date(),
            totalDevices: totalDevices,
            onlineDevices: onlineDevices,
            averageLatency: averageLatency,
            totalBandwidth: totalBandwidth,
            networkHealth: networkHealth,
            topDevices: topDevices,
            alerts: alerts
        )
    }
    
    private func calculateNetworkHealth() -> NetworkHealth {
        let offlineDevices = 2 // This would be calculated from actual data
        let averageLatency = latencyMeasurements.isEmpty ? 0.0 :
            latencyMeasurements.map { $0.latencyMs }.reduce(0, +) / Double(latencyMeasurements.count)
        
        var healthScore = 100.0
        
        if offlineDevices > 0 {
            healthScore -= Double(offlineDevices) * 10.0
        }
        
        if averageLatency > 100.0 {
            healthScore -= 20.0
        } else if averageLatency > 50.0 {
            healthScore -= 10.0
        }
        
        switch healthScore {
        case 90...100: return .excellent
        case 75..<90: return .good
        case 60..<75: return .fair
        case 40..<60: return .poor
        default: return .critical
        }
    }
    
    private func generateTopDevices() -> [PocketDisplayData.DeviceSummary] {
        return [
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
            ),
            PocketDisplayData.DeviceSummary(
                ipAddress: "192.168.1.101",
                hostname: "switch-02",
                status: .online,
                latency: 12.5,
                bandwidth: 67.8,
                utilization: 60.0
            )
        ]
    }
    
    private func generateNetworkAlerts() -> [PocketDisplayData.NetworkAlert] {
        var alerts: [PocketDisplayData.NetworkAlert] = []
        
        // Check for high latency alerts
        for measurement in latencyMeasurements.suffix(5) {
            if measurement.latencyMs > 100.0 {
                alerts.append(PocketDisplayData.NetworkAlert(
                    type: .highLatency,
                    severity: .warning,
                    message: "High latency detected: \(String(format: "%.1f", measurement.latencyMs))ms to \(measurement.targetIP)",
                    timestamp: measurement.timestamp,
                    deviceIP: measurement.targetIP
                ))
            }
        }
        
        // Check for bandwidth alerts
        for usage in bandwidthUsage.suffix(5) {
            if usage.totalBandwidthMbps > 1000.0 {
                alerts.append(PocketDisplayData.NetworkAlert(
                    type: .bandwidthExceeded,
                    severity: .error,
                    message: "High bandwidth usage: \(String(format: "%.1f", usage.totalBandwidthMbps)) Mbps",
                    timestamp: usage.timestamp,
                    deviceIP: usage.deviceName
                ))
            }
        }
        
        return alerts
    }
    
    // MARK: - Utility Methods
    private func getCurrentIPAddress() -> String? {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { continue }
            let name = String(cString: interface.ifa_name)
            
            if name == "en0" && interface.ifa_addr?.pointee.sa_family == UInt8(AF_INET) {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr!.pointee.sa_len),
                           &hostname, socklen_t(hostname.count),
                           nil, socklen_t(0), NI_NUMERICHOST)
                return String(cString: hostname)
            }
        }
        return nil
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                if path.status == .satisfied {
                    // Network is available
                } else {
                    // Network is unavailable
                }
            }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .background))
    }
    
    // MARK: - Data Export
    func exportBandwidthData() -> Data? {
        return try? JSONEncoder().encode(bandwidthUsage)
    }
    
    func exportLatencyData() -> Data? {
        return try? JSONEncoder().encode(latencyMeasurements)
    }
    
    func exportPerformanceData() -> Data? {
        return try? JSONEncoder().encode(performanceMetrics)
    }
    
    func clearAllData() {
        bandwidthUsage.removeAll()
        latencyMeasurements.removeAll()
        performanceMetrics.removeAll()
        pocketDisplayData = nil
    }
}
