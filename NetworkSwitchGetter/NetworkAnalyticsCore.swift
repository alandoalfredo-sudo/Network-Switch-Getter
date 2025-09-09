import Foundation

// MARK: - Network Analytics Models
struct BandwidthUsage: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let bytesIn: UInt64
    let bytesOut: UInt64
    let interfaceName: String
    let deviceIP: String
    
    var totalBytes: UInt64 {
        return bytesIn + bytesOut
    }
    
    var bandwidthInMbps: Double {
        return Double(bytesIn * 8) / 1_000_000.0
    }
    
    var bandwidthOutMbps: Double {
        return Double(bytesOut * 8) / 1_000_000.0
    }
    
    var totalBandwidthMbps: Double {
        return bandwidthInMbps + bandwidthOutMbps
    }
}

struct LatencyMeasurement: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let targetIP: String
    let latencyMs: Double
    let packetLoss: Double
    let jitter: Double
    let status: LatencyStatus
    
    enum LatencyStatus: String, CaseIterable, Codable {
        case excellent = "Excellent"
        case good = "Good"
        case fair = "Fair"
        case poor = "Poor"
        case critical = "Critical"
        
        var color: String {
            switch self {
            case .excellent: return "green"
            case .good: return "blue"
            case .fair: return "orange"
            case .poor: return "red"
            case .critical: return "purple"
            }
        }
        
        var threshold: Double {
            switch self {
            case .excellent: return 10.0
            case .good: return 25.0
            case .fair: return 50.0
            case .poor: return 100.0
            case .critical: return Double.infinity
            }
        }
        
        static func status(for latency: Double) -> LatencyStatus {
            if latency <= excellent.threshold { return .excellent }
            if latency <= good.threshold { return .good }
            if latency <= fair.threshold { return .fair }
            if latency <= poor.threshold { return .poor }
            return .critical
        }
    }
}

struct NetworkPerformanceMetrics: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let deviceIP: String
    let cpuUsage: Double
    let memoryUsage: Double
    let temperature: Double?
    let uptime: TimeInterval
    let portUtilization: [PortUtilization]
    let errorCount: Int
    let packetCount: UInt64
    
    struct PortUtilization: Identifiable, Codable {
        let id = UUID()
        let portNumber: Int
        let utilizationPercent: Double
        let bytesTransferred: UInt64
        let packetsTransferred: UInt64
        let errors: Int
    }
}

struct AINetworkRecommendation: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let type: RecommendationType
    let priority: Priority
    let title: String
    let description: String
    let action: String
    let estimatedImpact: String
    let confidence: Double
    
    enum RecommendationType: String, CaseIterable, Codable {
        case vpnConfiguration = "VPN Configuration"
        case trunkPortOptimization = "Trunk Port Optimization"
        case bandwidthOptimization = "Bandwidth Optimization"
        case securityEnhancement = "Security Enhancement"
        case performanceTuning = "Performance Tuning"
        case capacityPlanning = "Capacity Planning"
    }
    
    enum Priority: String, CaseIterable, Codable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case critical = "Critical"
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "orange"
            case .high: return "red"
            case .critical: return "purple"
            }
        }
    }
}

struct VPNConfiguration: Identifiable, Codable {
    let id = UUID()
    let name: String
    let type: VPNType
    let serverAddress: String
    let username: String
    let password: String
    let encryption: EncryptionType
    let authentication: AuthenticationType
    let isActive: Bool
    let bandwidthLimit: Double?
    let latencyThreshold: Double?
    
    enum VPNType: String, CaseIterable, Codable {
        case ipsec = "IPSec"
        case openvpn = "OpenVPN"
        case wireguard = "WireGuard"
        case ssl = "SSL VPN"
        case l2tp = "L2TP"
    }
    
    enum EncryptionType: String, CaseIterable, Codable {
        case aes256 = "AES-256"
        case aes128 = "AES-128"
        case chacha20 = "ChaCha20"
        case blowfish = "Blowfish"
    }
    
