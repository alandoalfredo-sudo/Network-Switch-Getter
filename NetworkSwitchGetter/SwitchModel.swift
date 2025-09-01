import Foundation
import Network

// MARK: - Switch Model
struct NetworkSwitch: Identifiable, Codable {
    let id = UUID()
    let ipAddress: String
    let macAddress: String
    let hostname: String?
    let vendor: String?
    let model: String?
    let firmwareVersion: String?
    let portCount: Int?
    let status: SwitchStatus
    let lastSeen: Date
    let responseTime: TimeInterval?
    let capabilities: [SwitchCapability]
    
    init(ipAddress: String, macAddress: String, hostname: String? = nil, vendor: String? = nil, model: String? = nil, firmwareVersion: String? = nil, portCount: Int? = nil, status: SwitchStatus = .unknown, responseTime: TimeInterval? = nil, capabilities: [SwitchCapability] = []) {
        self.ipAddress = ipAddress
        self.macAddress = macAddress
        self.hostname = hostname
        self.vendor = vendor
        self.model = model
        self.firmwareVersion = firmwareVersion
        self.portCount = portCount
        self.status = status
        self.lastSeen = Date()
        self.responseTime = responseTime
        self.capabilities = capabilities
    }
}

// MARK: - Switch Status
enum SwitchStatus: String, CaseIterable, Codable {
    case online = "Online"
    case offline = "Offline"
    case unknown = "Unknown"
    case error = "Error"
    
    var color: String {
        switch self {
        case .online: return "green"
        case .offline: return "red"
        case .unknown: return "orange"
        case .error: return "red"
        }
    }
}

// MARK: - Switch Capabilities
enum SwitchCapability: String, CaseIterable, Codable {
    case snmp = "SNMP"
    case ssh = "SSH"
    case telnet = "Telnet"
    case webInterface = "Web Interface"
    case cdp = "CDP"
    case lldp = "LLDP"
    case stp = "STP"
    case vlan = "VLAN"
    case qos = "QoS"
    case poe = "PoE"
    case stacking = "Stacking"
    case lacp = "LACP"
    case spanningTree = "Spanning Tree"
    case portMirroring = "Port Mirroring"
    case accessControl = "Access Control"
    case monitoring = "Monitoring"
}

// MARK: - Port Information
struct PortInfo: Identifiable, Codable {
    let id = UUID()
    let portNumber: Int
    let status: PortStatus
    let speed: String?
    let duplex: String?
    let vlan: String?
    let connectedDevice: String?
    let macAddress: String?
    let lastActivity: Date?
    
    init(portNumber: Int, status: PortStatus, speed: String? = nil, duplex: String? = nil, vlan: String? = nil, connectedDevice: String? = nil, macAddress: String? = nil, lastActivity: Date? = nil) {
        self.portNumber = portNumber
        self.status = status
        self.speed = speed
        self.duplex = duplex
        self.vlan = vlan
        self.connectedDevice = connectedDevice
        self.macAddress = macAddress
        self.lastActivity = lastActivity
    }
}

// MARK: - Port Status
enum PortStatus: String, CaseIterable, Codable {
    case up = "Up"
    case down = "Down"
    case disabled = "Disabled"
    case unknown = "Unknown"
    
    var color: String {
        switch self {
        case .up: return "green"
        case .down: return "red"
        case .disabled: return "gray"
        case .unknown: return "orange"
        }
    }
}

// MARK: - Network Interface
struct NetworkInterface: Identifiable, Codable {
    let id = UUID()
    let name: String
    let ipAddress: String
    let subnetMask: String
    let gateway: String?
    let dnsServers: [String]
    let isActive: Bool
    
    init(name: String, ipAddress: String, subnetMask: String, gateway: String? = nil, dnsServers: [String] = [], isActive: Bool = true) {
        self.name = name
        self.ipAddress = ipAddress
        self.subnetMask = subnetMask
        self.gateway = gateway
        self.dnsServers = dnsServers
        self.isActive = isActive
    }
}

// MARK: - Troubleshooting Result
struct TroubleshootingResult: Identifiable, Codable {
    let id = UUID()
    let testType: TroubleshootingTest
    let status: TestStatus
    let message: String
    let timestamp: Date
    let details: [String: String]
    
    init(testType: TroubleshootingTest, status: TestStatus, message: String, details: [String: String] = [:]) {
        self.testType = testType
        self.status = status
        self.message = message
        self.timestamp = Date()
        self.details = details
    }
}

// MARK: - Troubleshooting Test Types
enum TroubleshootingTest: String, CaseIterable, Codable {
    case ping = "Ping Test"
    case portScan = "Port Scan"
    case snmpQuery = "SNMP Query"
    case sshConnection = "SSH Connection"
    case webInterface = "Web Interface"
    case dnsResolution = "DNS Resolution"
    case arpTable = "ARP Table"
    case routingTable = "Routing Table"
    case interfaceStatus = "Interface Status"
    case bandwidthTest = "Bandwidth Test"
}

// MARK: - Test Status
enum TestStatus: String, CaseIterable, Codable {
    case passed = "Passed"
    case failed = "Failed"
    case warning = "Warning"
    case skipped = "Skipped"
    
    var color: String {
        switch self {
        case .passed: return "green"
        case .failed: return "red"
        case .warning: return "orange"
        case .skipped: return "gray"
        }
    }
}

// MARK: - Discovery Settings
struct DiscoverySettings: Codable {
    var scanRange: String
    var timeout: TimeInterval
    var maxConcurrentScans: Int
    var enableSNMP: Bool
    var enableSSH: Bool
    var enableWebInterface: Bool
    var customPorts: [Int]
    var retryCount: Int
    
    init() {
        self.scanRange = "192.168.1.0/24"
        self.timeout = 5.0
        self.maxConcurrentScans = 50
        self.enableSNMP = true
        self.enableSSH = true
        self.enableWebInterface = true
        self.customPorts = [22, 23, 80, 443, 161, 162]
        self.retryCount = 3
    }
}
