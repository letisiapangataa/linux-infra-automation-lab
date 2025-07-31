#!/bin/bash

# Monitoring Setup Script - Prometheus Node Exporter & Grafana
# Author: Linux Infrastructure Automation Lab
# Description: Sets up monitoring infrastructure with Prometheus and Grafana
# Date: $(date +%Y-%m-%d)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
PROMETHEUS_VERSION="2.45.0"
NODE_EXPORTER_VERSION="1.6.1"
GRAFANA_VERSION="10.0.3"
PROMETHEUS_USER="prometheus"
GRAFANA_USER="grafana"

# Logging setup
LOG_FILE="/var/log/monitoring-setup.log"
exec 1> >(tee -a "$LOG_FILE")
exec 2> >(tee -a "$LOG_FILE" >&2)

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        print_error "Cannot detect OS. Exiting."
        exit 1
    fi
    print_status "Detected OS: $OS $VERSION"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        exit 1
    fi
}

# Create monitoring users
create_users() {
    print_status "Creating monitoring users..."
    
    # Create prometheus user
    if ! id "$PROMETHEUS_USER" &>/dev/null; then
        useradd --no-create-home --shell /bin/false "$PROMETHEUS_USER"
        print_status "Created user: $PROMETHEUS_USER"
    fi
    
    # Create grafana user
    if ! id "$GRAFANA_USER" &>/dev/null; then
        useradd --system --shell /bin/false --home /var/lib/grafana "$GRAFANA_USER"
        print_status "Created user: $GRAFANA_USER"
    fi
    
    print_success "Monitoring users created"
}

# Install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    case $OS in
        ubuntu|debian)
            apt-get update
            apt-get install -y wget curl tar systemd adduser libfontconfig1
            ;;
        centos|rhel|fedora)
            yum update -y
            yum install -y wget curl tar systemd fontconfig
            ;;
        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    print_success "Dependencies installed"
}

# Install Prometheus
install_prometheus() {
    print_status "Installing Prometheus $PROMETHEUS_VERSION..."
    
    # Download and extract Prometheus
    cd /tmp
    wget "https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
    tar xzf "prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz"
    
    # Create directories
    mkdir -p /etc/prometheus /var/lib/prometheus
    
    # Copy binaries
    cp "prometheus-${PROMETHEUS_VERSION}.linux-amd64/prometheus" /usr/local/bin/
    cp "prometheus-${PROMETHEUS_VERSION}.linux-amd64/promtool" /usr/local/bin/
    cp -r "prometheus-${PROMETHEUS_VERSION}.linux-amd64/consoles" /etc/prometheus/
    cp -r "prometheus-${PROMETHEUS_VERSION}.linux-amd64/console_libraries" /etc/prometheus/
    
    # Set permissions
    chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
    chmod +x /usr/local/bin/prometheus /usr/local/bin/promtool
    
    # Create Prometheus configuration
    cat > /etc/prometheus/prometheus.yml << 'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "node_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
    
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
    scrape_interval: 5s
    metrics_path: /metrics
    
  - job_name: 'linux_servers'
    static_configs:
      - targets: ['localhost:9100']
    scrape_interval: 15s

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093
EOF

    # Create alert rules
    cat > /etc/prometheus/node_rules.yml << 'EOF'
groups:
  - name: node_alerts
    rules:
      - alert: HighCPUUsage
        expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.instance }}"
          description: "CPU usage is above 80% for more than 5 minutes"
          
      - alert: HighMemoryUsage
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.instance }}"
          description: "Memory usage is above 85% for more than 5 minutes"
          
      - alert: DiskSpaceLow
        expr: (1 - (node_filesystem_avail_bytes{fstype!="tmpfs"} / node_filesystem_size_bytes{fstype!="tmpfs"})) * 100 > 90
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Low disk space on {{ $labels.instance }}"
          description: "Disk usage is above 90% on {{ $labels.mountpoint }}"
          
      - alert: NodeDown
        expr: up{job="node_exporter"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Node is down"
          description: "{{ $labels.instance }} has been down for more than 1 minute"
EOF

    chown prometheus:prometheus /etc/prometheus/prometheus.yml /etc/prometheus/node_rules.yml
    
    # Create systemd service
    cat > /etc/systemd/system/prometheus.service << 'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries \
    --web.listen-address=0.0.0.0:9090 \
    --web.enable-lifecycle \
    --storage.tsdb.retention.time=30d

[Install]
WantedBy=multi-user.target
EOF

    # Clean up
    rm -rf "/tmp/prometheus-${PROMETHEUS_VERSION}.linux-amd64"*
    
    print_success "Prometheus installed"
}

