import Foundation
import os.log

// MARK: - Port Monitoring Logger
@available(macOS 10.15, *)
class PortMonitoringLogger {
    static let shared = PortMonitoringLogger()
    
    private let logger = NetworkLogger.shared
    private let fileLogger: FileLogger
    private let logQueue = DispatchQueue(label: "com.networkswitchgetter.portmonitor.log", qos: .utility)
    
    private init() {
        self.fileLogger = FileLogger()
        logger.info("PortMonitoringLogger initialized")
    }
    
    // MARK: - Port Connection Logging
    func logPortConnection(_ connection: PortConnection, event: PortEvent) {
        let logMessage = """
        Port Event: \(event.rawValue)
        Switch: \(connection.switchName) (\(connection.switchIP))
        Port: \(connection.portNumber)
        MAC: \(connection.macAddress)
        IP: \(connection.ipAddress ?? "N/A")
        Device: \(connection.deviceName ?? "Unknown")
        Status: \(connection.status.rawValue)
        VLAN: \(connection.vlan?.description ?? "N/A")
        Speed: \(connection.speed ?? "Unknown")
        """
        
        switch event {
        case .connected:
            logger.info("Port connected: \(logMessage)")
            fileLogger.log(level: .info, message: logMessage)
        case .disconnected:
            logger.warning("Port disconnected: \(logMessage)")
            fileLogger.log(level: .warning, message: logMessage)
        case .statusChanged:
            logger.info("Port status changed: \(logMessage)")
            fileLogger.log(level: .info, message: logMessage)
        case .error:
            logger.error("Port error: \(logMessage)")
            fileLogger.log(level: .error, message: logMessage)
        }
    }
    
    func logPortScan(_ switchInfo: SwitchPortInfo, duration: TimeInterval) {
        let logMessage = """
        Port Scan Completed
        Switch: \(switchInfo.switchName) (\(switchInfo.switchIP))
        Total Ports: \(switchInfo.totalPorts)
        Active Ports: \(switchInfo.activePorts)
        Duration: \(String(format: "%.2f", duration))s
        """
        
        logger.info("Port scan completed: \(logMessage)")
        fileLogger.log(level: .info, message: logMessage)
    }
    
    func logMonitoringStats(_ stats: PortMonitor.MonitoringStats) {
        let logMessage = """
        Monitoring Statistics
        Total Scans: \(stats.totalScans)
        Successful: \(stats.successfulScans)
        Failed: \(stats.failedScans)
        Success Rate: \(String(format: "%.1f", stats.successRate))%
        Average Duration: \(String(format: "%.2f", stats.averageScanDuration))s
        Uptime: \(String(format: "%.0f", stats.uptime))s
        """
        
        logger.info("Monitoring stats: \(logMessage)")
        fileLogger.log(level: .info, message: logMessage)
    }
    
    // MARK: - Filter and Search Logging
    func logFilterApplied(filters: [String: String]) {
        let filterString = filters.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let logMessage = "Filter applied: \(filterString)"
        
        logger.info("Filter applied: \(logMessage)")
        fileLogger.log(level: .info, message: logMessage)
    }
    
    func logDataExport(connections: [PortConnection], format: String) {
        let logMessage = """
        Data Export
        Format: \(format)
        Connections: \(connections.count)
        Timestamp: \(Date().iso8601String)
        """
        
        logger.info("Data exported: \(logMessage)")
        fileLogger.log(level: .info, message: logMessage)
    }
    
    // MARK: - Error Logging
    func logSNMPError(switchIP: String, port: Int, error: Error) {
        let logMessage = """
        SNMP Error
        Switch: \(switchIP)
        Port: \(port)
        Error: \(error.localizedDescription)
        """
        
        logger.error("SNMP error: \(logMessage)")
        fileLogger.log(level: .error, message: logMessage)
    }
    
    func logConnectionError(switchIP: String, error: Error) {
        let logMessage = """
        Connection Error
        Switch: \(switchIP)
        Error: \(error.localizedDescription)
        """
        
        logger.error("Connection error: \(logMessage)")
        fileLogger.log(level: .error, message: logMessage)
    }
    
    // MARK: - Performance Logging
    func logPerformance(operation: String, duration: TimeInterval, details: String = "") {
        let logMessage = """
        Performance: \(operation)
        Duration: \(String(format: "%.3f", duration))s
        Details: \(details)
        """
        
        if duration > 1.0 {
            logger.warning("Slow operation: \(logMessage)")
            fileLogger.log(level: .warning, message: logMessage)
        } else {
            logger.debug("Performance: \(logMessage)")
            fileLogger.log(level: .debug, message: logMessage)
        }
    }
    
