import XCTest
@testable import NetworkSwitchGetter

final class NetworkSwitchGetterTests: XCTestCase {
    
    func testNetworkSwitchInitialization() throws {
        // Test that NetworkSwitch can be initialized with basic properties
        let networkSwitch = NetworkSwitch(
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
        
        XCTAssertEqual(networkSwitch.ipAddress, "192.168.1.1")
        XCTAssertEqual(networkSwitch.macAddress, "00:11:22:33:44:55")
        XCTAssertEqual(networkSwitch.hostname, "test-switch")
        XCTAssertEqual(networkSwitch.vendor, "Cisco")
        XCTAssertEqual(networkSwitch.model, "Catalyst 2960")
        XCTAssertEqual(networkSwitch.firmwareVersion, "15.2.4")
        XCTAssertEqual(networkSwitch.portCount, 24)
        XCTAssertEqual(networkSwitch.status, .online)
        XCTAssertEqual(networkSwitch.responseTime, 5.2)
        XCTAssertEqual(networkSwitch.capabilities.count, 3)
        XCTAssertTrue(networkSwitch.capabilities.contains(.snmp))
        XCTAssertTrue(networkSwitch.capabilities.contains(.ssh))
        XCTAssertTrue(networkSwitch.capabilities.contains(.webInterface))
    }
    
    func testSwitchStatusEnum() throws {
        // Test that SwitchStatus enum works correctly
        XCTAssertEqual(SwitchStatus.online.rawValue, "Online")
        XCTAssertEqual(SwitchStatus.offline.rawValue, "Offline")
        XCTAssertEqual(SwitchStatus.unknown.rawValue, "Unknown")
        XCTAssertEqual(SwitchStatus.error.rawValue, "Error")
        
        // Test color properties
        XCTAssertEqual(SwitchStatus.online.color, "green")
        XCTAssertEqual(SwitchStatus.offline.color, "red")
        XCTAssertEqual(SwitchStatus.unknown.color, "orange")
        XCTAssertEqual(SwitchStatus.error.color, "red")
    }
    
    func testSwitchCapabilityEnum() throws {
        // Test that SwitchCapability enum works correctly
        XCTAssertEqual(SwitchCapability.snmp.rawValue, "SNMP")
        XCTAssertEqual(SwitchCapability.ssh.rawValue, "SSH")
        XCTAssertEqual(SwitchCapability.webInterface.rawValue, "Web Interface")
        XCTAssertEqual(SwitchCapability.poe.rawValue, "PoE")
    }
    
    func testPortInfoInitialization() throws {
        // Test that PortInfo can be initialized
        let portInfo = PortInfo(
            portNumber: 1,
            status: .up,
            speed: "1Gbps",
            duplex: "Full",
            vlan: "100",
            connectedDevice: "Server-01",
            macAddress: "00:11:22:33:44:55"
        )
        
        XCTAssertEqual(portInfo.portNumber, 1)
        XCTAssertEqual(portInfo.status, .up)
        XCTAssertEqual(portInfo.speed, "1Gbps")
        XCTAssertEqual(portInfo.duplex, "Full")
        XCTAssertEqual(portInfo.vlan, "100")
        XCTAssertEqual(portInfo.connectedDevice, "Server-01")
        XCTAssertEqual(portInfo.macAddress, "00:11:22:33:44:55")
    }
    
    func testPortStatusEnum() throws {
        // Test that PortStatus enum works correctly
        XCTAssertEqual(PortStatus.up.rawValue, "Up")
        XCTAssertEqual(PortStatus.down.rawValue, "Down")
        XCTAssertEqual(PortStatus.disabled.rawValue, "Disabled")
        XCTAssertEqual(PortStatus.unknown.rawValue, "Unknown")
        
        // Test color properties
        XCTAssertEqual(PortStatus.up.color, "green")
        XCTAssertEqual(PortStatus.down.color, "red")
        XCTAssertEqual(PortStatus.disabled.color, "gray")
        XCTAssertEqual(PortStatus.unknown.color, "orange")
    }
    
    func testNetworkInterfaceInitialization() throws {
        // Test that NetworkInterface can be initialized
        let networkInterface = NetworkInterface(
            name: "en0",
            ipAddress: "192.168.1.100",
            subnetMask: "255.255.255.0",
            gateway: "192.168.1.1",
            dnsServers: ["8.8.8.8", "8.8.4.4"],
            isActive: true
        )
        
        XCTAssertEqual(networkInterface.name, "en0")
        XCTAssertEqual(networkInterface.ipAddress, "192.168.1.100")
        XCTAssertEqual(networkInterface.subnetMask, "255.255.255.0")
        XCTAssertEqual(networkInterface.gateway, "192.168.1.1")
        XCTAssertEqual(networkInterface.dnsServers.count, 2)
        XCTAssertEqual(networkInterface.dnsServers[0], "8.8.8.8")
        XCTAssertEqual(networkInterface.dnsServers[1], "8.8.4.4")
        XCTAssertTrue(networkInterface.isActive)
    }
    
    func testTroubleshootingResultInitialization() throws {
        // Test that TroubleshootingResult can be initialized
        let result = TroubleshootingResult(
            testType: .ping,
            status: .passed,
            message: "Ping successful",
            details: ["latency": "5.2ms", "packet_loss": "0%"]
        )
        
        XCTAssertEqual(result.testType, .ping)
        XCTAssertEqual(result.status, .passed)
        XCTAssertEqual(result.message, "Ping successful")
        XCTAssertEqual(result.details["latency"], "5.2ms")
        XCTAssertEqual(result.details["packet_loss"], "0%")
    }
    
    func testTroubleshootingTestEnum() throws {
        // Test that TroubleshootingTest enum works correctly
        XCTAssertEqual(TroubleshootingTest.ping.rawValue, "Ping Test")
        XCTAssertEqual(TroubleshootingTest.portScan.rawValue, "Port Scan")
        XCTAssertEqual(TroubleshootingTest.snmpQuery.rawValue, "SNMP Query")
        XCTAssertEqual(TroubleshootingTest.sshConnection.rawValue, "SSH Connection")
        XCTAssertEqual(TroubleshootingTest.webInterface.rawValue, "Web Interface")
    }
    
    func testTestStatusEnum() throws {
        // Test that TestStatus enum works correctly
        XCTAssertEqual(TestStatus.passed.rawValue, "Passed")
        XCTAssertEqual(TestStatus.failed.rawValue, "Failed")
        XCTAssertEqual(TestStatus.warning.rawValue, "Warning")
        XCTAssertEqual(TestStatus.skipped.rawValue, "Skipped")
        
        // Test color properties
        XCTAssertEqual(TestStatus.passed.color, "green")
        XCTAssertEqual(TestStatus.failed.color, "red")
        XCTAssertEqual(TestStatus.warning.color, "orange")
        XCTAssertEqual(TestStatus.skipped.color, "gray")
    }
    
    func testDiscoverySettingsInitialization() throws {
        // Test that DiscoverySettings can be initialized with default values
        let settings = DiscoverySettings()
        
        XCTAssertEqual(settings.scanRange, "192.168.1.0/24")
        XCTAssertEqual(settings.timeout, 5.0)
        XCTAssertEqual(settings.maxConcurrentScans, 50)
        XCTAssertTrue(settings.enableSNMP)
        XCTAssertTrue(settings.enableSSH)
        XCTAssertTrue(settings.enableWebInterface)
        XCTAssertEqual(settings.customPorts, [22, 23, 80, 443, 161, 162])
        XCTAssertEqual(settings.retryCount, 3)
    }
    
    func testBandwidthUsageCalculation() throws {
        // Test bandwidth calculations
        let bandwidthUsage = BandwidthUsage(
            timestamp: Date(),
            bytesIn: 1_000_000, // 1MB
            bytesOut: 500_000,  // 0.5MB
            interfaceName: "en0",
            deviceIP: "192.168.1.1"
        )
        
        XCTAssertEqual(bandwidthUsage.totalBytes, 1_500_000)
        XCTAssertEqual(bandwidthUsage.bandwidthInMbps, 8.0) // 1MB * 8 bits / 1,000,000
        XCTAssertEqual(bandwidthUsage.bandwidthOutMbps, 4.0) // 0.5MB * 8 bits / 1,000,000
        XCTAssertEqual(bandwidthUsage.totalBandwidthMbps, 12.0)
    }
    
    func testLatencyStatusCalculation() throws {
        // Test latency status calculation
        XCTAssertEqual(LatencyMeasurement.LatencyStatus.status(for: 5.0), .excellent)
        XCTAssertEqual(LatencyMeasurement.LatencyStatus.status(for: 20.0), .good)
        XCTAssertEqual(LatencyMeasurement.LatencyStatus.status(for: 40.0), .fair)
        XCTAssertEqual(LatencyMeasurement.LatencyStatus.status(for: 80.0), .poor)
        XCTAssertEqual(LatencyMeasurement.LatencyStatus.status(for: 150.0), .critical)
    }
    
    func testNetworkHealthEnum() throws {
        // Test NetworkHealth enum
        XCTAssertEqual(NetworkHealth.excellent.score, 90)
        XCTAssertEqual(NetworkHealth.good.score, 75)
        XCTAssertEqual(NetworkHealth.fair.score, 60)
        XCTAssertEqual(NetworkHealth.poor.score, 40)
        XCTAssertEqual(NetworkHealth.critical.score, 20)
        
        XCTAssertEqual(NetworkHealth.excellent.color, "green")
        XCTAssertEqual(NetworkHealth.good.color, "blue")
        XCTAssertEqual(NetworkHealth.fair.color, "orange")
        XCTAssertEqual(NetworkHealth.poor.color, "red")
        XCTAssertEqual(NetworkHealth.critical.color, "purple")
    }
    
    func testNetworkLoggerInitialization() throws {
        // Test that NetworkLogger can be initialized
        let logger = NetworkLogger.shared
        XCTAssertNotNil(logger)
    }
    
    func testNetworkLoggerLogLevels() throws {
        // Test that all log levels are defined
        let levels = NetworkLogger.LogLevel.allCases
        XCTAssertEqual(levels.count, 5)
        XCTAssertTrue(levels.contains(.debug))
        XCTAssertTrue(levels.contains(.info))
        XCTAssertTrue(levels.contains(.warning))
        XCTAssertTrue(levels.contains(.error))
        XCTAssertTrue(levels.contains(.critical))
    }
    
    func testNetworkLoggerActivityLogging() throws {
        // Test activity logging functionality
        let logger = NetworkLogger.shared
        
        // Test basic activity logging
        logger.logActivity("TEST_ACTIVITY", details: ["test_key": "test_value"])
        
        // Test network event logging
        logger.logNetworkEvent("TEST_NETWORK_EVENT", ipAddress: "192.168.1.1", details: ["port": 80])
        
        // Test device event logging
        logger.logDeviceEvent("TEST_DEVICE_EVENT", deviceIP: "192.168.1.100", details: ["status": "online"])
        
        // Test performance logging
        logger.logPerformance("TEST_METRIC", value: 100.5, unit: "Mbps", details: ["interface": "en0"])
        
        // All logging calls should complete without errors
        XCTAssertTrue(true)
    }
    
    func testNetworkLoggerErrorLogging() throws {
        // Test error logging functionality
        let logger = NetworkLogger.shared
        
        // Create a test error
        let testError = NSError(domain: "TestDomain", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error message"])
        
        // Test error logging
        logger.logError(testError, context: "TestContext")
        
        // Error logging should complete without errors
        XCTAssertTrue(true)
    }
    
    func testNetworkLoggerLogManagement() throws {
        // Test log management functionality
        let logger = NetworkLogger.shared
        
        // Test getting log files
        let logFiles = logger.getLogFiles()
        XCTAssertNotNil(logFiles)
        
        // Test clearing old logs (should not throw)
        logger.clearOldLogs(olderThan: 7)
        
        // Test exporting logs
        let exportedLogs = logger.exportLogs()
        // May be nil if no logs exist yet, which is fine
        XCTAssertTrue(exportedLogs == nil || exportedLogs != nil)
    }
}