# Install Node Exporter
install_node_exporter() {
    print_status "Installing Node Exporter $NODE_EXPORTER_VERSION..."
    
    # Download and extract Node Exporter
    cd /tmp
    wget "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
    tar xzf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
    
    # Copy binary
    cp "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
    chmod +x /usr/local/bin/node_exporter
    
    # Create systemd service
    cat > /etc/systemd/system/node_exporter.service << 'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/node_exporter \
    --collector.systemd \
    --collector.processes \
    --web.listen-address=0.0.0.0:9100

[Install]
WantedBy=multi-user.target
EOF

    # Clean up
    rm -rf "/tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"*
    
    print_success "Node Exporter installed"
}

# Install Grafana
install_grafana() {
    print_status "Installing Grafana..."
    
    case $OS in
        ubuntu|debian)
            # Add Grafana repository
            wget -q -O - https://packages.grafana.com/gpg.key | apt-key add -
            echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
            apt-get update
            apt-get install -y grafana
            ;;
        centos|rhel|fedora)
            # Add Grafana repository
            cat > /etc/yum.repos.d/grafana.repo << 'EOF'
[grafana]
name=grafana
baseurl=https://packages.grafana.com/oss/rpm
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://packages.grafana.com/gpg.key
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
            yum install -y grafana
            ;;
    esac
    
    # Configure Grafana
    cat > /etc/grafana/grafana.ini << 'EOF'
[server]
http_port = 3000
domain = localhost

[security]
admin_user = admin
admin_password = admin123

[users]
allow_sign_up = false
allow_org_create = false

[auth.anonymous]
enabled = false

[dashboards]
default_home_dashboard_path = /var/lib/grafana/dashboards/node-exporter.json

[log]
mode = file
level = info
EOF

    print_success "Grafana installed"
}

# Create Grafana dashboard
create_grafana_dashboard() {
    print_status "Creating Grafana dashboard..."
    
    mkdir -p /var/lib/grafana/dashboards
    
    cat > /var/lib/grafana/dashboards/node-exporter.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "Node Exporter Server Metrics",
    "tags": ["node-exporter"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "CPU Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "CPU Usage %"
          }
        ],
        "yAxes": [
          {
            "min": 0,
            "max": 100,
            "unit": "percent"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        }
      },
      {
        "id": 2,
        "title": "Memory Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100",
            "legendFormat": "Memory Usage %"
          }
        ],
        "yAxes": [
          {
            "min": 0,
            "max": 100,
            "unit": "percent"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        }
      },
      {
        "id": 3,
        "title": "Disk Usage",
        "type": "graph",
        "targets": [
          {
            "expr": "(1 - (node_filesystem_avail_bytes{fstype!=\"tmpfs\"} / node_filesystem_size_bytes{fstype!=\"tmpfs\"})) * 100",
            "legendFormat": "Disk Usage % - {{ mountpoint }}"
          }
        ],
        "yAxes": [
          {
            "min": 0,
            "max": 100,
            "unit": "percent"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 8
        }
      },
      {
        "id": 4,
        "title": "Network Traffic",
        "type": "graph",
        "targets": [
          {
            "expr": "irate(node_network_receive_bytes_total{device!=\"lo\"}[5m])",
            "legendFormat": "Received - {{ device }}"
          },
          {
            "expr": "irate(node_network_transmit_bytes_total{device!=\"lo\"}[5m])",
            "legendFormat": "Transmitted - {{ device }}"
          }
        ],
        "yAxes": [
          {
            "unit": "bytes"
          }
        ],
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 16
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  }
}
EOF

    chown -R grafana:grafana /var/lib/grafana/dashboards
    print_success "Grafana dashboard created"
}

