#!/usr/bin/env python3
"""
Network Switch Getter - Web Interface
A Flask web application for network switch discovery and management
"""

from flask import Flask, render_template, jsonify, request, redirect, url_for
from flask_cors import CORS
import json
import os
import sys
import subprocess
import psutil
import netifaces
import time
import threading
import random
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
CORS(app)

# Global data storage (in production, use a proper database)
discovered_switches = []
network_interfaces = []
monitoring_data = {
    'bandwidth_usage': [],
    'latency_measurements': [],
    'performance_metrics': []
}

class NetworkSwitch:
    def __init__(self, ip, name="", vendor="", model="", status="online"):
        self.ip = ip
        self.name = name or f"Switch-{ip.split('.')[-1]}"
        self.vendor = vendor or "Unknown"
        self.model = model or "Unknown"
        self.status = status
        self.ports = []
        self.last_seen = datetime.now().isoformat()
        self.capabilities = []

class PortInfo:
    def __init__(self, port_number, status="up", speed="1000", duplex="full"):
        self.port_number = port_number
        self.status = status
        self.speed = speed
        self.duplex = duplex
        self.vlan = "1"
        self.description = f"Port {port_number}"

def get_network_interfaces():
    """Get available network interfaces"""
    interfaces = []
    for interface in netifaces.interfaces():
        try:
            addrs = netifaces.ifaddresses(interface)
            if netifaces.AF_INET in addrs:
                ip = addrs[netifaces.AF_INET][0]['addr']
                if not ip.startswith('127.'):  # Skip localhost
                    interfaces.append({
                        'name': interface,
                        'ip': ip,
                        'status': 'up' if interface in psutil.net_if_stats() else 'down'
                    })
        except Exception as e:
            logger.warning(f"Error getting interface {interface}: {e}")
    return interfaces

def scan_network(ip_range="192.168.1.0/24"):
    """Simulate network scanning for switches"""
    logger.info(f"Scanning network: {ip_range}")
    
    # Simulate discovering some switches
    switches = [
        NetworkSwitch("192.168.1.1", "Main Switch", "Cisco", "Catalyst 2960"),
        NetworkSwitch("192.168.1.10", "Office Switch", "HP", "ProCurve 2520"),
        NetworkSwitch("192.168.1.20", "Server Switch", "Dell", "PowerConnect 2848")
    ]
    
    # Add some ports to each switch
    for switch in switches:
        for i in range(1, 25):  # 24 ports
            port = PortInfo(i, "up" if i % 4 != 0 else "down", "1000", "full")
            switch.ports.append(port.__dict__)
        switch.capabilities = ["SNMP", "SSH", "Web Interface"]
    
    return switches

def get_system_info():
    """Get system information"""
    return {
        'cpu_percent': psutil.cpu_percent(),
        'memory_percent': psutil.virtual_memory().percent,
        'disk_percent': psutil.disk_usage('/').percent,
        'network_io': psutil.net_io_counters()._asdict(),
        'boot_time': datetime.fromtimestamp(psutil.boot_time()).isoformat()
    }

def generate_mac_address():
    """Generate a random MAC address"""
    return ':'.join(['%02x' % random.randint(0, 255) for _ in range(6)])

def generate_ip_address():
    """Generate a random IP address in common ranges"""
    ranges = [
        '192.168.1.',
        '192.168.0.',
        '10.0.0.',
        '172.16.0.'
    ]
    base = random.choice(ranges)
    return base + str(random.randint(1, 254))

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('index.html')

@app.route('/features')
def features():
    """Features and capabilities page"""
    return render_template('features.html')

@app.route('/port-monitor')
def port_monitor():
    """Port monitoring dashboard"""
    return render_template('port_monitor.html')

@app.route('/switch-dashboard')
def switch_dashboard():
    """Switch dashboard with port configuration"""
    return render_template('switch_dashboard.html')

@app.route('/api/switches')
def get_switches():
    """Get all discovered switches"""
    return jsonify([switch.__dict__ for switch in discovered_switches])

