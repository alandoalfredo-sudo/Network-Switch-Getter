// Network Switch Getter - Web Interface JavaScript

class NetworkSwitchGetter {
    constructor() {
        this.switches = [];
        this.interfaces = [];
        this.systemInfo = {};
        this.refreshInterval = null;
        this.init();
    }

    init() {
        this.loadData();
        this.setupEventListeners();
        this.startAutoRefresh();
    }

    setupEventListeners() {
        // Add any event listeners here
        document.getElementById('scan-range').addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.startScan();
            }
        });
    }

    async loadData() {
        try {
            await Promise.all([
                this.loadSwitches(),
                this.loadInterfaces(),
                this.loadSystemInfo()
            ]);
            this.updateUI();
        } catch (error) {
            console.error('Error loading data:', error);
            this.showAlert('Error loading data: ' + error.message, 'danger');
        }
    }

    async loadSwitches() {
        const response = await fetch('/api/switches');
        if (response.ok) {
            this.switches = await response.json();
        } else {
            throw new Error('Failed to load switches');
        }
    }

    async loadInterfaces() {
        const response = await fetch('/api/interfaces');
        if (response.ok) {
            this.interfaces = await response.json();
        } else {
            throw new Error('Failed to load interfaces');
        }
    }

    async loadSystemInfo() {
        const response = await fetch('/api/system');
        if (response.ok) {
            this.systemInfo = await response.json();
        } else {
            throw new Error('Failed to load system info');
        }
    }

    updateUI() {
        this.updateOverviewCards();
        this.updateSwitchesTable();
        this.updateInterfacesTable();
    }

    updateOverviewCards() {
        // Update switches count
        document.getElementById('switches-count').textContent = this.switches.length;
        
        // Update online switches count
        const onlineSwitches = this.switches.filter(s => s.status === 'online').length;
        document.getElementById('online-switches').textContent = onlineSwitches;
        
        // Update interfaces count
        document.getElementById('interfaces-count').textContent = this.interfaces.length;
        
        // Update system load
        document.getElementById('system-load').textContent = 
            Math.round(this.systemInfo.cpu_percent || 0) + '%';
    }

    updateSwitchesTable() {
        const tbody = document.getElementById('switches-table');
        
        if (this.switches.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="8" class="text-center">No switches discovered yet. Start a scan to find network devices.</td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = this.switches.map(switch_ => `
            <tr>
                <td><code>${switch_.ip}</code></td>
                <td>${switch_.name}</td>
                <td>${switch_.vendor}</td>
                <td>${switch_.model}</td>
                <td>
                    <span class="badge ${this.getStatusClass(switch_.status)}">
                        ${switch_.status.toUpperCase()}
                    </span>
                </td>
                <td>${switch_.ports ? switch_.ports.length : 0}</td>
                <td>${this.formatDate(switch_.last_seen)}</td>
                <td>
                    <button class="btn btn-sm btn-outline-primary" onclick="app.showSwitchDetails('${switch_.ip}')">
                        <i class="fas fa-eye"></i>
                    </button>
                    <button class="btn btn-sm btn-outline-info" onclick="app.showPorts('${switch_.ip}')">
                        <i class="fas fa-list"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    }

    updateInterfacesTable() {
        const tbody = document.getElementById('interfaces-table');
        
        if (this.interfaces.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="3" class="text-center">No network interfaces found.</td>
                </tr>
            `;
            return;
        }

        tbody.innerHTML = this.interfaces.map(iface => `
            <tr>
                <td><code>${iface.name}</code></td>
                <td><code>${iface.ip}</code></td>
                <td>
                    <span class="badge ${this.getStatusClass(iface.status)}">
                        ${iface.status.toUpperCase()}
                    </span>
                </td>
            </tr>
        `).join('');
    }

    getStatusClass(status) {
        switch (status.toLowerCase()) {
            case 'online':
            case 'up':
                return 'bg-success';
            case 'offline':
            case 'down':
                return 'bg-danger';
            default:
                return 'bg-secondary';
        }
    }

    formatDate(dateString) {
        if (!dateString) return 'Unknown';
        const date = new Date(dateString);
        return date.toLocaleString();
    }

    async startScan() {
        const ipRange = document.getElementById('scan-range').value;
        if (!ipRange) {
            this.showAlert('Please enter a valid IP range', 'warning');
            return;
        }

        try {
            this.showAlert('Starting network scan...', 'info');
            
            const response = await fetch('/api/scan', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ ip_range: ipRange })
            });

            if (response.ok) {
                this.showAlert('Network scan started successfully', 'success');
                // Refresh data after a short delay
                setTimeout(() => this.loadData(), 2000);
            } else {
                throw new Error('Failed to start scan');
            }
        } catch (error) {
            console.error('Error starting scan:', error);
            this.showAlert('Error starting scan: ' + error.message, 'danger');
        }
    }

    async refreshData() {
        this.showAlert('Refreshing data...', 'info');
        await this.loadData();
        this.showAlert('Data refreshed successfully', 'success');
    }

    async showSwitchDetails(switchIp) {
        try {
            const response = await fetch(`/api/switches/${switchIp}`);
            if (response.ok) {
                const switch_ = await response.json();
                this.displaySwitchModal(switch_);
            } else {
                this.showAlert('Switch not found', 'danger');
            }
        } catch (error) {
            console.error('Error loading switch details:', error);
            this.showAlert('Error loading switch details', 'danger');
        }
    }

    displaySwitchModal(switch_) {
        const modal = new bootstrap.Modal(document.getElementById('switchModal'));
        const detailsDiv = document.getElementById('switch-details');
        
        detailsDiv.innerHTML = `
            <div class="row">
                <div class="col-md-6">
                    <h6>Basic Information</h6>
                    <table class="table table-sm">
                        <tr><td><strong>IP Address:</strong></td><td><code>${switch_.ip}</code></td></tr>
                        <tr><td><strong>Name:</strong></td><td>${switch_.name}</td></tr>
                        <tr><td><strong>Vendor:</strong></td><td>${switch_.vendor}</td></tr>
                        <tr><td><strong>Model:</strong></td><td>${switch_.model}</td></tr>
                        <tr><td><strong>Status:</strong></td><td><span class="badge ${this.getStatusClass(switch_.status)}">${switch_.status.toUpperCase()}</span></td></tr>
                        <tr><td><strong>Last Seen:</strong></td><td>${this.formatDate(switch_.last_seen)}</td></tr>
                    </table>
                </div>
                <div class="col-md-6">
                    <h6>Capabilities</h6>
                    <div class="mb-3">
                        ${switch_.capabilities ? switch_.capabilities.map(cap => 
                            `<span class="badge bg-info me-1">${cap}</span>`
                        ).join('') : 'No capabilities listed'}
                    </div>
                    <h6>Ports (${switch_.ports ? switch_.ports.length : 0})</h6>
                    <div class="port-grid">
                        ${switch_.ports ? switch_.ports.map(port => 
                            `<div class="port-item ${port.status}">Port ${port.port_number}</div>`
                        ).join('') : 'No ports available'}
                    </div>
                </div>
            </div>
        `;
        
        modal.show();
    }

    async showPorts(switchIp) {
        try {
            const response = await fetch(`/api/switch/${switchIp}/ports`);
            if (response.ok) {
                const ports = await response.json();
                this.displayPortsModal(switchIp, ports);
            } else {
                this.showAlert('Ports not found', 'danger');
            }
        } catch (error) {
            console.error('Error loading ports:', error);
            this.showAlert('Error loading ports', 'danger');
        }
    }

    displayPortsModal(switchIp, ports) {
        const modal = new bootstrap.Modal(document.getElementById('switchModal'));
        const detailsDiv = document.getElementById('switch-details');
        
        detailsDiv.innerHTML = `
            <h6>Ports for Switch ${switchIp}</h6>
            <div class="table-responsive">
                <table class="table table-sm">
                    <thead>
                        <tr>
                            <th>Port</th>
                            <th>Status</th>
                            <th>Speed</th>
                            <th>Duplex</th>
                            <th>VLAN</th>
                            <th>Description</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${ports.map(port => `
                            <tr>
                                <td>${port.port_number}</td>
                                <td><span class="badge ${this.getStatusClass(port.status)}">${port.status.toUpperCase()}</span></td>
                                <td>${port.speed}</td>
                                <td>${port.duplex}</td>
                                <td>${port.vlan}</td>
                                <td>${port.description}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </div>
        `;
        
        modal.show();
    }

    exportData() {
        const data = {
            switches: this.switches,
            interfaces: this.interfaces,
            systemInfo: this.systemInfo,
            exportTime: new Date().toISOString()
        };
        
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `network-switch-data-${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        this.showAlert('Data exported successfully', 'success');
    }

    showAlert(message, type) {
        // Remove existing alerts
        const existingAlerts = document.querySelectorAll('.alert');
        existingAlerts.forEach(alert => alert.remove());
        
        // Create new alert
        const alertDiv = document.createElement('div');
        alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
        alertDiv.innerHTML = `
            ${message}
            <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        `;
        
        // Insert at the top of the container
        const container = document.querySelector('.container-fluid');
        container.insertBefore(alertDiv, container.firstChild);
        
        // Auto-dismiss after 5 seconds
        setTimeout(() => {
            if (alertDiv.parentNode) {
                alertDiv.remove();
            }
        }, 5000);
    }

    startAutoRefresh() {
        // Refresh data every 30 seconds
        this.refreshInterval = setInterval(() => {
            this.loadData();
        }, 30000);
    }

    stopAutoRefresh() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
            this.refreshInterval = null;
        }
    }
}

// Global functions for button clicks
function startScan() {
    app.startScan();
}

function refreshData() {
    app.refreshData();
}

function exportData() {
    app.exportData();
}

// Initialize the application
const app = new NetworkSwitchGetter();