# Start and enable services
start_services() {
    print_status "Starting and enabling monitoring services..."
    
    # Reload systemd
    systemctl daemon-reload
    
    # Start and enable services
    systemctl enable node_exporter prometheus grafana-server
    systemctl start node_exporter
    systemctl start prometheus
    systemctl start grafana-server
    
    # Wait for services to start
    sleep 10
    
    # Check service status
    if systemctl is-active --quiet node_exporter; then
        print_success "Node Exporter is running"
    else
        print_error "Node Exporter failed to start"
    fi
    
    if systemctl is-active --quiet prometheus; then
        print_success "Prometheus is running"
    else
        print_error "Prometheus failed to start"
    fi
    
    if systemctl is-active --quiet grafana-server; then
        print_success "Grafana is running"
    else
        print_error "Grafana failed to start"
    fi
}

# Configure firewall for monitoring
configure_monitoring_firewall() {
    print_status "Configuring firewall for monitoring..."
    
    case $OS in
        ubuntu|debian)
            if command -v ufw >/dev/null 2>&1; then
                ufw allow 9090/tcp comment 'Prometheus'
                ufw allow 9100/tcp comment 'Node Exporter'
                ufw allow 3000/tcp comment 'Grafana'
            fi
            ;;
        centos|rhel|fedora)
            if command -v firewall-cmd >/dev/null 2>&1; then
                firewall-cmd --zone=public --add-port=9090/tcp --permanent
                firewall-cmd --zone=public --add-port=9100/tcp --permanent
                firewall-cmd --zone=public --add-port=3000/tcp --permanent
                firewall-cmd --reload
            fi
            ;;
    esac
    
    print_success "Firewall configured for monitoring"
}

# Create monitoring validation script
create_validation_script() {
    print_status "Creating monitoring validation script..."
    
    cat > /usr/local/bin/check-monitoring.sh << 'EOF'
#!/bin/bash

# Monitoring Health Check Script

echo "=== Monitoring Services Health Check ==="
echo "Timestamp: $(date)"
echo

# Check Node Exporter
echo "Node Exporter Status:"
if systemctl is-active --quiet node_exporter; then
    echo "✓ Node Exporter is running"
    if curl -s http://localhost:9100/metrics > /dev/null; then
        echo "✓ Node Exporter metrics endpoint is accessible"
    else
        echo "✗ Node Exporter metrics endpoint is not accessible"
    fi
else
    echo "✗ Node Exporter is not running"
fi

echo

# Check Prometheus
echo "Prometheus Status:"
if systemctl is-active --quiet prometheus; then
    echo "✓ Prometheus is running"
    if curl -s http://localhost:9090/-/ready > /dev/null; then
        echo "✓ Prometheus is ready"
    else
        echo "✗ Prometheus is not ready"
    fi
else
    echo "✗ Prometheus is not running"
fi

echo

# Check Grafana
echo "Grafana Status:"
if systemctl is-active --quiet grafana-server; then
    echo "✓ Grafana is running"
    if curl -s http://localhost:3000/api/health > /dev/null; then
        echo "✓ Grafana API is accessible"
    else
        echo "✗ Grafana API is not accessible"
    fi
else
    echo "✗ Grafana is not running"
fi

echo
echo "=== Monitoring URLs ==="
echo "Prometheus: http://$(hostname -I | awk '{print $1}'):9090"
echo "Node Exporter: http://$(hostname -I | awk '{print $1}'):9100/metrics"
echo "Grafana: http://$(hostname -I | awk '{print $1}'):3000"
echo "Default Grafana credentials: admin/admin123"
EOF

    chmod +x /usr/local/bin/check-monitoring.sh
    print_success "Validation script created at /usr/local/bin/check-monitoring.sh"
}

# Main execution
main() {
    print_status "Starting Monitoring Setup..."
    print_status "Timestamp: $(date)"
    
    check_root
    detect_os
    
    install_dependencies
    create_users
    install_prometheus
    install_node_exporter
    install_grafana
    create_grafana_dashboard
    start_services
    configure_monitoring_firewall
    create_validation_script
    
    print_success "Monitoring setup completed successfully!"
    print_status "Running validation check..."
    /usr/local/bin/check-monitoring.sh
    
    echo
    print_status "Access your monitoring services:"
    print_status "Prometheus: http://$(hostname -I | awk '{print $1}'):9090"
    print_status "Grafana: http://$(hostname -I | awk '{print $1}'):3000 (admin/admin123)"
    print_status "Node Exporter: http://$(hostname -I | awk '{print $1}'):9100/metrics"
}

# Run main function
main "$@"
