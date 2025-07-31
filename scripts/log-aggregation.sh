#!/bin/bash

# Log Aggregation Setup Script
# Author: Linux Infrastructure Automation Lab
# Description: Configures centralized logging with rsyslog and log rotation
# Date: $(date +%Y-%m-%d)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
LOG_SERVER_IP="127.0.0.1"
LOG_SERVER_PORT="514"
LOG_RETENTION_DAYS="30"
LOG_ROTATION_SIZE="100M"

# Logging setup
LOG_FILE="/var/log/log-aggregation-setup.log"
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

# Install required packages
install_packages() {
    print_status "Installing logging packages..."
    
    case $OS in
        ubuntu|debian)
            apt-get update
            apt-get install -y rsyslog rsyslog-gnutls logrotate mailutils
            ;;
        centos|rhel|fedora)
            yum update -y
            yum install -y rsyslog rsyslog-gnutls logrotate mailx
            ;;
        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    print_success "Logging packages installed"
}

# Configure rsyslog server
configure_rsyslog_server() {
    print_status "Configuring rsyslog server..."
    
    # Backup original config
    cp /etc/rsyslog.conf /etc/rsyslog.conf.backup.$(date +%Y%m%d)
    
    # Create rsyslog server configuration
    cat > /etc/rsyslog.d/00-server.conf << 'EOF'
# Enable UDP syslog reception
module(load="imudp")
input(type="imudp" port="514")

# Enable TCP syslog reception
module(load="imtcp")
input(type="imtcp" port="514")

# Create log directories
$CreateDirs on

# Template for remote logs
$template RemoteLogs,"/var/log/remote/%HOSTNAME%/%PROGRAMNAME%.log"

# Store remote logs
*.* ?RemoteLogs
& stop

# Local system logs
*.*;auth,authpriv.none          /var/log/syslog
auth,authpriv.*                 /var/log/auth.log
kern.*                          /var/log/kern.log
mail.*                          /var/log/mail.log
user.*                          /var/log/user.log
daemon.*                        /var/log/daemon.log
EOF

    # Create advanced rsyslog configuration
    cat > /etc/rsyslog.d/10-custom.conf << 'EOF'
# Custom log filtering and routing

# Security logs
:msg,contains,"authentication failure" /var/log/security/auth-failures.log
:msg,contains,"Failed password" /var/log/security/failed-passwords.log
:msg,contains,"sudo" /var/log/security/sudo.log

# SSH logs
:programname,isequal,"sshd" /var/log/security/ssh.log

# Web server logs (if applicable)
:programname,isequal,"apache2" /var/log/applications/apache.log
:programname,isequal,"nginx" /var/log/applications/nginx.log

# Database logs
:programname,isequal,"mysql" /var/log/applications/mysql.log
:programname,isequal,"postgresql" /var/log/applications/postgresql.log

# System monitoring
:programname,isequal,"prometheus" /var/log/monitoring/prometheus.log
:programname,isequal,"node_exporter" /var/log/monitoring/node_exporter.log
:programname,isequal,"grafana-server" /var/log/monitoring/grafana.log

# Firewall logs
:msg,contains,"UFW" /var/log/security/firewall.log
:msg,contains,"iptables" /var/log/security/iptables.log

# Create emergency log for critical messages
*.emerg                         /var/log/emergency.log

# Forward critical logs to external syslog if configured
*.crit                          @@remote-syslog-server:514
EOF

    # Create log directories
    mkdir -p /var/log/{remote,security,applications,monitoring}
    chown -R syslog:adm /var/log/{remote,security,applications,monitoring}
    chmod -R 750 /var/log/{remote,security,applications,monitoring}
    
    print_success "Rsyslog server configured"
}

