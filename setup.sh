#!/bin/bash

# Linux Infrastructure Automation Lab - Master Setup Script
# Author: Linux Infrastructure Automation Lab
# Description: Complete automated setup of the infrastructure lab
# Date: $(date +%Y-%m-%d)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║                                                                      ║"
    echo "║         🐧 Linux Infrastructure Automation Lab Setup 🐧              ║"
    echo "║                                                                      ║"
    echo "║  A comprehensive Linux infrastructure management and security lab    ║"
    echo "║                                                                      ║"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

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

print_section() {
    echo
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}═══════════════════════════════════════════════════════════════════════${NC}"
    echo
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root"
        print_status "Please run: sudo $0"
        exit 1
    fi
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

# Check system requirements
check_requirements() {
    print_status "Checking system requirements..."
    
    # Check RAM
    RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $RAM_GB -lt 3 ]]; then
        print_warning "RAM: ${RAM_GB}GB detected. Recommended: 4GB+"
    else
        print_success "RAM: ${RAM_GB}GB ✓"
    fi
    
    # Check disk space
    DISK_GB=$(df / | awk 'NR==2{printf "%.0f", $4/1024/1024}')
    if [[ $DISK_GB -lt 40 ]]; then
        print_warning "Disk space: ${DISK_GB}GB available. Recommended: 50GB+"
    else
        print_success "Disk space: ${DISK_GB}GB available ✓"
    fi
    
    # Check CPU cores
    CPU_CORES=$(nproc)
    if [[ $CPU_CORES -lt 2 ]]; then
        print_warning "CPU cores: $CPU_CORES. Recommended: 2+"
    else
        print_success "CPU cores: $CPU_CORES ✓"
    fi
    
    # Check internet connectivity
    if ping -c 1 google.com >/dev/null 2>&1; then
        print_success "Internet connectivity ✓"
    else
        print_error "No internet connectivity. Required for package downloads."
        exit 1
    fi
}

# Create backup of original configurations
create_config_backup() {
    print_status "Creating backup of original configurations..."
    
    BACKUP_DIR="/root/pre-lab-configs-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # Backup important config files
    [[ -f /etc/ssh/sshd_config ]] && cp /etc/ssh/sshd_config "$BACKUP_DIR/"
    [[ -f /etc/rsyslog.conf ]] && cp /etc/rsyslog.conf "$BACKUP_DIR/"
    [[ -f /etc/sysctl.conf ]] && cp /etc/sysctl.conf "$BACKUP_DIR/"
    
    # Create restore script
    cat > "$BACKUP_DIR/restore.sh" << EOF
#!/bin/bash
# Restore original configurations
echo "Restoring original configurations..."
[[ -f sshd_config ]] && cp sshd_config /etc/ssh/sshd_config
[[ -f rsyslog.conf ]] && cp rsyslog.conf /etc/rsyslog.conf
[[ -f sysctl.conf ]] && cp sysctl.conf /etc/sysctl.conf
echo "Configurations restored. Please reboot the system."
EOF
    chmod +x "$BACKUP_DIR/restore.sh"
    
    print_success "Original configurations backed up to: $BACKUP_DIR"
}

# Prepare scripts
prepare_scripts() {
    print_status "Preparing setup scripts..."
    
    # Make all scripts executable
    chmod +x "$SCRIPT_DIR/scripts/"*.sh
    
    # Verify all required scripts exist
    local required_scripts=(
        "hardening.sh"
        "monitoring-setup.sh"
        "log-aggregation.sh"
        "backup-automation.sh"
    )
    
    for script in "${required_scripts[@]}"; do
        if [[ -f "$SCRIPT_DIR/scripts/$script" ]]; then
            print_success "Found: $script ✓"
        else
            print_error "Missing required script: $script"
            exit 1
        fi
    done
}

# Run hardening script
run_hardening() {
    print_section "🔐 PHASE 1: SYSTEM HARDENING"
    print_status "Running system hardening script..."
    
    if "$SCRIPT_DIR/scripts/hardening.sh"; then
        print_success "System hardening completed successfully"
        return 0
    else
        print_error "System hardening failed"
        return 1
    fi
}

