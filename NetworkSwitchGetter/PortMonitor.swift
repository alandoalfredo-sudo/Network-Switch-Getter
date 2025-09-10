import Foundation
import Network
import os.log

// MARK: - Port Monitoring Data Models
struct PortConnection: Identifiable, Codable {
    let id = UUID()
    let portNumber: Int
    let macAddress: String
    let ipAddress: String?
    let deviceName: String?
    let switchIP: String
    let switchName: String
    let vlan: Int?
    let speed: String?
    let duplex: String?
    let status: PortStatus
    let lastSeen: Date
    let uptime: TimeInterval?
    
    enum CodingKeys: String, CodingKey {
        case portNumber, macAddress, ipAddress, deviceName, switchIP, switchName
        case vlan, speed, duplex, status, lastSeen, uptime
    }
}

// PortStatus is defined in SwitchModel.swift

struct SwitchPortInfo: Codable {
    let switchIP: String
    let switchName: String
    let totalPorts: Int
    let activePorts: Int
    let ports: [PortConnection]
    let lastUpdated: Date
}

// MARK: - SNMP OID Constants
struct SNMPOIDs {
    // Interface table OIDs
    static let ifIndex = "1.3.6.1.2.1.2.2.1.1"           // ifIndex
    static let ifDescr = "1.3.6.1.2.1.2.2.1.2"           // ifDescr
    static let ifType = "1.3.6.1.2.1.2.2.1.3"            // ifType
    static let ifPhysAddress = "1.3.6.1.2.1.2.2.1.6"     // ifPhysAddress
    static let ifOperStatus = "1.3.6.1.2.1.2.2.1.8"      // ifOperStatus
    static let ifSpeed = "1.3.6.1.2.1.2.2.1.5"           // ifSpeed
    static let ifHighSpeed = "1.3.6.1.2.1.2.1.15"        // ifHighSpeed
    
    // Bridge MIB OIDs for MAC address table
    static let dot1dTpFdbAddress = "1.3.6.1.2.1.17.4.3.1.1"  // dot1dTpFdbAddress
    static let dot1dTpFdbPort = "1.3.6.1.2.1.17.4.3.1.2"     // dot1dTpFdbPort
    static let dot1dTpFdbStatus = "1.3.6.1.2.1.17.4.3.1.3"   // dot1dTpFdbStatus
    
    // IP Address table
    static let ipAdEntAddr = "1.3.6.1.2.1.4.20.1.1"      // ipAdEntAddr
    static let ipAdEntIfIndex = "1.3.6.1.2.1.4.20.1.2"   // ipAdEntIfIndex
    
    // VLAN information
    static let dot1qVlanStaticName = "1.3.6.1.2.1.17.7.1.4.3.1.1"  // dot1qVlanStaticName
    static let dot1qPvid = "1.3.6.1.2.1.17.7.1.4.5.1.1"            // dot1qPvid
}

// MARK: - Port Monitor
@available(macOS 10.15, *)
class PortMonitor: ObservableObject {
    @Published var activeConnections: [PortConnection] = []
    @Published var switchPorts: [String: SwitchPortInfo] = [:]
    @Published var isMonitoring = false
    @Published var lastUpdate: Date = Date()
    @Published var monitoringStats = MonitoringStats()
    
    private let logger = NetworkLogger.shared
    private var monitoringTimer: Timer?
    private let monitoringInterval: TimeInterval = 5.0 // 5 seconds
    private var snmpManager: SNMPManager
    private var discoveredSwitches: [NetworkSwitch] = []
    
    struct MonitoringStats: Codable {
        var totalScans: Int = 0
        var successfulScans: Int = 0
        var failedScans: Int = 0
        var totalConnections: Int = 0
        var lastScanDuration: TimeInterval = 0
        var averageScanDuration: TimeInterval = 0
        var startTime: Date = Date()
        
        var successRate: Double {
            guard totalScans > 0 else { return 0 }
            return Double(successfulScans) / Double(totalScans) * 100
        }
        
        var uptime: TimeInterval {
            Date().timeIntervalSince(startTime)
        }
    }
    
    init() {
        self.snmpManager = SNMPManager()
        logger.info("PortMonitor initialized")
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Public Methods
    func startMonitoring(switches: [NetworkSwitch]) {
        guard !isMonitoring else {
            logger.warning("Port monitoring already running")
            return
        }
        
        self.discoveredSwitches = switches
        isMonitoring = true
        monitoringStats.startTime = Date()
        
        logger.info("Starting port monitoring for \(switches.count) switches")
        
        // Start immediate scan
        performPortScan()
        
        // Set up periodic monitoring
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            self?.performPortScan()
        }
        
        logger.info("Port monitoring started with \(monitoringInterval)s interval")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        logger.info("Port monitoring stopped")
    }
    
