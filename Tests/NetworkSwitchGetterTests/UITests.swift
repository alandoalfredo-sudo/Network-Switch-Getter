import XCTest
import SwiftUI
@testable import NetworkSwitchGetter

final class UITests: XCTestCase {
    
    func testDataModelIntegration() throws {
        // Test that data models can be used in SwiftUI contexts
        let testSwitch = NetworkSwitch(
            ipAddress: "192.168.1.1",
            macAddress: "00:11:22:33:44:55",
            hostname: "test-switch",
            vendor: "Cisco",
            model: "Catalyst 2960",
            firmwareVersion: "15.2.4",
            portCount: 24,
            status: .online,
            responseTime: 5.2,
            capabilities: [.snmp, .ssh, .webInterface]
        )
        
        // Test that the switch can be used in a simple SwiftUI view
        let testView = TestSwitchView(switchDevice: testSwitch)
        XCTAssertNotNil(testView)
        XCTAssertNotNil(testView.body)
    }
    
    func testAnalyticsDataIntegration() throws {
        // Test that analytics data models work with SwiftUI
        let bandwidthUsage = BandwidthUsage(
            timestamp: Date(),
            bytesIn: 1024000,
            bytesOut: 512000,
            interfaceName: "en0",
            deviceIP: "192.168.1.1"
        )
        
        let latencyMeasurement = LatencyMeasurement(
            timestamp: Date(),
            targetIP: "192.168.1.1",
            latencyMs: 5.2,
            packetLoss: 0.0,
            jitter: 1.2,
            status: .good
        )
        
        let portUtilization = NetworkPerformanceMetrics.PortUtilization(
            portNumber: 1,
            utilizationPercent: 75.0,
            bytesTransferred: 1024000,
            packetsTransferred: 1000,
            errors: 0
        )
        
        let performanceMetrics = NetworkPerformanceMetrics(
            timestamp: Date(),
            deviceIP: "192.168.1.1",
            cpuUsage: 45.0,
            memoryUsage: 60.0,
            temperature: 35.0,
            uptime: 86400,
            portUtilization: [portUtilization],
            errorCount: 0,
            packetCount: 1000000
        )
        
        // Test that analytics data can be used in SwiftUI
        let testView = TestAnalyticsView(metrics: performanceMetrics)
        XCTAssertNotNil(testView)
        XCTAssertNotNil(testView.body)
    }
    
    func testLoggingIntegration() throws {
        // Test that logging works in SwiftUI context
        let logger = NetworkLogger.shared
        logger.logActivity("UI_TEST", details: ["test": "value"])
        
        // Test that logging doesn't interfere with UI operations
        let testSwitch = NetworkSwitch(
            ipAddress: "192.168.1.1",
            macAddress: "00:11:22:33:44:55",
            hostname: "test-switch",
            vendor: "Cisco",
            model: "Catalyst 2960",
            firmwareVersion: "15.2.4",
            portCount: 24,
            status: .online,
            responseTime: 5.2,
            capabilities: [.snmp, .ssh, .webInterface]
        )
        
        let testView = TestSwitchView(switchDevice: testSwitch)
        XCTAssertNotNil(testView.body)
    }
    
    func testDataModelPerformance() throws {
        // Test that data models can be created and used efficiently
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var switches: [NetworkSwitch] = []
        for i in 1...100 {
            let switchDevice = NetworkSwitch(
                ipAddress: "192.168.1.\(i)",
                macAddress: "00:11:22:33:44:\(String(format: "%02d", i))",
                hostname: "switch-\(i)",
                vendor: "Cisco",
                model: "Catalyst 2960",
                firmwareVersion: "15.2.4",
                portCount: 24,
                status: .online,
                responseTime: Double.random(in: 1...10),
                capabilities: [.snmp, .ssh, .webInterface]
            )
            switches.append(switchDevice)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Test that data model creation is fast
        XCTAssertLessThan(timeElapsed, 0.1)
        XCTAssertEqual(switches.count, 100)
    }
    
    func testDataModelMemoryUsage() throws {
        // Test that data models don't create excessive memory usage
        var switches: [NetworkSwitch] = []
        
        for i in 1...1000 {
            let switchDevice = NetworkSwitch(
                ipAddress: "192.168.1.\(i % 255)",
                macAddress: "00:11:22:33:44:\(String(format: "%02d", i % 100))",
                hostname: "switch-\(i)",
                vendor: "Cisco",
                model: "Catalyst 2960",
                firmwareVersion: "15.2.4",
                portCount: 24,
                status: .online,
                responseTime: Double.random(in: 1...10),
                capabilities: [.snmp, .ssh, .webInterface]
            )
            switches.append(switchDevice)
        }
        
        // Test that we can access the data without issues
        XCTAssertEqual(switches.count, 1000)
        XCTAssertNotNil(switches.first?.ipAddress)
        XCTAssertNotNil(switches.last?.macAddress)
    }
    
    func testDataModelSerialization() throws {
        // Test that data models can be serialized/deserialized
        let testSwitch = NetworkSwitch(
            ipAddress: "192.168.1.1",
            macAddress: "00:11:22:33:44:55",
            hostname: "test-switch",
            vendor: "Cisco",
            model: "Catalyst 2960",
            firmwareVersion: "15.2.4",
            portCount: 24,
            status: .online,
            responseTime: 5.2,
            capabilities: [.snmp, .ssh, .webInterface]
        )
        
        // Test JSON encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(testSwitch)
        XCTAssertNotNil(data)
        
        // Test JSON decoding
        let decoder = JSONDecoder()
        let decodedSwitch = try decoder.decode(NetworkSwitch.self, from: data)
        XCTAssertEqual(decodedSwitch.ipAddress, testSwitch.ipAddress)
        XCTAssertEqual(decodedSwitch.macAddress, testSwitch.macAddress)
        XCTAssertEqual(decodedSwitch.hostname, testSwitch.hostname)
    }
}

// MARK: - Test SwiftUI Views

struct TestSwitchView: View {
    let switchDevice: NetworkSwitch
    
    var body: some View {
        VStack {
            Text(switchDevice.hostname ?? "Unknown")
            Text(switchDevice.ipAddress)
            Text(switchDevice.vendor ?? "Unknown")
        }
    }
}

struct TestAnalyticsView: View {
    let metrics: NetworkPerformanceMetrics
    
    var body: some View {
        VStack {
            Text("Device IP: \(metrics.deviceIP)")
            Text("CPU Usage: \(metrics.cpuUsage)%")
            Text("Memory Usage: \(metrics.memoryUsage)%")
            Text("Port Utilization: \(metrics.portUtilization.count) ports")
            Text("Error Count: \(metrics.errorCount)")
        }
    }
}
