# Network Switch Getter

A comprehensive iOS application for discovering, monitoring, and troubleshooting network switches and devices on your local network.

## Features

### 🔍 Network Discovery
- **Automatic Network Scanning**: Discover switches and network devices on your local network
- **Real-time Detection**: Live scanning with progress indicators
- **Device Identification**: Identify device types, vendors, models, and capabilities
- **Customizable Scan Range**: Configure network ranges and scan parameters

### 📊 Network Analytics & Monitoring
- **Real-time Bandwidth Monitoring**: Track bandwidth usage with detailed metrics and charts
- **Latency Monitoring**: Continuous latency measurement with jitter and packet loss analysis
- **Performance Analytics**: CPU, memory, and temperature monitoring for network devices
- **Interactive Charts**: Beautiful SwiftUI charts showing network performance over time
- **Port Utilization Tracking**: Monitor individual port usage and performance

### 🤖 AI-Powered Intelligence
- **AI Network Analysis**: Intelligent analysis of network performance and configuration
- **Smart Recommendations**: AI-generated recommendations for network optimization
- **VPN Configuration**: AI-assisted VPN setup and management
- **Trunk Port Optimization**: Intelligent trunk port configuration and load balancing
- **Predictive Analytics**: Forecast network issues and suggest preventive measures

### 📱 Pocket Display Widget
- **Home Screen Widget**: Monitor network status directly from your home screen
- **Real-time Updates**: Live network health, device status, and performance metrics
- **Multiple Sizes**: Small, medium, and large widget options
- **Quick Alerts**: Instant notifications for network issues and performance problems
- **Customizable Display**: Choose what information to show on your widget

### 🛠️ Troubleshooting & Diagnostics
- **Comprehensive Testing**: Run multiple diagnostic tests including ping, port scans, SNMP queries, and more
- **Health Monitoring**: Real-time network health assessment with AI insights
- **Detailed Results**: Get detailed test results with timestamps and status indicators
- **Custom Test Selection**: Choose which diagnostic tests to run
- **Automated Remediation**: AI-powered suggestions for fixing network issues

### 📊 Device Management
- **Detailed Device Information**: View comprehensive details about each discovered switch
- **Port Monitoring**: Monitor individual switch ports and their status
- **Capability Detection**: Identify supported protocols and features
- **Performance Metrics**: Track response times and device performance
- **Real-time Status Updates**: Live monitoring of device health and connectivity

### ⚙️ Advanced Configuration
- **Protocol Settings**: Configure SNMP, SSH, and web interface access
- **Scan Customization**: Adjust timeout values, concurrent scans, and retry counts
- **Custom Ports**: Add custom ports for specialized device discovery
- **Export Options**: Export discovery results in CSV or JSON format
- **AI Configuration Management**: Intelligent configuration backup and restore

## Requirements

- **iOS 17.0+**
- **Xcode 15.0+**
- **Swift 5.9+**
- **Network access permissions**

## Installation

### Prerequisites
1. Install Xcode from the Mac App Store
2. Ensure you have an Apple Developer account (for device testing)

### Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone https://github.com/yourusername/Network-Switch-Getter.git
   cd Network-Switch-Getter
   ```

2. **Open in Xcode**
   ```bash
   open NetworkSwitchGetter.xcodeproj
   ```

3. **Configure Project Settings**
   - Select your development team in the project settings
   - Update the bundle identifier if needed
   - Configure signing certificates

4. **Build and Run**
   - Select your target device or simulator
   - Press `Cmd + R` to build and run the app

## Usage

### Getting Started

1. **Launch the App**: Open Network Switch Getter on your iOS device
2. **Check Network Connection**: Ensure your device is connected to the same network as the switches you want to discover
3. **Start Discovery**: Tap "Start Scan" in the Discovery tab
4. **Review Results**: View discovered switches in the list
5. **Access Details**: Tap on any switch to see detailed information

### Discovery Tab

The Discovery tab is your main interface for network scanning:

- **Network Interface Card**: Shows your current network connection details
- **Scan Controls**: Start/stop network scanning with progress indicators
- **Search Functionality**: Filter discovered devices by IP, hostname, vendor, or model
- **Device List**: View all discovered switches with status indicators

### Analytics Tab

The Analytics tab provides comprehensive network monitoring:

- **Real-time Metrics**: Live bandwidth, latency, and performance data
- **Interactive Charts**: Beautiful visualizations of network performance over time
- **Time Range Selection**: View data for different time periods (hour, day, week, month)
- **Metric Selection**: Choose between bandwidth, latency, performance, and utilization views
- **AI Insights**: Get intelligent recommendations based on network analysis

### AI Configuration Tab

The AI Configuration tab offers intelligent network management:

- **AI Recommendations**: View AI-generated suggestions for network optimization
- **VPN Configuration**: Set up and manage VPN connections with AI assistance
- **Trunk Port Management**: Configure and optimize trunk ports intelligently
- **Network Health Assessment**: Get comprehensive health scores and insights
- **Automated Configuration**: Apply AI recommendations with one tap

### Troubleshooting Tab

Use the Troubleshooting tab to diagnose network issues:

- **Switch Selection**: Choose which switch to troubleshoot
- **Test Selection**: Select specific diagnostic tests to run
- **Results View**: Review test results with detailed status information
- **Health Summary**: Get an overall network health assessment
- **AI-Powered Diagnostics**: Get intelligent suggestions for resolving issues

### Settings Tab

Configure the app behavior in the Settings tab:

- **Scan Settings**: Adjust network range, timeout, and performance parameters
- **Protocol Settings**: Configure SNMP, SSH, and web interface access
- **Data Management**: Export results or clear stored data
- **Widget Configuration**: Customize your home screen widget
- **AI Settings**: Configure AI analysis parameters and preferences
- **Help & Support**: Access user guides and troubleshooting information

## Architecture

### Core Components

#### NetworkDiscoveryManager
The main class responsible for network scanning and device discovery:
- Manages network monitoring and interface detection
- Handles concurrent IP address scanning
- Performs device identification and capability detection
- Manages troubleshooting and diagnostic operations

#### NetworkMonitoringManager
Advanced monitoring and analytics engine:
- Real-time bandwidth usage tracking
- Latency measurement and analysis
- Performance metrics collection
- Pocket display data generation

#### AINetworkIntelligence
AI-powered network analysis and configuration:
- Intelligent network performance analysis
- AI-generated recommendations
- VPN configuration management
- Trunk port optimization

#### SwitchModel & NetworkAnalytics
Comprehensive data models for network devices and analytics:
- `NetworkSwitch`: Main device model with all properties
- `PortInfo`: Individual port information
- `NetworkInterface`: Current network interface details
- `TroubleshootingResult`: Diagnostic test results
- `BandwidthUsage`: Bandwidth monitoring data
- `LatencyMeasurement`: Latency tracking information
- `NetworkPerformanceMetrics`: Device performance data
- `AINetworkRecommendation`: AI-generated suggestions

#### User Interface
SwiftUI-based interface with five main tabs:
- **DiscoveryView**: Network scanning and device listing
- **NetworkAnalyticsDashboard**: Real-time monitoring and analytics
- **AIConfigurationView**: AI-powered configuration management
- **TroubleshootingView**: Diagnostic testing interface
- **SettingsView**: Configuration and app management

#### Pocket Display Widget
Home screen widget for quick network monitoring:
- Real-time network status display
- Multiple widget sizes (small, medium, large)
- Customizable information display
- Live updates and alerts

### Key Features Implementation

#### Network Scanning
- Uses `Network` framework for low-level network operations
- Implements concurrent scanning with configurable limits
- Supports custom port scanning and protocol detection
- Handles network interface detection and IP range calculation

#### Device Identification
- Multi-protocol device identification (SNMP, SSH, Web Interface)
- MAC address resolution and vendor identification
- Capability detection through port scanning
- Response time measurement and performance tracking

#### Network Monitoring & Analytics
- Real-time bandwidth usage tracking with detailed metrics
- Continuous latency monitoring with jitter and packet loss analysis
- Performance metrics collection (CPU, memory, temperature)
- Interactive charts and visualizations using SwiftUI Charts
- Historical data analysis and trending

#### AI-Powered Intelligence
- Machine learning-based network analysis
- Intelligent recommendation generation
- Automated VPN configuration and management
- Smart trunk port optimization
- Predictive analytics for network issues

#### Pocket Display Widget
- Home screen widget integration using WidgetKit
- Real-time network status updates
- Multiple widget sizes and configurations
- Live data synchronization with main app
- Customizable display options

#### Troubleshooting
- Comprehensive diagnostic test suite
- Real-time test execution with progress tracking
- Detailed result reporting with timestamps
- Network health scoring and assessment
- AI-powered issue resolution suggestions

## Configuration

### Network Settings

Configure network discovery parameters in Settings > Scan Settings:

- **Network Range**: Set the IP range to scan (default: 192.168.1.0/24)
- **Timeout**: Adjust connection timeout (default: 5.0 seconds)
- **Max Concurrent Scans**: Control parallel scanning (default: 50)
- **Retry Count**: Set retry attempts for failed connections (default: 3)

### Protocol Settings

Configure device access protocols in Settings > Protocol Settings:

- **SNMP**: Enable/disable SNMP discovery with community string configuration
- **SSH**: Configure SSH access with default credentials
- **Web Interface**: Set HTTP/HTTPS port configurations

## Troubleshooting

### Common Issues

#### No Switches Discovered
- Verify network connectivity
- Check if you're on the same network as the switches
- Verify scan range settings
- Ensure switches are powered on and connected

#### Slow Scan Performance
- Reduce concurrent scan limit in settings
- Increase timeout values
- Check network congestion
- Verify device firewall settings

#### Missing Device Information
- Enable SNMP, SSH, or web interface protocols
- Check device accessibility
- Verify protocol credentials
- Review device configuration

#### App Crashes or Freezes
- Restart the app
- Check available memory
- Verify iOS version compatibility
- Report issues with device logs

### Performance Optimization

- **Network Range**: Limit scan range to necessary subnets
- **Concurrent Scans**: Adjust based on network capacity
- **Timeout Values**: Balance between speed and reliability
- **Protocol Selection**: Enable only necessary protocols

## Security Considerations

### Network Access
- The app requires local network access permissions
- Only scans configured network ranges
- Does not store sensitive credentials
- Uses secure protocols when available

### Data Privacy
- No data is transmitted to external servers
- All discovery results are stored locally
- User can clear all data at any time
- No personal information is collected

## Contributing

We welcome contributions to Network Switch Getter! Please follow these guidelines:

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on multiple devices
5. Submit a pull request

### Code Style
- Follow Swift style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Maintain consistent formatting

### Testing
- Test on multiple iOS versions
- Verify network functionality
- Check memory usage and performance
- Test edge cases and error conditions

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:

- **Documentation**: Check the in-app user guide and troubleshooting guide
- **Issues**: Report bugs and feature requests on GitHub
- **Contact**: Reach out through the app's contact support feature

## Changelog

### Version 1.0.0
- Initial release
- Network discovery functionality
- Troubleshooting and diagnostics
- Device management interface
- Comprehensive settings and configuration

## Acknowledgments

- Built with SwiftUI and the Network framework
- Uses iOS system APIs for network operations
- Inspired by network management best practices
- Community feedback and contributions

---

**Network Switch Getter** - Making network device discovery and management simple and efficient on iOS.
