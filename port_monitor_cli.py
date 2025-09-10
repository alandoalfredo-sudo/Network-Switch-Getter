#!/usr/bin/env python3
"""
Port Monitor CLI Tool
Real-time command line interface for monitoring switch ports
"""

import requests
import json
import time
import os
import sys
from datetime import datetime
from typing import Dict, List, Optional
import argparse
import signal

class PortMonitorCLI:
    def __init__(self, api_base_url: str = "http://localhost:8000"):
        self.api_base_url = api_base_url
        self.running = True
        self.refresh_interval = 5  # seconds
        self.last_data = None
        
        # Set up signal handlers for graceful shutdown
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
    
    def _signal_handler(self, signum, frame):
        """Handle shutdown signals"""
        print("\n\nShutting down port monitor...")
        self.running = False
        sys.exit(0)
    
    def clear_screen(self):
        """Clear the terminal screen"""
        os.system('cls' if os.name == 'nt' else 'clear')
    
    def get_port_data(self) -> Optional[Dict]:
        """Fetch port monitoring data from API"""
        try:
            response = requests.get(f"{self.api_base_url}/api/port-monitor", timeout=10)
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            print(f"Error fetching data: {e}")
            return None
    
    def format_mac_address(self, mac: str) -> str:
        """Format MAC address for display"""
        return mac.upper()
    
    def format_ip_address(self, ip: Optional[str]) -> str:
        """Format IP address for display"""
        return ip if ip else "N/A"
    
    def format_device_name(self, name: Optional[str]) -> str:
        """Format device name for display"""
        return name if name else "Unknown"
    
    def format_speed(self, speed: Optional[str]) -> str:
        """Format speed for display"""
        return speed if speed else "Unknown"
    
    def format_vlan(self, vlan: Optional[int]) -> str:
        """Format VLAN for display"""
        return str(vlan) if vlan else "N/A"
    
    def format_timestamp(self, timestamp: str) -> str:
        """Format timestamp for display"""
        try:
            dt = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
            return dt.strftime("%H:%M:%S")
        except:
            return timestamp
    
    def get_status_color(self, status: str) -> str:
        """Get color code for status"""
        colors = {
            'up': '\033[92m',      # Green
            'down': '\033[91m',    # Red
            'testing': '\033[93m', # Yellow
            'unknown': '\033[90m'  # Gray
        }
        return colors.get(status.lower(), '\033[0m')
    
    def reset_color(self) -> str:
        """Reset color"""
        return '\033[0m'
    
    def display_header(self, data: Dict):
        """Display header information"""
        stats = data.get('stats', {})
        timestamp = data.get('timestamp', '')
        
        print("=" * 120)
        print(f"🔍 PORT MONITOR - Real-time Switch Port Monitoring")
        print(f"📊 Active Connections: {stats.get('totalConnections', 0)} | "
              f"Switches: {stats.get('totalSwitches', 0)} | "
              f"Total Ports: {stats.get('totalPorts', 0)} | "
              f"Success Rate: {stats.get('successRate', 0):.1f}%")
        print(f"🕐 Last Update: {self.format_timestamp(timestamp)} | "
              f"Refresh: {self.refresh_interval}s | "
              f"Press Ctrl+C to exit")
        print("=" * 120)
    
    def display_connections_table(self, connections: List[Dict]):
        """Display connections in table format"""
        if not connections:
            print("No active connections found.")
            return
        
        # Table header
        print(f"{'Port':<6} {'MAC Address':<18} {'IP Address':<16} {'Device':<15} {'Switch':<12} {'VLAN':<6} {'Speed':<10} {'Status':<8}")
        print("-" * 120)
        
        # Sort connections by switch name, then port number
        sorted_connections = sorted(connections, key=lambda x: (x.get('switchName', ''), x.get('portNumber', 0)))
        
        for conn in sorted_connections:
            port = str(conn.get('portNumber', ''))
            mac = self.format_mac_address(conn.get('macAddress', ''))
            ip = self.format_ip_address(conn.get('ipAddress'))
            device = self.format_device_name(conn.get('deviceName'))
            switch = conn.get('switchName', '')[:12]  # Truncate long names
            vlan = self.format_vlan(conn.get('vlan'))
            speed = self.format_speed(conn.get('speed'))
            status = conn.get('status', 'unknown')
            
            # Color code the status
            status_color = self.get_status_color(status)
            status_display = f"{status_color}{status.upper()}{self.reset_color()}"
            
            print(f"{port:<6} {mac:<18} {ip:<16} {device:<15} {switch:<12} {vlan:<6} {speed:<10} {status_display:<8}")
    
    def display_switches_summary(self, switches: Dict):
        """Display switches summary"""
        if not switches:
            return
        
        print("\n" + "=" * 60)
        print("📡 SWITCHES SUMMARY")
        print("=" * 60)
        
        for switch_ip, switch_info in switches.items():
            switch_name = switch_info.get('switchName', 'Unknown')
            total_ports = switch_info.get('totalPorts', 0)
            active_ports = switch_info.get('activePorts', 0)
            last_updated = switch_info.get('lastUpdated', '')
            
            print(f"🔌 {switch_name} ({switch_ip})")
            print(f"   Ports: {active_ports}/{total_ports} active")
            print(f"   Last Update: {self.format_timestamp(last_updated)}")
            print()
    
    def display_filters(self, filters: Dict):
        """Display current filters"""
        if not any(filters.values()):
            return
        
        print("\n" + "=" * 60)
        print("🔍 ACTIVE FILTERS")
        print("=" * 60)
        
        for key, value in filters.items():
            if value:
                print(f"{key.title()}: {value}")
    
    def run_interactive_mode(self):
        """Run in interactive mode with real-time updates"""
        print("Starting Port Monitor CLI...")
        print("Press Ctrl+C to exit")
        time.sleep(2)
        
        while self.running:
            try:
                self.clear_screen()
                
                # Fetch data
                data = self.get_port_data()
                if not data:
                    print("Failed to fetch data. Retrying in 5 seconds...")
                    time.sleep(5)
                    continue
                
                # Display data
                self.display_header(data)
                self.display_connections_table(data.get('connections', []))
                self.display_switches_summary(data.get('switches', {}))
                
                # Wait for next refresh
                time.sleep(self.refresh_interval)
                
            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"Error: {e}")
                time.sleep(5)
        
        print("\nPort Monitor stopped.")
    
    def run_single_scan(self):
        """Run a single scan and display results"""
        print("Performing single port scan...")
        
        data = self.get_port_data()
        if not data:
            print("Failed to fetch data.")
            return
        
        self.display_header(data)
        self.display_connections_table(data.get('connections', []))
        self.display_switches_summary(data.get('switches', {}))
    
    def export_data(self, filename: Optional[str] = None):
        """Export port monitoring data to file"""
        data = self.get_port_data()
        if not data:
            print("Failed to fetch data for export.")
            return
        
        if not filename:
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"port_monitor_export_{timestamp}.json"
        
        try:
            with open(filename, 'w') as f:
                json.dump(data, f, indent=2)
            print(f"Data exported to: {filename}")
        except Exception as e:
            print(f"Error exporting data: {e}")
    
    def filter_data(self, mac: Optional[str] = None, ip: Optional[str] = None, 
                   switch: Optional[str] = None, port: Optional[str] = None):
        """Filter and display data"""
        params = {}
        if mac:
            params['mac'] = mac
        if ip:
            params['ip'] = ip
        if switch:
            params['switch'] = switch
        if port:
            params['port'] = port
        
        try:
            response = requests.get(f"{self.api_base_url}/api/port-monitor/filter", params=params)
            response.raise_for_status()
            data = response.json()
            
            self.display_header(data)
            self.display_connections_table(data.get('connections', []))
            self.display_filters(params)
            
        except requests.exceptions.RequestException as e:
            print(f"Error filtering data: {e}")

