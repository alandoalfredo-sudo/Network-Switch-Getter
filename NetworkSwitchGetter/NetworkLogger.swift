import Foundation
import os.log

// MARK: - Network Logger
@available(macOS 10.15, *)
class NetworkLogger {
    static let shared = NetworkLogger()
    
    private let logger: OSLog
    private let fileLogger = FileLogger()
    
    private init() {
        logger = OSLog(subsystem: "com.networkswitchgetter.NetworkSwitchGetter", category: "NetworkSwitchGetter")
    }
    
    // MARK: - Logging Levels
    enum LogLevel: String, CaseIterable {
        case debug = "DEBUG"
        case info = "INFO"
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
        
        var osLogType: OSLogType {
            switch self {
            case .debug: return .debug
            case .info: return .info
            case .warning: return .default
            case .error: return .error
            case .critical: return .fault
            }
        }
    }
    
    // MARK: - Logging Methods
    func log(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(level.rawValue)] \(fileName):\(line) \(function) - \(message)"
        
        // Console logging
        os_log("%{public}@", log: logger, type: level.osLogType, logMessage)
        
        // File logging
        fileLogger.log(level: level, message: logMessage)
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.critical, message, file: file, function: function, line: line)
    }
    
    // MARK: - Activity Logging
    func logActivity(_ activity: String, details: [String: Any] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        let detailsString = details.isEmpty ? "" : " | Details: \(formatDetails(details))"
        info("ACTIVITY: \(activity)\(detailsString)", file: file, function: function, line: line)
    }
    
    func logNetworkEvent(_ event: String, ipAddress: String? = nil, details: [String: Any] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        var eventDetails = details
        if let ip = ipAddress {
            eventDetails["ip_address"] = ip
        }
        eventDetails["event_type"] = "network"
        logActivity("NETWORK_EVENT: \(event)", details: eventDetails, file: file, function: function, line: line)
    }
    
    func logDeviceEvent(_ event: String, deviceIP: String, details: [String: Any] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        var eventDetails = details
        eventDetails["device_ip"] = deviceIP
        eventDetails["event_type"] = "device"
        logActivity("DEVICE_EVENT: \(event)", details: eventDetails, file: file, function: function, line: line)
    }
    
    func logPerformance(_ metric: String, value: Double, unit: String = "", details: [String: Any] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        var eventDetails = details
        eventDetails["metric"] = metric
        eventDetails["value"] = value
        eventDetails["unit"] = unit
        eventDetails["event_type"] = "performance"
        logActivity("PERFORMANCE: \(metric) = \(value)\(unit)", details: eventDetails, file: file, function: function, line: line)
    }
    
    func logError(_ error: Error, context: String = "", file: String = #file, function: String = #function, line: Int = #line) {
        let errorMessage = "ERROR in \(context): \(error.localizedDescription)"
        self.error(errorMessage, file: file, function: function, line: line)
        
        // Log additional error details
        if let nsError = error as NSError? {
            logActivity("ERROR_DETAILS", details: [
                "domain": nsError.domain,
                "code": nsError.code,
                "user_info": nsError.userInfo
            ], file: file, function: function, line: line)
        }
    }
    
    // MARK: - Helper Methods
    private func formatDetails(_ details: [String: Any]) -> String {
        return details.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
    }
    
    // MARK: - Log Management
    func getLogFiles() -> [URL] {
        return fileLogger.getLogFiles()
    }
    
    func clearOldLogs(olderThan days: Int = 7) {
        fileLogger.clearOldLogs(olderThan: days)
    }
    
    func exportLogs() -> Data? {
        return fileLogger.exportLogs()
    }
}

// MARK: - File Logger
class FileLogger {
    private let fileManager = FileManager.default
    private let logDirectory: URL
    
    init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        logDirectory = documentsPath.appendingPathComponent("NetworkSwitchGetter/Logs")
        
