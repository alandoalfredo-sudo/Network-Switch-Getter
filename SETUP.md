# Network Switch Getter - Setup Guide

This guide will help you set up and configure the Network Switch Getter iOS application for optimal performance and functionality.

## Prerequisites

### System Requirements
- **macOS**: 14.0 (Sonoma) or later
- **Xcode**: 15.0 or later
- **iOS Deployment Target**: 17.0 or later
- **Swift**: 5.9 or later

### Development Environment
- Apple Developer Account (for device testing)
- iOS device or simulator for testing
- Network access for testing network discovery features

## Installation Steps

### 1. Download and Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/Network-Switch-Getter.git
cd Network-Switch-Getter

# Open in Xcode
open NetworkSwitchGetter.xcodeproj
```

### 2. Project Configuration

#### Bundle Identifier
1. Select the project in Xcode navigator
2. Go to "Signing & Capabilities"
3. Update the bundle identifier to match your developer account
4. Example: `com.yourcompany.NetworkSwitchGetter`

#### Team Selection
1. In "Signing & Capabilities"
2. Select your development team
3. Ensure "Automatically manage signing" is enabled

#### Capabilities
The app requires the following capabilities:
- **Local Network**: For network discovery functionality
- **Background Modes**: For continuous network monitoring (optional)

### 3. Build Configuration

#### Debug Configuration
- Set build configuration to "Debug" for development
- Enable debug logging and verbose output
- Use simulator for initial testing

#### Release Configuration
- Set build configuration to "Release" for production
- Optimize for performance and size
- Test on physical devices

## Network Configuration

### 1. Network Permissions

The app requires local network access. Add the following to your `Info.plist`:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>This app needs access to the local network to discover network switches and devices.</string>
```

### 2. Network Interface Setup

Ensure your development device is connected to the same network as the switches you want to discover:

- **Wi-Fi**: Connect to the target network
- **Ethernet**: Use USB-C to Ethernet adapter if needed
- **VPN**: Disable VPN if it interferes with local network access

### 3. Firewall Configuration

Configure your development machine's firewall:

```bash
# Allow Xcode and Simulator through firewall
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/Xcode.app/Contents/MacOS/Xcode
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --add /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk/System/Library/CoreServices/Simulator.app/Contents/MacOS/Simulator
```

## Testing Setup

### 1. Simulator Testing

For initial testing, use the iOS Simulator:

1. **Network Access**: Simulator shares host machine's network
2. **Device Simulation**: Test basic UI and functionality
3. **Limitations**: Some network features may not work in simulator

### 2. Physical Device Testing

For full functionality testing:

1. **Connect Device**: Use USB cable or wireless debugging
2. **Trust Computer**: Allow debugging when prompted
3. **Network Access**: Ensure device is on target network
4. **Permissions**: Grant local network access when prompted

### 3. Test Network Setup

Create a test environment:

```
Test Network Configuration:
- Router: 192.168.1.1
- Subnet: 192.168.1.0/24
- Test Switches: 192.168.1.100-110
- Test Devices: 192.168.1.200-210
```

## Configuration Options

### 1. Default Settings

The app comes with sensible defaults:

```swift
DiscoverySettings:
- Scan Range: "192.168.1.0/24"
- Timeout: 5.0 seconds
- Max Concurrent Scans: 50
- Retry Count: 3
- Enable SNMP: true
- Enable SSH: true
- Enable Web Interface: true
- Custom Ports: [22, 23, 80, 443, 161, 162]
```

### 2. Custom Configuration

Modify settings in the app or through code:

```swift
// Example: Custom scan range
networkManager.settings.scanRange = "10.0.0.0/24"

// Example: Increase timeout for slow networks
networkManager.settings.timeout = 10.0

// Example: Reduce concurrent scans for stability
networkManager.settings.maxConcurrentScans = 25
```

### 3. Protocol Configuration

Configure device access protocols:

```swift
// SNMP Configuration
networkManager.settings.enableSNMP = true
// Community string: "public" (default)

// SSH Configuration
networkManager.settings.enableSSH = true
// Default port: 22

// Web Interface Configuration
networkManager.settings.enableWebInterface = true
// HTTP port: 80, HTTPS port: 443
```