def main():
    parser = argparse.ArgumentParser(description='Port Monitor CLI Tool')
    parser.add_argument('--url', default='http://localhost:8000', 
                       help='API base URL (default: http://localhost:8000)')
    parser.add_argument('--interval', type=int, default=5,
                       help='Refresh interval in seconds (default: 5)')
    parser.add_argument('--single', action='store_true',
                       help='Run single scan instead of continuous monitoring')
    parser.add_argument('--export', type=str, metavar='FILENAME',
                       help='Export data to JSON file')
    parser.add_argument('--filter-mac', type=str, metavar='MAC',
                       help='Filter by MAC address')
    parser.add_argument('--filter-ip', type=str, metavar='IP',
                       help='Filter by IP address')
    parser.add_argument('--filter-switch', type=str, metavar='SWITCH',
                       help='Filter by switch name')
    parser.add_argument('--filter-port', type=str, metavar='PORT',
                       help='Filter by port number')
    
    args = parser.parse_args()
    
    monitor = PortMonitorCLI(args.url)
    monitor.refresh_interval = args.interval
    
    if args.export:
        monitor.export_data(args.export)
    elif any([args.filter_mac, args.filter_ip, args.filter_switch, args.filter_port]):
        monitor.filter_data(
            mac=args.filter_mac,
            ip=args.filter_ip,
            switch=args.filter_switch,
            port=args.filter_port
        )
    elif args.single:
        monitor.run_single_scan()
    else:
        monitor.run_interactive_mode()

if __name__ == "__main__":
    main()
