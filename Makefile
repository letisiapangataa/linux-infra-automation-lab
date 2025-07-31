# Linux Infrastructure Automation Lab - Makefile
# Provides convenient commands for managing the infrastructure lab

.PHONY: help install check clean status backup restore test security logs monitor

# Default target
help:
	@echo "Linux Infrastructure Automation Lab - Available Commands"
	@echo "======================================================="
	@echo ""
	@echo "Setup Commands:"
	@echo "  install     - Complete lab installation (requires sudo)"
	@echo "  check       - Verify system requirements"
	@echo "  clean       - Remove all lab components"
	@echo ""
	@echo "Management Commands:"
	@echo "  status      - Show status of all services"
	@echo "  backup      - Run manual backup"
	@echo "  restore     - Show restore options"
	@echo "  test        - Run system tests"
	@echo ""
	@echo "Monitoring Commands:"
	@echo "  security    - Run security analysis"
	@echo "  logs        - Show log analysis"
	@echo "  monitor     - Check monitoring health"
	@echo ""
	@echo "Example usage:"
	@echo "  make install    # Install the complete lab"
	@echo "  make status     # Check all service status"
	@echo "  make security   # Run security audit"

# Complete installation
install:
	@echo "Starting Linux Infrastructure Automation Lab installation..."
	@if [ "$$(id -u)" != "0" ]; then \
		echo "Error: Installation requires root privileges"; \
		echo "Please run: sudo make install"; \
		exit 1; \
	fi
	@chmod +x setup.sh scripts/*.sh
	@./setup.sh

# Check system requirements
check:
	@echo "Checking system requirements..."
	@echo "================================"
	@echo "OS Information:"
	@if [ -f /etc/os-release ]; then \
		. /etc/os-release && echo "  Distribution: $$ID $$VERSION_ID"; \
	else \
		echo "  Distribution: Unknown"; \
	fi
	@echo "Hardware Information:"
	@echo "  RAM: $$(free -h | grep '^Mem:' | awk '{print $$2}')"
	@echo "  CPU Cores: $$(nproc)"
	@echo "  Disk Space: $$(df -h / | tail -1 | awk '{print $$4}') available"
	@echo "Network Connectivity:"
	@if ping -c 1 google.com >/dev/null 2>&1; then \
		echo "  Internet: ✓ Connected"; \
	else \
		echo "  Internet: ✗ Not connected"; \
	fi
	@echo "Required Commands:"
	@for cmd in curl wget tar systemctl; do \
		if command -v $$cmd >/dev/null 2>&1; then \
			echo "  $$cmd: ✓ Available"; \
		else \
			echo "  $$cmd: ✗ Missing"; \
		fi \
	done

# Remove all lab components
clean:
	@echo "WARNING: This will remove all lab components!"
	@echo "This includes:"
	@echo "  - Monitoring services (Prometheus, Grafana)"
	@echo "  - Backup automation"
	@echo "  - Custom configurations"
	@echo "  - Log aggregation setup"
	@read -p "Are you sure you want to continue? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "Removing lab components..."; \
		sudo systemctl stop prometheus node_exporter grafana-server 2>/dev/null || true; \
		sudo systemctl disable prometheus node_exporter grafana-server 2>/dev/null || true; \
		sudo rm -rf /etc/prometheus /var/lib/prometheus 2>/dev/null || true; \
		sudo rm -rf /etc/grafana /var/lib/grafana 2>/dev/null || true; \
		sudo rm -rf /opt/backups 2>/dev/null || true; \
		sudo rm -f /usr/local/bin/prometheus /usr/local/bin/promtool 2>/dev/null || true; \
		sudo rm -f /usr/local/bin/node_exporter 2>/dev/null || true; \
		sudo rm -f /usr/local/bin/check-monitoring.sh 2>/dev/null || true; \
		sudo rm -f /usr/local/bin/log-*.sh 2>/dev/null || true; \
		sudo rm -f /etc/systemd/system/{prometheus,node_exporter}.service 2>/dev/null || true; \
		sudo rm -rf /etc/rsyslog.d/0*-server.conf /etc/rsyslog.d/10-custom.conf 2>/dev/null || true; \
		sudo systemctl daemon-reload; \
		echo "Lab components removed."; \
		echo "Note: Original system configurations were backed up during installation."; \
	else \
		echo "Clean operation cancelled."; \
	fi

# Show status of all services
status:
	@echo "Linux Infrastructure Lab - Service Status"
	@echo "========================================="
	@echo ""
	@echo "Core Services:"
	@for service in sshd rsyslog; do \
		if systemctl is-active --quiet $$service; then \
			echo "  $$service: ✓ Running"; \
		else \
			echo "  $$service: ✗ Stopped"; \
		fi \
	done
	@echo ""
	@echo "Monitoring Services:"
	@for service in prometheus node_exporter grafana-server; do \
		if systemctl is-active --quiet $$service 2>/dev/null; then \
			echo "  $$service: ✓ Running"; \
		else \
			echo "  $$service: ✗ Stopped/Not installed"; \
		fi \
	done
	@echo ""
	@echo "Network Ports:"
	@for port_desc in "2222:SSH" "9090:Prometheus" "9100:Node_Exporter" "3000:Grafana" "514:Rsyslog"; do \
		port=$$(echo $$port_desc | cut -d: -f1); \
		desc=$$(echo $$port_desc | cut -d: -f2); \
		if netstat -tuln 2>/dev/null | grep -q ":$$port "; then \
			echo "  $$desc ($$port): ✓ Listening"; \
		else \
			echo "  $$desc ($$port): ✗ Not listening"; \
		fi \
	done
	@echo ""
	@echo "Storage Usage:"
	@if [ -d /opt/backups ]; then \
		echo "  Backup Storage: $$(du -sh /opt/backups 2>/dev/null | cut -f1)"; \
	fi
	@if [ -d /var/lib/prometheus ]; then \
		echo "  Prometheus Data: $$(du -sh /var/lib/prometheus 2>/dev/null | cut -f1)"; \
	fi
	@echo "  Root Filesystem: $$(df -h / | tail -1 | awk '{print $$5}') used"

# Run manual backup
backup:
	@echo "Running manual backup..."
	@if [ -f /opt/backups/scripts/system-backup.sh ]; then \
		sudo -u backup /opt/backups/scripts/system-backup.sh daily; \
	else \
		echo "Error: Backup system not installed. Run 'make install' first."; \
	fi

# Show restore options
restore:
	@echo "Backup Restore Options"
	@echo "====================="
	@if [ -f /opt/backups/scripts/system-restore.sh ]; then \
		echo "Available restore commands:"; \
		echo "  List backup contents:"; \
		echo "    sudo -u backup /opt/backups/scripts/system-restore.sh -l <backup_file>"; \
		echo ""; \
		echo "  Test restore:"; \
		echo "    sudo -u backup /opt/backups/scripts/system-restore.sh -t <backup_file>"; \
		echo ""; \
		echo "  Full restore:"; \
		echo "    sudo -u backup /opt/backups/scripts/system-restore.sh <backup_file>"; \
		echo ""; \
		echo "Available backups:"; \
		if [ -d /opt/backups/daily ]; then \
			ls -la /opt/backups/daily/*.tar.gz 2>/dev/null | tail -5 || echo "    No backups found"; \
		else \
			echo "    Backup directory not found"; \
		fi \
	else \
		echo "Error: Backup system not installed. Run 'make install' first."; \
	fi

# Run system tests
test:
	@echo "Running system tests..."
	@echo "======================"
	@echo ""
	@echo "Service Health Checks:"
	@if command -v /usr/local/bin/check-monitoring.sh >/dev/null 2>&1; then \
		sudo /usr/local/bin/check-monitoring.sh; \
	else \
		echo "  Monitoring health check not available"; \
	fi
	@echo ""
	@echo "Backup Validation:"
	@if [ -f /opt/backups/scripts/backup-validation.sh ]; then \
		sudo -u backup /opt/backups/scripts/backup-validation.sh; \
	else \
		echo "  Backup validation not available"; \
	fi
	@echo ""
	@echo "Log System Test:"
	@logger "MAKEFILE-TEST: System test message - $$(date)"
	@sleep 2
	@if grep -q "MAKEFILE-TEST" /var/log/syslog; then \
		echo "  ✓ Log system working"; \
	else \
		echo "  ✗ Log system test failed"; \
	fi

# Run security analysis
security:
	@echo "Security Analysis"
	@echo "================"
	@if command -v /usr/local/bin/log-analysis.sh >/dev/null 2>&1; then \
		echo "Running security log analysis..."; \
		sudo /usr/local/bin/log-analysis.sh --security; \
	else \
		echo "Security analysis tools not available."; \
		echo "Basic security checks:"; \
		echo ""; \
		echo "SSH Configuration:"; \
		if [ -f /etc/ssh/sshd_config.d/99-hardening.conf ]; then \
			echo "  ✓ SSH hardening configuration found"; \
		else \
			echo "  ✗ SSH hardening not configured"; \
		fi \
		echo ""; \
		echo "Firewall Status:"; \
		if command -v ufw >/dev/null 2>&1; then \
			sudo ufw status | head -5; \
		elif command -v firewall-cmd >/dev/null 2>&1; then \
			sudo firewall-cmd --list-all | head -10; \
		else \
			echo "  No firewall management tool detected"; \
		fi \
		echo ""; \
		echo "Failed Login Attempts (last 24h):"; \
		grep "Failed password" /var/log/auth.log 2>/dev/null | grep "$$(date '+%b %d')" | wc -l || echo "  0"; \
	fi

# Show log analysis
logs:
	@echo "Log Analysis"
	@echo "==========="
	@if command -v /usr/local/bin/log-analysis.sh >/dev/null 2>&1; then \
		echo "Select log analysis type:"; \
		echo "  1) Security summary"; \
		echo "  2) Authentication analysis"; \
		echo "  3) Error summary"; \
		echo "  4) Top IPs"; \
		echo "  5) User activity"; \
		read -p "Enter choice (1-5): " choice; \
		case $$choice in \
			1) sudo /usr/local/bin/log-analysis.sh --security ;; \
			2) sudo /usr/local/bin/log-analysis.sh --auth ;; \
			3) sudo /usr/local/bin/log-analysis.sh --errors ;; \
			4) sudo /usr/local/bin/log-analysis.sh --top-ips ;; \
			5) sudo /usr/local/bin/log-analysis.sh --users ;; \
			*) echo "Invalid choice" ;; \
		esac \
	else \
		echo "Log analysis tools not available."; \
		echo "Basic log information:"; \
		echo ""; \
		echo "Recent log entries:"; \
		tail -10 /var/log/syslog 2>/dev/null || echo "  Cannot access syslog"; \
		echo ""; \
		echo "Log file sizes:"; \
		ls -lh /var/log/*.log 2>/dev/null | head -5 || echo "  No log files found"; \
	fi

# Check monitoring health
monitor:
	@echo "Monitoring Health Check"
	@echo "======================"
	@if command -v /usr/local/bin/check-monitoring.sh >/dev/null 2>&1; then \
		sudo /usr/local/bin/check-monitoring.sh; \
	else \
		echo "Monitoring health script not available."; \
		echo "Manual monitoring checks:"; \
		echo ""; \
		echo "Prometheus Status:"; \
		if curl -sf http://localhost:9090/-/ready >/dev/null 2>&1; then \
			echo "  ✓ Prometheus is ready"; \
		else \
			echo "  ✗ Prometheus not responding"; \
		fi \
		echo ""; \
		echo "Grafana Status:"; \
		if curl -sf http://localhost:3000/api/health >/dev/null 2>&1; then \
			echo "  ✓ Grafana is healthy"; \
		else \
			echo "  ✗ Grafana not responding"; \
		fi \
		echo ""; \
		echo "Node Exporter Metrics:"; \
		if curl -sf http://localhost:9100/metrics | head -1 >/dev/null 2>&1; then \
			echo "  ✓ Node Exporter providing metrics"; \
		else \
			echo "  ✗ Node Exporter not responding"; \
		fi \
	fi

# Development and testing targets
dev-test:
	@echo "Running development tests..."
	@bash -n setup.sh && echo "✓ setup.sh syntax OK" || echo "✗ setup.sh syntax error"
	@for script in scripts/*.sh; do \
		bash -n "$$script" && echo "✓ $$script syntax OK" || echo "✗ $$script syntax error"; \
	done

# Generate documentation
docs:
	@echo "Documentation available in docs/ directory:"
	@ls -la docs/ 2>/dev/null || echo "Documentation directory not found"
	@echo ""
	@echo "Quick access:"
	@echo "  Installation Guide: docs/installation-guide.md"
	@echo "  Recovery Procedures: docs/recovery-procedures.md"
	@echo "  Architecture Diagram: docs/architecture-diagram.md"
