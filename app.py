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

@app.route('/')
def index():
    """Main dashboard page"""
    return render_template('index.html')

@app.route('/features')
def features():
    """Features and capabilities page"""
    return render_template('features.html')

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