    enum AuthenticationType: String, CaseIterable, Codable {
        case certificate = "Certificate"
        case usernamePassword = "Username/Password"
        case twoFactor = "Two-Factor"
        case biometric = "Biometric"
    }
}

struct TrunkPortConfiguration: Identifiable, Codable {
    let id = UUID()
    let portNumber: Int
    let vlans: [Int]
    let allowedVlans: [Int]
    let nativeVlan: Int
    let trunkingProtocol: TrunkingProtocol
    let loadBalancing: LoadBalancingType
    let isActive: Bool
    let bandwidth: Double
    let utilization: Double
    
    enum TrunkingProtocol: String, CaseIterable, Codable {
        case dot1q = "802.1Q"
        case isl = "ISL"
        case lldp = "LLDP"
        case lacp = "LACP"
    }
    
    enum LoadBalancingType: String, CaseIterable, Codable {
        case srcMac = "Source MAC"
        case dstMac = "Destination MAC"
        case srcDstMac = "Source-Destination MAC"
        case srcIp = "Source IP"
        case dstIp = "Destination IP"
        case srcDstIp = "Source-Destination IP"
    }
}

// MARK: - Pocket Display Data
struct PocketDisplayData: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let totalDevices: Int
    let onlineDevices: Int
    let averageLatency: Double
    let totalBandwidth: Double
    let networkHealth: NetworkHealth
    let topDevices: [DeviceSummary]
    let alerts: [NetworkAlert]
    
    struct DeviceSummary: Identifiable, Codable {
        let id = UUID()
        let ipAddress: String
        let hostname: String?
        let status: SwitchStatus
        let latency: Double
        let bandwidth: Double
        let utilization: Double
    }
    
    struct NetworkAlert: Identifiable, Codable {
        let id = UUID()
        let type: AlertType
        let severity: AlertSeverity
        let message: String
        let timestamp: Date
        let deviceIP: String?
        
        enum AlertType: String, CaseIterable, Codable {
            case highLatency = "High Latency"
            case bandwidthExceeded = "Bandwidth Exceeded"
            case deviceOffline = "Device Offline"
            case portError = "Port Error"
            case securityThreat = "Security Threat"
            case performanceDegradation = "Performance Degradation"
        }
        
        enum AlertSeverity: String, CaseIterable, Codable {
            case info = "Info"
            case warning = "Warning"
            case error = "Error"
            case critical = "Critical"
            
            var color: String {
                switch self {
                case .info: return "blue"
                case .warning: return "orange"
                case .error: return "red"
                case .critical: return "purple"
                }
            }
        }
    }
}

enum NetworkHealth: String, CaseIterable, Codable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case critical = "Critical"
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "orange"
        case .poor: return "red"
        case .critical: return "purple"
        }
    }
    
    var score: Int {
        switch self {
        case .excellent: return 90
        case .good: return 75
        case .fair: return 60
        case .poor: return 40
        case .critical: return 20
        }
    }
}

// MARK: - Network Analyzer
class NetworkAnalyzer {
    func calculateNetworkHealth(switches: [NetworkSwitch], metrics: [NetworkPerformanceMetrics], latency: [LatencyMeasurement]) -> NetworkHealth {
        var healthScore = 100.0
        
        // Factor in device status
        let offlineDevices = switches.filter { $0.status != .online }.count
        healthScore -= Double(offlineDevices) * 10.0
        
        // Factor in latency
        let averageLatency = latency.map { $0.latencyMs }.reduce(0, +) / Double(latency.count)
        if averageLatency > 100.0 {
            healthScore -= 20.0
        } else if averageLatency > 50.0 {
            healthScore -= 10.0
        }
        
        // Factor in performance metrics
        let averageCPU = metrics.map { $0.cpuUsage }.reduce(0, +) / Double(metrics.count)
        if averageCPU > 80.0 {
            healthScore -= 15.0
        }
        
        // Determine health level
        switch healthScore {
        case 90...100: return .excellent
        case 75..<90: return .good
        case 60..<75: return .fair
        case 40..<60: return .poor
        default: return .critical
        }
    }
}