    func refreshNow() {
        guard isMonitoring else { return }
        performPortScan()
    }
    
    // MARK: - Filtering Methods
    func filterByMAC(_ macAddress: String) -> [PortConnection] {
        return activeConnections.filter { connection in
            connection.macAddress.lowercased().contains(macAddress.lowercased())
        }
    }
    
    func filterByIP(_ ipAddress: String) -> [PortConnection] {
        return activeConnections.filter { connection in
            connection.ipAddress?.contains(ipAddress) ?? false
        }
    }
    
    func filterBySwitch(_ switchName: String) -> [PortConnection] {
        return activeConnections.filter { connection in
            connection.switchName.lowercased().contains(switchName.lowercased())
        }
    }
    
    func filterByPort(_ portNumber: Int) -> [PortConnection] {
        return activeConnections.filter { connection in
            connection.portNumber == portNumber
        }
    }
    
    // MARK: - Private Methods
    private func performPortScan() {
        let scanStartTime = CFAbsoluteTimeGetCurrent()
        monitoringStats.totalScans += 1
        
        logger.debug("Starting port scan for \(discoveredSwitches.count) switches")
        
        Task {
            var newConnections: [PortConnection] = []
            var newSwitchPorts: [String: SwitchPortInfo] = [:]
            
            for switchDevice in discoveredSwitches {
                do {
                    let switchPortInfo = try await scanSwitchPorts(switchDevice)
                    newSwitchPorts[switchDevice.ipAddress] = switchPortInfo
                    newConnections.append(contentsOf: switchPortInfo.ports)
                    
                    monitoringStats.successfulScans += 1
                    logger.debug("Successfully scanned \(switchDevice.ipAddress) - found \(switchPortInfo.activePorts) active ports")
                } catch {
                    monitoringStats.failedScans += 1
                    logger.error("Failed to scan \(switchDevice.ipAddress): \(error.localizedDescription)")
                }
            }
            
            let scanDuration = CFAbsoluteTimeGetCurrent() - scanStartTime
            monitoringStats.lastScanDuration = scanDuration
            monitoringStats.averageScanDuration = (monitoringStats.averageScanDuration + scanDuration) / 2
            monitoringStats.totalConnections = newConnections.count
            
            await MainActor.run {
                self.activeConnections = newConnections
                self.switchPorts = newSwitchPorts
                self.lastUpdate = Date()
                
                self.logger.info("Port scan completed in \(String(format: "%.2f", scanDuration))s - found \(newConnections.count) active connections")
            }
        }
    }
    
    private func scanSwitchPorts(_ switchDevice: NetworkSwitch) async throws -> SwitchPortInfo {
        logger.debug("Scanning ports for switch: \(switchDevice.ipAddress)")
        
        // Get interface information
        let interfaces = try await snmpManager.walkOID(switchDevice.ipAddress, community: "public", oid: SNMPOIDs.ifIndex)
        
        var ports: [PortConnection] = []
        var activePortCount = 0
        
        for interface in interfaces {
            guard let portNumber = Int(interface.value) else { continue }
            
            // Skip non-physical interfaces (software interfaces, VLANs, etc.)
            if portNumber > 1000 { continue }
            
            do {
                let portInfo = try await getPortInformation(switchDevice, portNumber: portNumber)
                ports.append(portInfo)
                
                if portInfo.status == .up {
                    activePortCount += 1
                }
                
                logger.debug("Port \(portNumber) on \(switchDevice.ipAddress): \(portInfo.status.rawValue) - \(portInfo.macAddress)")
            } catch {
                logger.warning("Failed to get info for port \(portNumber) on \(switchDevice.ipAddress): \(error.localizedDescription)")
            }
        }
        
        let switchPortInfo = SwitchPortInfo(
            switchIP: switchDevice.ipAddress,
            switchName: "Switch-\(switchDevice.ipAddress.components(separatedBy: ".").last ?? "Unknown")",
            totalPorts: ports.count,
            activePorts: activePortCount,
            ports: ports,
            lastUpdated: Date()
        )
        
        return switchPortInfo
    }
    