@app.route('/api/switches', methods=['POST'])
def add_switch():
    """Add a new switch"""
    data = request.get_json()
    switch = NetworkSwitch(
        ip=data['ip'],
        name=data.get('name', ''),
        vendor=data.get('vendor', ''),
        model=data.get('model', '')
    )
    discovered_switches.append(switch)
    return jsonify(switch.__dict__), 201

@app.route('/api/switches/<switch_ip>')
def get_switch(switch_ip):
    """Get specific switch details"""
    switch = next((s for s in discovered_switches if s.ip == switch_ip), None)
    if switch:
        return jsonify(switch.__dict__)
    return jsonify({'error': 'Switch not found'}), 404

@app.route('/api/scan', methods=['POST'])
def start_scan():
    """Start network scan"""
    data = request.get_json()
    ip_range = data.get('ip_range', '192.168.1.0/24')
    
    # Clear existing switches
    discovered_switches.clear()
    
    # Start scan in background
    def scan_background():
        new_switches = scan_network(ip_range)
        discovered_switches.extend(new_switches)
        logger.info(f"Scan completed. Found {len(new_switches)} switches")
    
    thread = threading.Thread(target=scan_background)
    thread.daemon = True
    thread.start()
    
    return jsonify({'message': 'Scan started', 'ip_range': ip_range})

@app.route('/api/interfaces')
def get_interfaces():
    """Get network interfaces"""
    global network_interfaces
    network_interfaces = get_network_interfaces()
    return jsonify(network_interfaces)

@app.route('/api/system')
def get_system():
    """Get system information"""
    return jsonify(get_system_info())

@app.route('/api/monitoring')
def get_monitoring():
    """Get monitoring data"""
    return jsonify(monitoring_data)

@app.route('/api/monitoring', methods=['POST'])
def update_monitoring():
    """Update monitoring data"""
    data = request.get_json()
    monitoring_data.update(data)
    return jsonify({'message': 'Monitoring data updated'})

@app.route('/api/switch/<switch_ip>/ports')
def get_switch_ports(switch_ip):
    """Get ports for a specific switch"""
    switch = next((s for s in discovered_switches if s.ip == switch_ip), None)
    if switch:
        return jsonify(switch.ports)
    return jsonify({'error': 'Switch not found'}), 404

@app.route('/api/switch/<switch_ip>/ports/<int:port_number>', methods=['PUT'])
def update_port(switch_ip, port_number):
    """Update port configuration"""
    switch = next((s for s in discovered_switches if s.ip == switch_ip), None)
    if not switch:
        return jsonify({'error': 'Switch not found'}), 404
    
    data = request.get_json()
    port = next((p for p in switch.ports if p['port_number'] == port_number), None)
    if not port:
        return jsonify({'error': 'Port not found'}), 404
    
    port.update(data)
    return jsonify(port)