# Configure log rotation
configure_logrotate() {
    print_status "Configuring log rotation..."
    
    # Security logs rotation
    cat > /etc/logrotate.d/security-logs << EOF
/var/log/security/*.log {
    daily
    missingok
    rotate $LOG_RETENTION_DAYS
    compress
    delaycompress
    notifempty
    create 640 syslog adm
    size $LOG_ROTATION_SIZE
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF

    # Application logs rotation
    cat > /etc/logrotate.d/application-logs << EOF
/var/log/applications/*.log {
    daily
    missingok
    rotate $LOG_RETENTION_DAYS
    compress
    delaycompress
    notifempty
    create 640 syslog adm
    size $LOG_ROTATION_SIZE
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF

    # Monitoring logs rotation
    cat > /etc/logrotate.d/monitoring-logs << EOF
/var/log/monitoring/*.log {
    daily
    missingok
    rotate $LOG_RETENTION_DAYS
    compress
    delaycompress
    notifempty
    create 640 syslog adm
    size $LOG_ROTATION_SIZE
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF

    # Remote logs rotation
    cat > /etc/logrotate.d/remote-logs << EOF
/var/log/remote/*/*.log {
    daily
    missingok
    rotate $LOG_RETENTION_DAYS
    compress
    delaycompress
    notifempty
    create 640 syslog adm
    size $LOG_ROTATION_SIZE
    sharedscripts
    postrotate
        systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
EOF

    print_success "Log rotation configured"
}

# Configure log monitoring and alerting
configure_log_monitoring() {
    print_status "Configuring log monitoring and alerting..."
    
    # Create log monitoring script
    cat > /usr/local/bin/log-monitor.sh << 'EOF'
#!/bin/bash

# Log Monitoring and Alerting Script
# Monitors logs for security events and sends alerts

ALERT_EMAIL="admin@localhost"
TEMP_DIR="/tmp/log-monitor"
LAST_CHECK_FILE="$TEMP_DIR/last_check"

# Create temp directory
mkdir -p "$TEMP_DIR"

# Get last check time
if [[ -f "$LAST_CHECK_FILE" ]]; then
    LAST_CHECK=$(cat "$LAST_CHECK_FILE")
else
    LAST_CHECK=$(date -d "1 hour ago" +%s)
fi

CURRENT_TIME=$(date +%s)
echo "$CURRENT_TIME" > "$LAST_CHECK_FILE"

# Convert to date format for log searching
LAST_CHECK_DATE=$(date -d "@$LAST_CHECK" "+%b %d %H:%M")
CURRENT_DATE=$(date "+%b %d %H:%M")

# Function to send alert
send_alert() {
    local subject="$1"
    local message="$2"
    echo "$message" | mail -s "$subject" "$ALERT_EMAIL"
    logger "ALERT SENT: $subject"
}

# Monitor authentication failures
AUTH_FAILURES=$(grep -c "authentication failure\|Failed password" /var/log/auth.log | tail -1)
if [[ $AUTH_FAILURES -gt 10 ]]; then
    send_alert "High Authentication Failures" "Detected $AUTH_FAILURES authentication failures since last check"
fi

# Monitor SSH brute force attempts
SSH_FAILURES=$(grep "Failed password" /var/log/auth.log | grep -c "$(date '+%b %d')")
if [[ $SSH_FAILURES -gt 20 ]]; then
    send_alert "SSH Brute Force Alert" "Detected $SSH_FAILURES SSH login failures today"
fi

# Monitor sudo usage
SUDO_USAGE=$(grep -c "sudo" /var/log/auth.log | tail -1)
if [[ $SUDO_USAGE -gt 50 ]]; then
    send_alert "High Sudo Usage" "Detected $SUDO_USAGE sudo commands since last check"
fi

# Monitor disk space in log directories
LOG_DISK_USAGE=$(df /var/log | awk 'NR==2 {print $5}' | sed 's/%//')
if [[ $LOG_DISK_USAGE -gt 85 ]]; then
    send_alert "Log Disk Space Alert" "Log directory is $LOG_DISK_USAGE% full"
fi

# Monitor for specific security events
if grep -q "POSSIBLE BREAK-IN ATTEMPT\|Invalid user\|ROOT LOGIN" /var/log/auth.log; then
    send_alert "Security Event Alert" "Potential security breach detected in auth logs"
fi

# Check for new emergency logs
if [[ -f /var/log/emergency.log && -s /var/log/emergency.log ]]; then
    EMERGENCY_COUNT=$(wc -l < /var/log/emergency.log)
    if [[ $EMERGENCY_COUNT -gt 0 ]]; then
        send_alert "Emergency Log Alert" "Found $EMERGENCY_COUNT emergency log entries"
    fi
fi
EOF

    chmod +x /usr/local/bin/log-monitor.sh
    
    # Create cron job for log monitoring
    cat > /etc/cron.d/log-monitor << 'EOF'
# Log monitoring cron job - runs every 15 minutes
*/15 * * * * root /usr/local/bin/log-monitor.sh >/dev/null 2>&1
EOF

    print_success "Log monitoring configured"
}

# Configure log analysis tools
configure_log_analysis() {
    print_status "Setting up log analysis tools..."
    
    # Create log analysis script
    cat > /usr/local/bin/log-analysis.sh << 'EOF'
#!/bin/bash

# Log Analysis Script
# Provides various log analysis functions

print_usage() {
    echo "Usage: $0 [option]"
    echo "Options:"
    echo "  -s, --security    Show security-related log summary"
    echo "  -a, --auth        Show authentication log analysis"
    echo "  -e, --errors      Show error log summary"
    echo "  -t, --top-ips     Show top source IPs"
    echo "  -u, --users       Show user activity summary"
    echo "  -h, --help        Show this help message"
}

security_summary() {
    echo "=== Security Log Summary ==="
    echo "Date: $(date)"
    echo
    
    echo "Authentication Failures (last 24h):"
    grep "authentication failure\|Failed password" /var/log/auth.log | \
    grep "$(date '+%b %d')" | wc -l
    
    echo
    echo "Successful SSH Logins (last 24h):"
    grep "Accepted password\|Accepted publickey" /var/log/auth.log | \
    grep "$(date '+%b %d')" | wc -l
    
    echo
    echo "Sudo Commands (last 24h):"
    grep "sudo" /var/log/auth.log | grep "$(date '+%b %d')" | wc -l
    
    echo
    echo "Firewall Blocks (last 24h):"
    if [[ -f /var/log/security/firewall.log ]]; then
        grep "$(date '+%b %d')" /var/log/security/firewall.log | wc -l
    else
        echo "No firewall log found"
    fi
}

auth_analysis() {
    echo "=== Authentication Analysis ==="
    echo "Date: $(date)"
    echo
    
    echo "Top 10 Failed Login Attempts by IP:"
    grep "Failed password" /var/log/auth.log | \
    awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | head -10
    
    echo
    echo "Top 10 Successful Logins by User:"
    grep "Accepted" /var/log/auth.log | \
    awk '{print $9}' | sort | uniq -c | sort -nr | head -10
    
    echo
    echo "Login Times (last 24h):"
    grep "Accepted" /var/log/auth.log | grep "$(date '+%b %d')" | \
    awk '{print $3}' | cut -d: -f1 | sort | uniq -c
}

error_summary() {
    echo "=== Error Log Summary ==="
    echo "Date: $(date)"
    echo
    
    echo "System Errors (last 24h):"
    grep -i "error\|critical\|failed" /var/log/syslog | \
    grep "$(date '+%b %d')" | wc -l
    
    echo
    echo "Top 10 Error Messages:"
    grep -i "error\|critical\|failed" /var/log/syslog | \
    grep "$(date '+%b %d')" | awk -F'] ' '{print $2}' | \
    sort | uniq -c | sort -nr | head -10
}

top_ips() {
    echo "=== Top Source IPs ==="
    echo "Date: $(date)"
    echo
    
    echo "Top 20 IPs in Auth Logs:"
    grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' /var/log/auth.log | \
    sort | uniq -c | sort -nr | head -20
}

user_activity() {
    echo "=== User Activity Summary ==="
    echo "Date: $(date)"
    echo
    
    echo "Unique Users Logged In (last 24h):"
    grep "Accepted" /var/log/auth.log | grep "$(date '+%b %d')" | \
    awk '{print $9}' | sort | uniq
    
    echo
    echo "Sudo Users (last 24h):"
    grep "sudo" /var/log/auth.log | grep "$(date '+%b %d')" | \
    awk '{print $6}' | cut -d: -f1 | sort | uniq
}

# Main execution
case "${1:-}" in
    -s|--security)
        security_summary
        ;;
    -a|--auth)
        auth_analysis
        ;;
    -e|--errors)
        error_summary
        ;;
    -t|--top-ips)
        top_ips
        ;;
    -u|--users)
        user_activity
        ;;
    -h|--help)
        print_usage
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
EOF

    chmod +x /usr/local/bin/log-analysis.sh
    
    print_success "Log analysis tools configured"
}

