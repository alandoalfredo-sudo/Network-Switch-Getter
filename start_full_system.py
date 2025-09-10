#!/usr/bin/env python3
"""
Start the complete Network Switch Getter system
Includes Flask web server and WebSocket server
"""

import subprocess
import sys
import time
import signal
import os
from threading import Thread

class SystemManager:
    def __init__(self):
        self.processes = []
        self.running = True
        
    def start_flask_server(self):
        """Start the Flask web server"""
        print("🌐 Starting Flask web server...")
        try:
            process = subprocess.Popen([
                sys.executable, 'app.py'
            ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            self.processes.append(('Flask', process))
            print("✅ Flask server started on http://localhost:8000")
        except Exception as e:
            print(f"❌ Failed to start Flask server: {e}")
    
    def start_websocket_server(self):
        """Start the WebSocket server"""
        print("🔌 Starting WebSocket server...")
        try:
            process = subprocess.Popen([
                sys.executable, 'websocket_server.py'
            ], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            self.processes.append(('WebSocket', process))
            print("✅ WebSocket server started on ws://localhost:8765")
        except Exception as e:
            print(f"❌ Failed to start WebSocket server: {e}")
    
    def start_system(self):
        """Start the complete system"""
        print("🚀 Starting Network Switch Getter System...")
        print("=" * 50)
        
        # Start Flask server
        self.start_flask_server()
        time.sleep(2)
        
        # Start WebSocket server
        self.start_websocket_server()
        time.sleep(2)
        
        print("=" * 50)
        print("🎯 System Status:")
        print("  📱 Web Dashboard: http://localhost:8000/")
        print("  🔍 Port Monitor: http://localhost:8000/port-monitor")
        print("  ⚙️  Switch Dashboard: http://localhost:8000/switch-dashboard")
        print("  ⭐ Features: http://localhost:8000/features")
        print("  🔌 WebSocket: ws://localhost:8765")
        print("=" * 50)
        print("Press Ctrl+C to stop all services")
        
        # Monitor processes
        self.monitor_processes()
    
    def monitor_processes(self):
        """Monitor running processes"""
        try:
            while self.running:
                time.sleep(1)
                
                # Check if any process has died
                for name, process in self.processes[:]:
                    if process.poll() is not None:
                        print(f"⚠️  {name} server stopped unexpectedly")
                        self.processes.remove((name, process))
                        
                        # Restart if it was critical
                        if name == 'Flask':
                            print("🔄 Restarting Flask server...")
                            self.start_flask_server()
                        elif name == 'WebSocket':
                            print("🔄 Restarting WebSocket server...")
                            self.start_websocket_server()
                
        except KeyboardInterrupt:
            print("\n🛑 Shutting down system...")
            self.stop_all_processes()
    
    def stop_all_processes(self):
        """Stop all running processes"""
        self.running = False
        
        for name, process in self.processes:
            print(f"🛑 Stopping {name} server...")
            try:
                process.terminate()
                process.wait(timeout=5)
                print(f"✅ {name} server stopped")
            except subprocess.TimeoutExpired:
                print(f"⚠️  Force killing {name} server...")
                process.kill()
            except Exception as e:
                print(f"❌ Error stopping {name} server: {e}")
        
        print("✅ All services stopped")

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    print("\n🛑 Received shutdown signal...")
    sys.exit(0)

def main():
    """Main function"""
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Check if required files exist
    required_files = ['app.py', 'websocket_server.py']
    for file in required_files:
        if not os.path.exists(file):
            print(f"❌ Required file not found: {file}")
            sys.exit(1)
    
    # Start the system
    manager = SystemManager()
    try:
        manager.start_system()
    except KeyboardInterrupt:
        manager.stop_all_processes()
    except Exception as e:
        print(f"❌ System error: {e}")
        manager.stop_all_processes()
        sys.exit(1)

if __name__ == "__main__":
    main()