# Run monitoring setup
run_monitoring() {
    print_section "📊 PHASE 2: MONITORING SETUP"
    print_status "Setting up monitoring infrastructure..."
    
    if "$SCRIPT_DIR/scripts/monitoring-setup.sh"; then
        print_success "Monitoring setup completed successfully"
        return 0
    else
        print_error "Monitoring setup failed"
        return 1
    fi
}

# Run log aggregation setup
run_log_aggregation() {
    print_section "🧾 PHASE 3: LOG AGGREGATION"
    print_status "Configuring log aggregation..."
    
    if "$SCRIPT_DIR/scripts/log-aggregation.sh"; then
        print_success "Log aggregation setup completed successfully"
        return 0
    else
        print_error "Log aggregation setup failed"
        return 1
    fi
}

# Run backup automation setup
run_backup_automation() {
    print_section "💾 PHASE 4: BACKUP AUTOMATION"
    print_status "Setting up backup automation..."
    
    if "$SCRIPT_DIR/scripts/backup-automation.sh"; then
        print_success "Backup automation setup completed successfully"
        return 0
    else
        print_error "Backup automation setup failed"
        return 1
    fi
}

# Verify installation
verify_installation() {
    print_section "✅ INSTALLATION VERIFICATION"
    print_status "Verifying installation..."
    
    local verification_failed=0
    
    # Check services
    local services=(
        "sshd"
        "prometheus"
        "node_exporter"
        "grafana-server"
        "rsyslog"
    )
    
    for service in "${services[@]}"; do
        if systemctl is-active --quiet "$service"; then
            print_success "$service is running ✓"
        else
            print_error "$service is not running ✗"
            ((verification_failed++))
        fi
    done
    
    # Check ports
    local ports=(
        "2222"  # SSH
        "9090"  # Prometheus
        "9100"  # Node Exporter
        "3000"  # Grafana
        "514"   # Rsyslog
    )
    
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            print_success "Port $port is listening ✓"
        else
            print_warning "Port $port is not listening"
        fi
    done
    
    # Check backup setup
    if [[ -d /opt/backups && -f /opt/backups/scripts/backup-status.sh ]]; then
        print_success "Backup system configured ✓"
    else
        print_error "Backup system not properly configured ✗"
        ((verification_failed++))
    fi
    
    # Check monitoring endpoints
    if curl -sf http://localhost:9090/-/ready >/dev/null 2>&1; then
        print_success "Prometheus is ready ✓"
    else
        print_warning "Prometheus health check failed"
    fi
    
    if curl -sf http://localhost:3000/api/health >/dev/null 2>&1; then
        print_success "Grafana is ready ✓"
    else
        print_warning "Grafana health check failed"
    fi
    
    if [[ $verification_failed -eq 0 ]]; then
        print_success "All critical services verified successfully"
        return 0
    else
        print_warning "$verification_failed verification checks failed"
        return 1
    fi
}

# Generate access information
generate_access_info() {
    print_section "🌐 ACCESS INFORMATION"
    
    local server_ip
    server_ip=$(hostname -I | awk '{print $1}')
    
    echo -e "${GREEN}Your Linux Infrastructure Lab is ready!${NC}"
    echo
    echo -e "${BLUE}Access Information:${NC}"
    echo "===================="
    echo
    echo -e "${YELLOW}SSH Access:${NC}"
    echo "  Port: 2222 (password auth disabled, keys only)"
    echo "  Command: ssh -p 2222 user@$server_ip"
    echo
    echo -e "${YELLOW}Monitoring Dashboard:${NC}"
    echo "  Grafana: http://$server_ip:3000"
    echo "  Username: admin"
    echo "  Password: admin123"
    echo
    echo -e "${YELLOW}Metrics & Monitoring:${NC}"
    echo "  Prometheus: http://$server_ip:9090"
    echo "  Node Exporter: http://$server_ip:9100/metrics"
    echo
    echo -e "${YELLOW}Management Tools:${NC}"
    echo "  Backup Status: sudo -u backup /opt/backups/scripts/backup-status.sh"
    echo "  Log Analysis: sudo /usr/local/bin/log-analysis.sh --help"
    echo "  System Status: sudo /usr/local/bin/check-monitoring.sh"
    echo
    echo -e "${YELLOW}Important Notes:${NC}"
    echo "  • SSH port changed to 2222 for security"
    echo "  • Root SSH login disabled"
    echo "  • Daily backups scheduled at 2:00 AM"
    echo "  • Log retention: 30 days"
    echo "  • Prometheus retention: 30 days"
    echo
}