        // Create log directory if it doesn't exist
        try? fileManager.createDirectory(at: logDirectory, withIntermediateDirectories: true)
    }
    
    func log(level: NetworkLogger.LogLevel, message: String) {
        let timestamp = DateFormatter.iso8601.string(from: Date())
        let logEntry = "\(timestamp) \(message)\n"
        
        let logFile = getCurrentLogFile()
        
        if let data = logEntry.data(using: .utf8) {
            if fileManager.fileExists(atPath: logFile.path) {
                if let fileHandle = try? FileHandle(forWritingTo: logFile) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: logFile)
            }
        }
    }
    
    private func getCurrentLogFile() -> URL {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return logDirectory.appendingPathComponent("network_switch_getter_\(dateString).log")
    }
    
    func getLogFiles() -> [URL] {
        do {
            let files = try fileManager.contentsOfDirectory(at: logDirectory, includingPropertiesForKeys: [.creationDateKey], options: [])
            return files.filter { $0.pathExtension == "log" }.sorted { file1, file2 in
                let date1 = (try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
        } catch {
            return []
        }
    }
    
    func clearOldLogs(olderThan days: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date.distantPast
        
        for file in getLogFiles() {
            if let creationDate = try? file.resourceValues(forKeys: [.creationDateKey]).creationDate,
               creationDate < cutoffDate {
                try? fileManager.removeItem(at: file)
            }
        }
    }
    
    func exportLogs() -> Data? {
        let allLogs = getLogFiles()
        var combinedLogs = Data()
        
        for logFile in allLogs {
            if let data = try? Data(contentsOf: logFile) {
                combinedLogs.append(data)
            }
        }
        
        return combinedLogs.isEmpty ? nil : combinedLogs
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

// MARK: - Logging Extensions
extension NetworkLogger {
    // MARK: - Network Discovery Logging
    func logScanStart(ipRange: String, totalIPs: Int) {
        logActivity("NETWORK_SCAN_START", details: [
            "ip_range": ipRange,
            "total_ips": totalIPs,
            "scan_id": UUID().uuidString
        ])
    }
    
    func logScanProgress(current: Int, total: Int, percentage: Double) {
        logPerformance("scan_progress", value: percentage, unit: "%", details: [
            "current_ips": current,
            "total_ips": total
        ])
    }
    
    func logScanComplete(discoveredDevices: Int, duration: TimeInterval) {
        logActivity("NETWORK_SCAN_COMPLETE", details: [
            "discovered_devices": discoveredDevices,
            "duration_seconds": duration
        ])
    }
    
    func logDeviceDiscovered(device: NetworkSwitch) {
        logDeviceEvent("DEVICE_DISCOVERED", deviceIP: device.ipAddress, details: [
            "mac_address": device.macAddress,
            "hostname": device.hostname ?? "unknown",
            "vendor": device.vendor ?? "unknown",
            "model": device.model ?? "unknown",
            "port_count": device.portCount ?? 0,
            "capabilities": device.capabilities.map { $0.rawValue }
        ])
    }
    
    func logDeviceStatusChange(device: NetworkSwitch, oldStatus: SwitchStatus, newStatus: SwitchStatus) {
        logDeviceEvent("STATUS_CHANGE", deviceIP: device.ipAddress, details: [
            "old_status": oldStatus.rawValue,
            "new_status": newStatus.rawValue,
            "hostname": device.hostname ?? "unknown"
        ])
    }
    
    // MARK: - Performance Logging
    func logBandwidthUsage(usage: BandwidthUsage) {
        logPerformance("bandwidth_usage", value: usage.totalBandwidthMbps, unit: "Mbps", details: [
            "interface": usage.interfaceName,
            "bytes_in": usage.bytesIn,
            "bytes_out": usage.bytesOut,
            "device_ip": usage.deviceIP
        ])
    }
    
    func logLatencyMeasurement(measurement: LatencyMeasurement) {
        logPerformance("latency", value: measurement.latencyMs, unit: "ms", details: [
            "target_ip": measurement.targetIP,
            "packet_loss": measurement.packetLoss,
            "jitter": measurement.jitter,
            "status": measurement.status.rawValue
        ])
    }
    
    func logNetworkHealth(health: NetworkHealth, score: Int, details: [String: Any] = [:]) {
        logActivity("NETWORK_HEALTH_UPDATE", details: [
            "health_status": health.rawValue,
            "health_score": score,
            "timestamp": Date().timeIntervalSince1970
        ].merging(details) { _, new in new })
    }
    
    // MARK: - Troubleshooting Logging
    func logTroubleshootingStart(device: NetworkSwitch, tests: [TroubleshootingTest]) {
        logDeviceEvent("TROUBLESHOOTING_START", deviceIP: device.ipAddress, details: [
            "tests": tests.map { $0.rawValue },
            "hostname": device.hostname ?? "unknown"
        ])
    }
    
    func logTroubleshootingResult(device: NetworkSwitch, test: TroubleshootingTest, result: TroubleshootingResult) {
        logDeviceEvent("TROUBLESHOOTING_RESULT", deviceIP: device.ipAddress, details: [
            "test_type": test.rawValue,
            "status": result.status.rawValue,
            "message": result.message,
            "details": result.details
        ])
    }
    
    func logTroubleshootingComplete(device: NetworkSwitch, totalTests: Int, passedTests: Int, failedTests: Int) {
        logDeviceEvent("TROUBLESHOOTING_COMPLETE", deviceIP: device.ipAddress, details: [
            "total_tests": totalTests,
            "passed_tests": passedTests,
            "failed_tests": failedTests,
            "success_rate": Double(passedTests) / Double(totalTests) * 100
        ])
    }
}
