#!/bin/bash

# Linux Infrastructure Hardening Script
# Author: Linux Infrastructure Automation Lab
# Description: Comprehensive security hardening for Ubuntu/CentOS systems
# Date: $(date +%Y-%m-%d)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging setup
LOG_FILE="/var/log/hardening.log"
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

# Update system packages
update_system() {
    print_status "Updating system packages..."
    
    case $OS in
        ubuntu|debian)
            apt-get update && apt-get upgrade -y
            apt-get install -y fail2ban ufw aide rkhunter chkrootkit
            ;;
        centos|rhel|fedora)
            yum update -y
            yum install -y fail2ban firewalld aide rkhunter
            ;;
        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    print_success "System packages updated"
}

# Configure SSH hardening
harden_ssh() {
    print_status "Hardening SSH configuration..."
    
    # Backup original config
    cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%Y%m%d)
    
    # SSH hardening settings
    cat > /etc/ssh/sshd_config.d/99-hardening.conf << 'EOF'
# SSH Hardening Configuration
Protocol 2
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
TCPKeepAlive no
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60
MaxAuthTries 3
MaxSessions 2
AllowUsers sysadmin
DenyUsers root
Banner /etc/issue.net
Compression no
LogLevel VERBOSE
StrictModes yes
IgnoreRhosts yes
RhostsRSAAuthentication no
HostbasedAuthentication no
EOF

    # Create warning banner
    cat > /etc/issue.net << 'EOF'
***********************************************************************
                    AUTHORIZED ACCESS ONLY
                    
This system is for authorized users only. All activities are monitored
and logged. Unauthorized access is strictly prohibited and will be
prosecuted to the full extent of the law.
***********************************************************************
EOF

    # Restart SSH service
    systemctl restart sshd
    print_success "SSH hardening completed"
}

# Configure firewall
configure_firewall() {
    print_status "Configuring firewall..."
    
    case $OS in
        ubuntu|debian)
            # Configure UFW
            ufw --force reset
            ufw default deny incoming
            ufw default allow outgoing
            ufw allow 2222/tcp comment 'SSH'
            ufw allow 80/tcp comment 'HTTP'
            ufw allow 443/tcp comment 'HTTPS'
            ufw allow 9100/tcp comment 'Prometheus Node Exporter'
            ufw --force enable
            ;;
        centos|rhel|fedora)
            # Configure firewalld
            systemctl enable firewalld
            systemctl start firewalld
            firewall-cmd --set-default-zone=drop
            firewall-cmd --zone=public --add-port=2222/tcp --permanent
            firewall-cmd --zone=public --add-port=80/tcp --permanent
            firewall-cmd --zone=public --add-port=443/tcp --permanent
            firewall-cmd --zone=public --add-port=9100/tcp --permanent
            firewall-cmd --reload
            ;;
    esac
    
    print_success "Firewall configured"
}

# Disable unnecessary services
disable_services() {
    print_status "Disabling unnecessary services..."
    
    # List of services to disable
    SERVICES_TO_DISABLE=(
        "avahi-daemon"
        "cups"
        "bluetooth"
        "whoopsie"
        "apport"
        "snapd"
    )
    
    for service in "${SERVICES_TO_DISABLE[@]}"; do
        if systemctl is-enabled "$service" >/dev/null 2>&1; then
            systemctl disable "$service"
            systemctl stop "$service" 2>/dev/null || true
            print_status "Disabled service: $service"
        fi
    done
    
    print_success "Unnecessary services disabled"
}

# Configure system auditing
configure_auditing() {
    print_status "Configuring system auditing..."
    
    # Install auditd if not present
    case $OS in
        ubuntu|debian)
            apt-get install -y auditd audispd-plugins
            ;;
        centos|rhel|fedora)
            yum install -y audit audit-libs
            ;;
    esac
    
    # Configure audit rules
    cat > /etc/audit/rules.d/99-security.rules << 'EOF'
# Security audit rules
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k privilege_escalation
-w /var/log/auth.log -p wa -k authentication
-w /var/log/secure -p wa -k authentication
-w /bin/su -p x -k privilege_escalation
-w /usr/bin/sudo -p x -k privilege_escalation
-w /etc/ssh/sshd_config -p wa -k ssh_config
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time-change
-a always,exit -F arch=b32 -S adjtimex -S settimeofday -S stime -k time-change
-a always,exit -F arch=b64 -S clock_settime -k time-change
-a always,exit -F arch=b32 -S clock_settime -k time-change
EOF
    
    # Enable and start auditd
    systemctl enable auditd
    systemctl restart auditd
    
    print_success "System auditing configured"
}

# Configure file integrity monitoring
configure_aide() {
    print_status "Configuring AIDE (File Integrity Monitoring)..."
    
    # Initialize AIDE database
    case $OS in
        ubuntu|debian)
            aideinit
            mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db
            ;;
        centos|rhel|fedora)
            aide --init
            mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
            ;;
    esac
    
    # Create daily AIDE check cron job
    cat > /etc/cron.daily/aide-check << 'EOF'
#!/bin/bash
# Daily AIDE integrity check

AIDE_LOG="/var/log/aide.log"
DATE=$(date)

echo "AIDE Check - $DATE" >> $AIDE_LOG

case $(lsb_release -si) in
    Ubuntu|Debian)
        aide --check >> $AIDE_LOG 2>&1
        ;;
    CentOS|RedHat|Fedora)
        aide --check >> $AIDE_LOG 2>&1
        ;;
esac

# Email results if changes detected
if [ $? -ne 0 ]; then
    echo "AIDE detected file system changes on $(hostname) at $DATE" | \
    mail -s "AIDE Alert - $(hostname)" root@localhost
fi
EOF
    
    chmod +x /etc/cron.daily/aide-check
    print_success "AIDE configured"
}

# Configure fail2ban
configure_fail2ban() {
    print_status "Configuring Fail2Ban..."
    
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = 2222
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

[apache-auth]
enabled = false

[apache-badbots]
enabled = false

[apache-noscript]
enabled = false

[apache-overflows]
enabled = false
EOF
    
    systemctl enable fail2ban
    systemctl restart fail2ban
    
    print_success "Fail2Ban configured"
}

# Set kernel parameters for security
configure_kernel_parameters() {
    print_status "Configuring kernel security parameters..."
    
    cat > /etc/sysctl.d/99-security.conf << 'EOF'
# Network security parameters
net.ipv4.ip_forward = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# IPv6 security
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Kernel security
kernel.dmesg_restrict = 1
kernel.kptr_restrict = 2
kernel.yama.ptrace_scope = 1
kernel.core_uses_pid = 1
fs.suid_dumpable = 0
EOF
    
    sysctl -p /etc/sysctl.d/99-security.conf
    print_success "Kernel security parameters configured"
}

# Main execution
main() {
    print_status "Starting Linux Infrastructure Hardening..."
    print_status "Timestamp: $(date)"
    
    check_root
    detect_os
    
    update_system
    harden_ssh
    configure_firewall
    disable_services
    configure_auditing
    configure_aide
    configure_fail2ban
    configure_kernel_parameters
    
    print_success "Hardening completed successfully!"
    print_status "Please reboot the system to ensure all changes take effect."
    print_status "SSH port changed to 2222. Update your connection settings."
    print_status "Log file: $LOG_FILE"
}

# Run main function
main "$@"