# Configure firewall for log server
configure_firewall() {
    print_status "Configuring firewall for log aggregation..."
    
    case $OS in
        ubuntu|debian)
            if command -v ufw >/dev/null 2>&1; then
                ufw allow 514/udp comment 'Syslog UDP'
                ufw allow 514/tcp comment 'Syslog TCP'
            fi
            ;;
        centos|rhel|fedora)
            if command -v firewall-cmd >/dev/null 2>&1; then
                firewall-cmd --zone=public --add-port=514/udp --permanent
                firewall-cmd --zone=public --add-port=514/tcp --permanent
                firewall-cmd --reload
            fi
            ;;
    esac
    
    print_success "Firewall configured for log aggregation"
}

# Test log aggregation
test_log_aggregation() {
    print_status "Testing log aggregation..."
    
    # Send test messages
    logger -p auth.info "TEST: Log aggregation test message - authentication"
    logger -p daemon.warning "TEST: Log aggregation test message - daemon warning"
    logger -p kern.error "TEST: Log aggregation test message - kernel error"
    
    sleep 2
    
    # Check if messages were logged
    if grep -q "Log aggregation test message" /var/log/syslog; then
        print_success "Log aggregation test passed"
    else
        print_warning "Log aggregation test failed - check configuration"
    fi
    
    # Test log rotation
    if logrotate -d /etc/logrotate.d/security-logs >/dev/null 2>&1; then
        print_success "Log rotation configuration is valid"
    else
        print_warning "Log rotation configuration has issues"
    fi
}