    // MARK: - System Events
    func logMonitoringStarted(switches: [NetworkSwitch]) {
        let switchList = switches.map { "\($0.ipAddress)" }.joined(separator: ", ")
        let logMessage = """
        Monitoring Started
        Switches: \(switchList)
        Count: \(switches.count)
        """
        
        logger.info("Monitoring started: \(logMessage)")
        fileLogger.log(level: .info, message: logMessage)
    }
    
    func logMonitoringStopped() {
        let logMessage = "Monitoring stopped"
        logger.info("Monitoring stopped: \(logMessage)")
        fileLogger.log(level: .info, message: logMessage)
    }
    
    // MARK: - Alert Logging
    func logAlert(_ alert: PortAlert) {
        let logMessage = """
        Port Alert
        Type: \(alert.type.rawValue)
        Severity: \(alert.severity.rawValue)
        Switch: \(alert.switchName) (\(alert.switchIP))
        Port: \(alert.portNumber)
        Message: \(alert.message)
        """
        
        switch alert.severity {
        case .critical:
            logger.error("Critical alert: \(logMessage)")
            fileLogger.log(level: .error, message: logMessage)
        case .warning:
            logger.warning("Warning alert: \(logMessage)")
            fileLogger.log(level: .warning, message: logMessage)
        case .info:
            logger.info("Info alert: \(logMessage)")
            fileLogger.log(level: .info, message: logMessage)
        }
    }
}

// MARK: - Supporting Types
enum PortEvent: String, CaseIterable {
    case connected = "connected"
    case disconnected = "disconnected"
    case statusChanged = "status_changed"
    case error = "error"
}

struct PortAlert {
    let type: AlertType
    let severity: AlertSeverity
    let switchName: String
    let switchIP: String
    let portNumber: Int
    let message: String
    let timestamp: Date
    
    init(type: AlertType, severity: AlertSeverity, switchName: String, switchIP: String, portNumber: Int, message: String) {
        self.type = type
        self.severity = severity
        self.switchName = switchName
        self.switchIP = switchIP
        self.portNumber = portNumber
        self.message = message
        self.timestamp = Date()
    }
}

enum AlertType: String, CaseIterable {
    case portDown = "port_down"
    case portUp = "port_up"
    case macAddressChanged = "mac_changed"
    case highUtilization = "high_utilization"
    case snmpError = "snmp_error"
    case connectionLost = "connection_lost"
}

enum AlertSeverity: String, CaseIterable {
    case critical = "critical"
    case warning = "warning"
    case info = "info"
}

// MARK: - File Logger Extension
extension FileLogger {
    func logPortConnection(_ connection: PortConnection, event: PortEvent) {
        let timestamp = Date().iso8601String
        let logEntry = """
        [\(timestamp)] PORT_\(event.rawValue.uppercased())
        Switch: \(connection.switchName) (\(connection.switchIP))
        Port: \(connection.portNumber)
        MAC: \(connection.macAddress)
        IP: \(connection.ipAddress ?? "N/A")
        Status: \(connection.status.rawValue)
        VLAN: \(connection.vlan?.description ?? "N/A")
        Speed: \(connection.speed ?? "Unknown")
        ---
        """
        
        log(level: .info, message: logEntry)
    }
    
    func logPortScan(_ switchInfo: SwitchPortInfo, duration: TimeInterval) {
        let timestamp = Date().iso8601String
        let logEntry = """
        [\(timestamp)] PORT_SCAN
        Switch: \(switchInfo.switchName) (\(switchInfo.switchIP))
        Total Ports: \(switchInfo.totalPorts)
        Active Ports: \(switchInfo.activePorts)
        Duration: \(String(format: "%.2f", duration))s
        ---
        """
        
        log(level: .info, message: logEntry)
    }
    
    func logMonitoringStats(_ stats: PortMonitor.MonitoringStats) {
        let timestamp = Date().iso8601String
        let logEntry = """
        [\(timestamp)] MONITORING_STATS
        Total Scans: \(stats.totalScans)
        Successful: \(stats.successfulScans)
        Failed: \(stats.failedScans)
        Success Rate: \(String(format: "%.1f", stats.successRate))%
        Average Duration: \(String(format: "%.2f", stats.averageScanDuration))s
        Uptime: \(String(format: "%.0f", stats.uptime))s
        ---
        """
        
        log(level: .info, message: logEntry)
    }
}

// MARK: - Date Extension
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}