## Performance Optimization

### 1. Network Scanning

Optimize scanning performance:

- **Concurrent Scans**: Adjust based on network capacity
- **Timeout Values**: Balance speed vs reliability
- **Scan Range**: Limit to necessary subnets
- **Retry Logic**: Configure retry attempts

### 2. Memory Management

Monitor memory usage:

- **Device Limits**: Test on older devices
- **Memory Warnings**: Handle low memory conditions
- **Background Tasks**: Limit background operations
- **Data Cleanup**: Clear old scan results

### 3. Battery Optimization

Minimize battery impact:

- **Background Modes**: Use sparingly
- **Network Activity**: Limit continuous scanning
- **CPU Usage**: Optimize scanning algorithms
- **Screen Updates**: Reduce UI refresh frequency

## Troubleshooting Setup Issues

### 1. Build Errors

Common build issues and solutions:

```bash
# Clean build folder
Product > Clean Build Folder (Cmd+Shift+K)

# Reset derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Update dependencies
# (if using external libraries)
```

### 2. Network Access Issues

If network discovery fails:

1. **Check Permissions**: Verify local network access
2. **Network Interface**: Ensure proper network connection
3. **Firewall**: Check firewall settings
4. **VPN**: Disable VPN if interfering

### 3. Device Testing Issues

If device testing fails:

1. **Signing**: Verify code signing configuration
2. **Provisioning**: Check provisioning profiles
3. **Device Registration**: Register device in developer portal
4. **Trust Settings**: Trust developer certificate on device

### 4. Performance Issues

If app performance is poor:

1. **Memory**: Monitor memory usage
2. **CPU**: Check CPU utilization
3. **Network**: Verify network conditions
4. **Settings**: Adjust scan parameters

## Development Workflow

### 1. Daily Development

```bash
# Start development session
git pull origin main
open NetworkSwitchGetter.xcodeproj

# Make changes and test
# Build and run (Cmd+R)
# Test on device/simulator

# Commit changes
git add .
git commit -m "Description of changes"
git push origin feature-branch
```

### 2. Testing Workflow

1. **Unit Tests**: Run unit tests (Cmd+U)
2. **UI Tests**: Execute UI test suite
3. **Device Testing**: Test on multiple devices
4. **Network Testing**: Test in different network environments
5. **Performance Testing**: Monitor performance metrics

### 3. Release Preparation

1. **Version Bump**: Update version numbers
2. **Release Notes**: Document changes
3. **Testing**: Comprehensive testing
4. **Build**: Create release build
5. **Archive**: Create archive for distribution

## Advanced Configuration

### 1. Custom Network Protocols

Add support for custom protocols:

```swift
// Example: Add custom protocol detection
private func detectCustomProtocol(ipAddress: String) async -> Bool {
    // Implement custom protocol detection
    return await isPortOpen(ipAddress: ipAddress, port: 8080)
}
```

### 2. Enhanced Device Identification

Improve device identification:

```swift
// Example: Enhanced vendor detection
private func identifyVendor(macAddress: String) -> String? {
    let oui = String(macAddress.prefix(8))
    return vendorDatabase[oui]
}
```

### 3. Custom Troubleshooting Tests

Add custom diagnostic tests:

```swift
// Example: Custom bandwidth test
private func performBandwidthTest(ipAddress: String) async -> TroubleshootingResult {
    // Implement bandwidth testing
    return TroubleshootingResult(
        testType: .bandwidthTest,
        status: .passed,
        message: "Bandwidth test completed"
    )
}
```

## Support and Resources

### 1. Documentation
- **README.md**: Main project documentation
- **Code Comments**: Inline code documentation
- **API Documentation**: Generated from code comments

### 2. Community
- **GitHub Issues**: Report bugs and request features
- **Discussions**: Community discussions and Q&A
- **Wiki**: Additional documentation and guides

### 3. Development Resources
- **Apple Documentation**: iOS and Network framework docs
- **SwiftUI Guides**: SwiftUI development resources
- **Network Programming**: Network programming best practices

---

This setup guide should help you get Network Switch Getter up and running quickly. For additional support, please refer to the main README.md or create an issue on GitHub.