@app.route('/api/port-monitor')
def get_port_monitor_data():
    """Get real-time port monitoring data"""
    # Simulate port monitoring data
    connections = []
    switches_data = {}
    
    for switch in discovered_switches:
        switch_ports = []
        active_ports = 0
        
        for port in switch.ports:
            # Simulate port connection data
            mac_address = generate_mac_address()
            ip_address = generate_ip_address() if random.random() > 0.3 else None
            device_name = f"Device-{random.randint(1, 100)}" if ip_address else None
            
            connection = {
                'portNumber': port['port_number'],
                'macAddress': mac_address,
                'ipAddress': ip_address,
                'deviceName': device_name,
                'switchIP': switch.ip,
                'switchName': switch.name,
                'vlan': random.randint(1, 100) if random.random() > 0.5 else None,
                'speed': random.choice(['1 Gbps', '100 Mbps', '10 Gbps']),
                'duplex': 'Full',
                'status': port['status'],
                'lastSeen': datetime.now().isoformat(),
                'uptime': random.randint(100, 86400) if port['status'] == 'Up' else None
            }
            
            connections.append(connection)
            switch_ports.append(connection)
            
            if port['status'] == 'Up':
                active_ports += 1
        
        switches_data[switch.ip] = {
            'switchIP': switch.ip,
            'switchName': switch.name,
            'totalPorts': len(switch.ports),
            'activePorts': active_ports,
            'ports': switch_ports,
            'lastUpdated': datetime.now().isoformat()
        }
    
    # Simulate monitoring statistics
    stats = {
        'totalConnections': len([c for c in connections if c['status'] == 'Up']),
        'totalSwitches': len(discovered_switches),
        'totalPorts': sum(len(s.ports) for s in discovered_switches),
        'successRate': random.uniform(95, 99.5),
        'totalScans': random.randint(100, 1000),
        'successfulScans': random.randint(95, 99),
        'failedScans': random.randint(1, 5),
        'lastScanDuration': random.uniform(0.5, 2.0),
        'averageScanDuration': random.uniform(1.0, 3.0),
        'uptime': random.uniform(3600, 86400)
    }
    
    return jsonify({
        'connections': connections,
        'switches': switches_data,
        'stats': stats,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/api/port-monitor/export')
def export_port_monitor_data():
    """Export port monitoring data"""
    data = get_port_monitor_data()
    return jsonify(data.get_json())

@app.route('/api/port-monitor/filter')
def filter_port_monitor_data():
    """Filter port monitoring data"""
    mac_filter = request.args.get('mac', '').lower()
    ip_filter = request.args.get('ip', '').lower()
    switch_filter = request.args.get('switch', '').lower()
    port_filter = request.args.get('port', '')
    
    data = get_port_monitor_data().get_json()
    connections = data['connections']
    
    filtered_connections = []
    for connection in connections:
        mac_match = not mac_filter or mac_filter in connection['macAddress'].lower()
        ip_match = not ip_filter or (connection['ipAddress'] and ip_filter in connection['ipAddress'].lower())
        switch_match = not switch_filter or switch_filter in connection['switchName'].lower()
        port_match = not port_filter or port_filter in str(connection['portNumber'])
        
        if mac_match and ip_match and switch_match and port_match:
            filtered_connections.append(connection)
    
    data['connections'] = filtered_connections
    return jsonify(data)

@app.route('/api/port-config', methods=['POST'])
def configure_port():
    """Configure a switch port"""
    try:
        data = request.get_json()
        
        # Validate required fields
        required_fields = ['switchId', 'portNumber']
        for field in required_fields:
            if field not in data:
                return jsonify({'success': False, 'error': f'Missing required field: {field}'}), 400
        
        switch_id = data['switchId']
        port_number = data['portNumber']
        
        # Find the switch
        switch = next((s for s in discovered_switches if s.ip == switch_id), None)
        if not switch:
            return jsonify({'success': False, 'error': 'Switch not found'}), 404
        
        # Simulate port configuration
        logger.info(f"Configuring port {port_number} on switch {switch_id}")
        
        # In a real implementation, this would:
        # 1. Connect to the switch via SSH/SNMP
        # 2. Apply the configuration
        # 3. Verify the changes
        
        # For demo purposes, we'll simulate success
        config_result = {
            'success': True,
            'message': f'Port {port_number} configured successfully',
            'switch': switch_id,
            'port': port_number,
            'timestamp': datetime.now().isoformat(),
            'applied_config': {
                'port_name': data.get('portName', ''),
                'admin_status': data.get('adminStatus', 'up'),
                'port_mode': data.get('portMode', 'access'),
                'speed': data.get('speed', 'auto'),
                'duplex': data.get('duplex', 'auto'),
                'access_vlan': data.get('accessVlan', ''),
                'native_vlan': data.get('nativeVlan', ''),
                'allowed_vlans': data.get('allowedVlans', ''),
                'poe_enabled': data.get('poeEnabled', False),
                'stp_enabled': data.get('stpEnabled', True),
                'port_security_enabled': data.get('portSecurityEnabled', False),
                'storm_control_enabled': data.get('stormControlEnabled', False),
                'max_mac_addresses': data.get('maxMacAddresses', ''),
                'violation_action': data.get('violationAction', 'shutdown'),
                'lag_group': data.get('lagGroup', 'none'),
                'lacp_mode': data.get('lacpMode', 'off')
            }
        }
        
        return jsonify(config_result)
        
    except Exception as e:
        logger.error(f"Error configuring port: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/port-status/<switch_ip>/<int:port_number>')
def get_port_status(switch_ip, port_number):
    """Get detailed status of a specific port"""
    try:
        # Find the switch
        switch = next((s for s in discovered_switches if s.ip == switch_ip), None)
        if not switch:
            return jsonify({'error': 'Switch not found'}), 404
        
        # Simulate port status data
        port_data = {
            'switch_ip': switch_ip,
            'port_number': port_number,
            'status': 'up' if random.random() > 0.3 else 'down',
            'mac_address': generate_mac_address(),
            'ip_address': generate_ip_address() if random.random() > 0.4 else None,
            'vlan': random.randint(1, 100) if random.random() > 0.5 else None,
            'speed': random.choice(['1 Gbps', '100 Mbps', '10 Gbps']),
            'duplex': 'Full',
            'poe_status': 'Enabled' if random.random() > 0.7 else 'Disabled',
            'last_seen': datetime.now().isoformat(),
            'uptime': random.randint(100, 86400),
            'errors': {
                'crc_errors': random.randint(0, 10),
                'collisions': random.randint(0, 5),
                'late_collisions': random.randint(0, 2)
            },
            'traffic': {
                'bytes_in': random.randint(1000000, 100000000),
                'bytes_out': random.randint(1000000, 100000000),
                'packets_in': random.randint(10000, 1000000),
                'packets_out': random.randint(10000, 1000000)
            }
        }
        
        return jsonify(port_data)
        
    except Exception as e:
        logger.error(f"Error getting port status: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/switch-ports/<switch_ip>')
def get_all_switch_ports(switch_ip):
    """Get all ports for a specific switch"""
    try:
        # Find the switch
        switch = next((s for s in discovered_switches if s.ip == switch_ip), None)
        if not switch:
            return jsonify({'error': 'Switch not found'}), 404
        
        # Generate port data for all 24 ports
        ports = []
        for port_num in range(1, 25):
            port_data = {
                'port_number': port_num,
                'status': 'up' if random.random() > 0.3 else 'down',
                'mac_address': generate_mac_address(),
                'ip_address': generate_ip_address() if random.random() > 0.4 else None,
                'vlan': random.randint(1, 100) if random.random() > 0.5 else None,
                'speed': random.choice(['1 Gbps', '100 Mbps', '10 Gbps']),
                'duplex': 'Full',
                'poe_status': 'Enabled' if random.random() > 0.7 else 'Disabled',
                'last_seen': datetime.now().isoformat()
            }
            ports.append(port_data)
        
        return jsonify({
            'switch_ip': switch_ip,
            'switch_name': switch.name if hasattr(switch, 'name') else f'Switch {switch_ip}',
            'total_ports': 24,
            'active_ports': len([p for p in ports if p['status'] == 'up']),
            'ports': ports,
            'last_updated': datetime.now().isoformat()
        })
        
    except Exception as e:
        logger.error(f"Error getting switch ports: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'switches_count': len(discovered_switches),
        'interfaces_count': len(network_interfaces)
    })

# Initialize with some sample data
def initialize_data():
    """Initialize with sample data"""
    global discovered_switches, network_interfaces
    network_interfaces = get_network_interfaces()
    
    # Add some sample switches
    sample_switches = scan_network()
    discovered_switches.extend(sample_switches)
    
    logger.info(f"Initialized with {len(discovered_switches)} switches and {len(network_interfaces)} interfaces")

if __name__ == '__main__':
    initialize_data()
    
    print("🌐 Network Switch Getter - Web Interface")
    print("=" * 50)
    print("📡 Starting web server...")
    print("🔗 Open in browser: http://localhost:8000")
    print("📊 API Documentation: http://localhost:8000/api/health")
    print("=" * 50)
    
    app.run(host='0.0.0.0', port=8000, debug=True)