# Create log aggregation status script
create_status_script() {
    print_status "Creating log aggregation status script..."
    
    cat > /usr/local/bin/log-status.sh << 'EOF'
#!/bin/bash

# Log Aggregation Status Script

echo "=== Log Aggregation Status ==="
echo "Timestamp: $(date)"
echo

# Check rsyslog service
echo "Rsyslog Service Status:"
if systemctl is-active --quiet rsyslog; then
    echo "✓ Rsyslog is running"
    echo "  Listening ports:"
    netstat -tuln | grep :514 || echo "  No syslog ports detected"
else
    echo "✗ Rsyslog is not running"
fi

echo

# Check log directories
echo "Log Directory Status:"
for dir in /var/log/{security,applications,monitoring,remote}; do
    if [[ -d "$dir" ]]; then
        file_count=$(find "$dir" -type f -name "*.log" | wc -l)
        size=$(du -sh "$dir" 2>/dev/null | cut -f1)
        echo "✓ $dir ($file_count files, $size)"
    else
        echo "✗ $dir (missing)"
    fi
done

echo

# Check disk usage
echo "Log Disk Usage:"
df -h /var/log | tail -1 | awk '{print $5 " used (" $4 " available)"}'

echo

# Check recent log activity
echo "Recent Log Activity (last hour):"
find /var/log -name "*.log" -type f -newermt "1 hour ago" -exec basename {} \; | \
sort | uniq -c | sort -nr | head -10

echo

# Check log rotation status
echo "Log Rotation Status:"
if [[ -f /var/lib/logrotate/status ]]; then
    echo "✓ Logrotate status file exists"
    echo "  Last rotation: $(stat -c %y /var/lib/logrotate/status | cut -d. -f1)"
else
    echo "✗ Logrotate status file missing"
fi

echo

# Check monitoring cron job
echo "Log Monitoring Cron Job:"
if [[ -f /etc/cron.d/log-monitor ]]; then
    echo "✓ Log monitoring cron job is configured"
else
    echo "✗ Log monitoring cron job is missing"
fi

echo
echo "=== Log Analysis Tools ==="
echo "Available commands:"
echo "  log-analysis.sh --security    # Security log summary"
echo "  log-analysis.sh --auth        # Authentication analysis"
echo "  log-analysis.sh --errors      # Error log summary"
echo "  log-monitor.sh                # Manual log monitoring check"
EOF

    chmod +x /usr/local/bin/log-status.sh
    print_success "Status script created at /usr/local/bin/log-status.sh"
}

# Main execution
main() {
    print_status "Starting Log Aggregation Setup..."
    print_status "Timestamp: $(date)"
    
    check_root
    detect_os
    
    install_packages
    configure_rsyslog_server
    configure_logrotate
    configure_log_monitoring
    configure_log_analysis
    configure_firewall
    
    # Restart rsyslog to apply changes
    systemctl restart rsyslog
    
    test_log_aggregation
    create_status_script
    
    print_success "Log aggregation setup completed successfully!"
    print_status "Running status check..."
    /usr/local/bin/log-status.sh
    
    echo
    print_status "Log aggregation services:"
    print_status "- Centralized logging: rsyslog listening on port 514 (TCP/UDP)"
    print_status "- Log rotation: configured for $LOG_RETENTION_DAYS days retention"
    print_status "- Log monitoring: automated alerting every 15 minutes"
    print_status "- Log analysis: use 'log-analysis.sh --help' for options"
}

# Run main function
main "$@"