# Generate summary report
generate_summary_report() {
    local report_file="/root/lab-setup-summary-$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$report_file" << EOF
Linux Infrastructure Automation Lab - Setup Summary
===================================================
Setup Date: $(date)
Hostname: $(hostname)
IP Address: $(hostname -I | awk '{print $1}')
OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")

Installed Components:
- System Hardening (SSH, Firewall, Auditing)
- Monitoring Stack (Prometheus, Grafana, Node Exporter)
- Log Aggregation (rsyslog, logrotate, analysis tools)
- Backup Automation (daily/weekly/monthly backups)

Service Status:
$(systemctl is-active sshd prometheus node_exporter grafana-server rsyslog | paste <(echo -e "SSH\nPrometheus\nNode Exporter\nGrafana\nRsyslog") -)

Port Configuration:
- SSH: 2222
- Prometheus: 9090
- Grafana: 3000
- Node Exporter: 9100
- Rsyslog: 514

Key File Locations:
- Backup Scripts: /opt/backups/scripts/
- Monitoring Config: /etc/prometheus/
- Log Config: /etc/rsyslog.d/
- Security Config: /etc/ssh/sshd_config.d/

Scheduled Tasks:
- Daily Backup: 02:00
- Weekly Backup: Sunday 03:00
- Monthly Backup: 1st day 04:00
- Log Monitoring: Every 15 minutes

Next Steps:
1. Change Grafana admin password
2. Configure additional monitoring targets
3. Set up remote backup destination
4. Review and customize security policies
5. Test disaster recovery procedures

Configuration Backup: $BACKUP_DIR
EOF
    
    print_success "Setup summary saved to: $report_file"
}

# Prompt for reboot
prompt_reboot() {
    echo
    print_warning "Some changes require a system reboot to take full effect."
    echo
    read -p "Would you like to reboot now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Rebooting system in 10 seconds..."
        print_status "After reboot, SSH will be available on port 2222"
        sleep 10
        reboot
    else
        print_status "Reboot skipped. Please reboot manually when convenient."
        print_status "SSH port change will take effect after reboot."
    fi
}

# Main execution function
main() {
    local start_time=$(date +%s)
    
    print_banner
    
    print_status "Starting Linux Infrastructure Automation Lab setup..."
    print_status "This will install and configure:"
    print_status "  • System hardening and security"
    print_status "  • Monitoring with Prometheus and Grafana"
    print_status "  • Centralized log aggregation"
    print_status "  • Automated backup system"
    echo
    
    # Confirmation prompt
    read -p "Do you want to proceed with the installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled by user."
        exit 0
    fi
    
    # Pre-installation checks
    check_root
    detect_os
    check_requirements
    create_config_backup
    prepare_scripts
    
    # Track failed phases
    local failed_phases=()
    
    # Run installation phases
    if ! run_hardening; then
        failed_phases+=("Hardening")
    fi
    
    if ! run_monitoring; then
        failed_phases+=("Monitoring")
    fi
    
    if ! run_log_aggregation; then
        failed_phases+=("Log Aggregation")
    fi
    
    if ! run_backup_automation; then
        failed_phases+=("Backup Automation")
    fi
    
    # Post-installation verification
    verify_installation
    
    # Generate reports and access info
    generate_access_info
    generate_summary_report
    
    # Calculate installation time
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    echo
    print_section "🎉 INSTALLATION COMPLETE"
    
    if [[ ${#failed_phases[@]} -eq 0 ]]; then
        print_success "All phases completed successfully!"
        print_success "Total installation time: ${minutes}m ${seconds}s"
    else
        print_warning "Installation completed with some issues:"
        for phase in "${failed_phases[@]}"; do
            print_warning "  • $phase phase had problems"
        done
        print_status "Check the logs above for details"
        print_status "Total installation time: ${minutes}m ${seconds}s"
    fi
    
    echo
    print_status "For detailed usage instructions, see:"
    print_status "  • docs/installation-guide.md"
    print_status "  • docs/recovery-procedures.md"
    print_status "  • docs/architecture-diagram.md"
    
    # Offer reboot
    prompt_reboot
}

# Trap for cleanup on exit
trap 'print_error "Installation interrupted. Check logs for details."' ERR

# Run main function
main "$@"