    private func getPortInformation(_ switchDevice: NetworkSwitch, portNumber: Int) async throws -> PortConnection {
        // Get port description
        let description = try await snmpManager.getOID(switchDevice.ipAddress, community: "public", oid: "\(SNMPOIDs.ifDescr).\(portNumber)")
        
        // Get MAC address
        let macAddress = try await snmpManager.getOID(switchDevice.ipAddress, community: "public", oid: "\(SNMPOIDs.ifPhysAddress).\(portNumber)")
        
        // Get operational status
        let statusValue = try await snmpManager.getOID(switchDevice.ipAddress, community: "public", oid: "\(SNMPOIDs.ifOperStatus).\(portNumber)")
        let status = PortStatus(rawValue: statusValue) ?? .unknown
        
        // Get speed
        let speed = try await snmpManager.getOID(switchDevice.ipAddress, community: "public", oid: "\(SNMPOIDs.ifSpeed).\(portNumber)")
        let speedFormatted = formatSpeed(speed)
        
        // Get VLAN information
        let vlan = try? await snmpManager.getOID(switchDevice.ipAddress, community: "public", oid: "\(SNMPOIDs.dot1qPvid).\(portNumber)")
        let vlanNumber = vlan.flatMap(Int.init)
        
        // Try to find IP address for this MAC
        let ipAddress = try? await findIPForMAC(switchDevice, macAddress: macAddress)
        
        // Try to resolve device name
        let deviceName = try? await resolveDeviceName(ipAddress: ipAddress)
        
        return PortConnection(
            portNumber: portNumber,
            macAddress: macAddress,
            ipAddress: ipAddress,
            deviceName: deviceName,
            switchIP: switchDevice.ipAddress,
            switchName: "Switch-\(switchDevice.ipAddress.components(separatedBy: ".").last ?? "Unknown")",
            vlan: vlanNumber,
            speed: speedFormatted,
            duplex: "auto", // Would need additional SNMP query
            status: status,
            lastSeen: Date(),
            uptime: nil as TimeInterval? // Would need additional SNMP query
        )
    }
    
    private func findIPForMAC(_ switchDevice: NetworkSwitch, macAddress: String) async throws -> String? {
        // This is a simplified implementation
        // In a real scenario, you'd query the ARP table or use other methods
        return nil
    }
    
    private func resolveDeviceName(ipAddress: String?) async throws -> String? {
        guard let ip = ipAddress else { return nil }
        
        // Simple hostname resolution - simplified for compatibility
        return "Device-\(ip.components(separatedBy: ".").last ?? "Unknown")"
    }
    
    private func formatSpeed(_ speedString: String) -> String {
        guard let speed = Int(speedString) else { return "Unknown" }
        
        if speed >= 1000000000 {
            return "\(speed / 1000000000) Gbps"
        } else if speed >= 1000000 {
            return "\(speed / 1000000) Mbps"
        } else if speed >= 1000 {
            return "\(speed / 1000) Kbps"
        } else {
            return "\(speed) bps"
        }
    }
}

// MARK: - SNMP Manager
@available(macOS 10.15, *)
class SNMPManager {
    private let logger = NetworkLogger.shared
    
    func getOID(_ host: String, community: String, oid: String) async throws -> String {
        // This is a simplified implementation
        // In a real scenario, you'd use a proper SNMP library like pysnmp or similar
        
        logger.debug("SNMP GET \(host):\(oid)")
        
        // Simulate SNMP response for demo purposes
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                // Simulate different responses based on OID
                let response = self.simulateSNMPResponse(oid: oid)
                continuation.resume(returning: response)
            }
        }
    }
    
    func walkOID(_ host: String, community: String, oid: String) async throws -> [(oid: String, value: String)] {
        logger.debug("SNMP WALK \(host):\(oid)")
        
        // Simulate SNMP walk response
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
                let response = self.simulateSNMPWalkResponse(oid: oid)
                continuation.resume(returning: response)
            }
        }
    }
    
    private func simulateSNMPResponse(oid: String) -> String {
        // Simulate different responses for demo
        if oid.contains("1.3.6.1.2.1.2.2.1.8") { // ifOperStatus
            return ["1", "2"][Int.random(in: 0...1)] // 1=up, 2=down
        } else if oid.contains("1.3.6.1.2.1.2.2.1.6") { // ifPhysAddress
            return generateRandomMAC()
        } else if oid.contains("1.3.6.1.2.1.2.2.1.5") { // ifSpeed
            return ["1000000000", "100000000", "10000000"][Int.random(in: 0...2)]
        } else if oid.contains("1.3.6.1.2.1.2.2.1.2") { // ifDescr
            return "GigabitEthernet0/\(Int.random(in: 1...24))"
        } else {
            return "Unknown"
        }
    }
    
    private func simulateSNMPWalkResponse(oid: String) -> [(oid: String, value: String)] {
        var results: [(oid: String, value: String)] = []
        
        if oid.contains("1.3.6.1.2.1.2.2.1.1") { // ifIndex
            for i in 1...24 {
                results.append((oid: "\(oid).\(i)", value: "\(i)"))
            }
        }
        
        return results
    }
    
    private func generateRandomMAC() -> String {
        let hexChars = "0123456789ABCDEF"
        var mac = ""
        for i in 0..<6 {
            if i > 0 { mac += ":" }
            for _ in 0..<2 {
                mac += String(hexChars.randomElement()!)
            }
        }
        return mac
    }
}
