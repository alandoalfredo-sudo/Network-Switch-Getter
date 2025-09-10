#!/usr/bin/env python3
"""
WebSocket server for real-time switch monitoring
"""

import asyncio
import websockets
import json
import random
import time
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SwitchMonitorWebSocket:
    def __init__(self):
        self.clients = set()
        self.switches = [
            {'ip': '192.168.1.1', 'name': 'Main Switch', 'ports': 24},
            {'ip': '192.168.1.10', 'name': 'Office Switch', 'ports': 24},
            {'ip': '192.168.1.20', 'name': 'Server Switch', 'ports': 24}
        ]
    
    async def register_client(self, websocket):
        """Register a new client"""
        self.clients.add(websocket)
        logger.info(f"Client connected. Total clients: {len(self.clients)}")
        
        # Send initial data
        await self.send_initial_data(websocket)
    
    async def unregister_client(self, websocket):
        """Unregister a client"""
        self.clients.discard(websocket)
        logger.info(f"Client disconnected. Total clients: {len(self.clients)}")
    
    async def send_initial_data(self, websocket):
        """Send initial switch data to client"""
        try:
            data = {
                'type': 'initial_data',
                'switches': self.switches,
                'timestamp': datetime.now().isoformat()
            }
            await websocket.send(json.dumps(data))
        except websockets.exceptions.ConnectionClosed:
            await self.unregister_client(websocket)
    
    async def generate_port_data(self, switch_ip, port_number):
        """Generate simulated port data"""
        statuses = ['up', 'down', 'error', 'unknown']
        speeds = ['1 Gbps', '100 Mbps', '10 Gbps', 'Unknown']
        vlans = [1, 10, 20, 30, 100, None]
        
        return {
            'port_number': port_number,
            'status': random.choice(statuses),
            'mac_address': self.generate_mac_address(),
            'ip_address': self.generate_ip_address() if random.random() > 0.4 else None,
            'vlan': random.choice(vlans),
            'speed': random.choice(speeds),
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
    
    def generate_mac_address(self):
        """Generate a random MAC address"""
        return ':'.join(['%02x' % random.randint(0, 255) for _ in range(6)])
    
    def generate_ip_address(self):
        """Generate a random IP address"""
        ranges = ['192.168.1.', '192.168.0.', '10.0.0.', '172.16.0.']
        base = random.choice(ranges)
        return base + str(random.randint(1, 254))
    
    async def broadcast_update(self):
        """Broadcast port updates to all clients"""
        if not self.clients:
            return
        
        # Generate updates for all switches
        updates = []
        for switch in self.switches:
            switch_update = {
                'switch_ip': switch['ip'],
                'switch_name': switch['name'],
                'ports': []
            }
            
            # Generate data for a few random ports (simulate changes)
            num_ports_to_update = random.randint(1, 5)
            ports_to_update = random.sample(range(1, 25), num_ports_to_update)
            
            for port_num in ports_to_update:
                port_data = await self.generate_port_data(switch['ip'], port_num)
                switch_update['ports'].append(port_data)
            
            updates.append(switch_update)
        
        # Create update message
        message = {
            'type': 'port_update',
            'updates': updates,
            'timestamp': datetime.now().isoformat()
        }
        
        # Send to all connected clients
        disconnected_clients = set()
        for client in self.clients:
            try:
                await client.send(json.dumps(message))
            except websockets.exceptions.ConnectionClosed:
                disconnected_clients.add(client)
        
        # Remove disconnected clients
        for client in disconnected_clients:
            await self.unregister_client(client)
    
    async def handle_client(self, websocket, path):
        """Handle a client connection"""
        await self.register_client(websocket)
        try:
            async for message in websocket:
                # Handle incoming messages from clients
                data = json.loads(message)
                await self.handle_client_message(websocket, data)
        except websockets.exceptions.ConnectionClosed:
            pass
        finally:
            await self.unregister_client(websocket)
    
    async def handle_client_message(self, websocket, data):
        """Handle messages from clients"""
        message_type = data.get('type')
        
        if message_type == 'get_port_status':
            # Send specific port status
            switch_ip = data.get('switch_ip')
            port_number = data.get('port_number')
            
            port_data = await self.generate_port_data(switch_ip, port_number)
            response = {
                'type': 'port_status',
                'switch_ip': switch_ip,
                'port_number': port_number,
                'data': port_data,
                'timestamp': datetime.now().isoformat()
            }
            
            await websocket.send(json.dumps(response))
        
        elif message_type == 'get_switch_ports':
            # Send all ports for a switch
            switch_ip = data.get('switch_ip')
            switch = next((s for s in self.switches if s['ip'] == switch_ip), None)
            
            if switch:
                ports = []
                for port_num in range(1, 25):
                    port_data = await self.generate_port_data(switch_ip, port_num)
                    ports.append(port_data)
                
                response = {
                    'type': 'switch_ports',
                    'switch_ip': switch_ip,
                    'switch_name': switch['name'],
                    'total_ports': 24,
                    'active_ports': len([p for p in ports if p['status'] == 'up']),
                    'ports': ports,
                    'timestamp': datetime.now().isoformat()
                }
                
                await websocket.send(json.dumps(response))
    
    async def start_broadcast_loop(self):
        """Start the broadcast loop for live updates"""
        while True:
            await self.broadcast_update()
            await asyncio.sleep(5)  # Update every 5 seconds

async def main():
    """Main function to start the WebSocket server"""
    monitor = SwitchMonitorWebSocket()
    
    # Start the broadcast loop
    broadcast_task = asyncio.create_task(monitor.start_broadcast_loop())
    
    # Start the WebSocket server
    server = await websockets.serve(
        monitor.handle_client,
        "localhost",
        8765,
        ping_interval=20,
        ping_timeout=10
    )
    
    logger.info("WebSocket server started on ws://localhost:8765")
    
    try:
        await asyncio.gather(server.wait_closed(), broadcast_task)
    except KeyboardInterrupt:
        logger.info("Shutting down WebSocket server...")
        server.close()
        await server.wait_closed()
        broadcast_task.cancel()

if __name__ == "__main__":
    asyncio.run(main())
