# Installation and Usage Guide

## Prerequisites

### System Requirements
- **Operating System**: Ubuntu 20.04+ or CentOS 8+ / RHEL 8+
- **RAM**: Minimum 4GB (8GB recommended)
- **Storage**: 50GB available disk space
- **CPU**: 2 cores minimum (4 cores recommended)
- **Network**: Internet connectivity for package downloads

### Required Privileges
- Root access or sudo privileges
- SSH access to the target system

## Quick Start Installation

### 1. Clone the Repository
```bash
git clone https://github.com/letisiapangataa/linux-infra-automation-lab.git
cd linux-infra-automation-lab
```

### 2. Run the Complete Setup
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run all setup scripts in order
sudo ./scripts/hardening.sh
sudo ./scripts/monitoring-setup.sh
sudo ./scripts/log-aggregation.sh
sudo ./scripts/backup-automation.sh
```

### 3. Verify Installation
```bash
# Check all services
sudo systemctl status sshd prometheus node_exporter grafana-server rsyslog

# Run status checks
sudo /usr/local/bin/check-monitoring.sh
sudo /usr/local/bin/log-status.sh
sudo -u backup /opt/backups/scripts/backup-status.sh
```

## Detailed Installation Steps

### Step 1: System Hardening

The hardening script configures essential security settings:

```bash
sudo ./scripts/hardening.sh
```

**What it does:**
- Hardens SSH configuration (port 2222, key-only auth)
- Configures firewall rules
- Disables unnecessary services
- Sets up system auditing with auditd
- Configures AIDE for file integrity monitoring
- Installs and configures Fail2Ban
- Applies kernel security parameters

**Post-installation:**
- SSH port changes to 2222
- Password authentication disabled
- Root login disabled

### Step 2: Monitoring Setup

The monitoring script installs Prometheus, Node Exporter, and Grafana:

```bash
sudo ./scripts/monitoring-setup.sh
```

**What it does:**
- Installs Prometheus 2.45.0
- Installs Node Exporter 1.6.1
- Installs Grafana with custom dashboards
- Configures alerting rules
- Sets up monitoring users and permissions

**Access URLs:**
- Prometheus: http://server-ip:9090
- Grafana: http://server-ip:3000 (admin/admin123)
- Node Exporter: http://server-ip:9100/metrics

### Step 3: Log Aggregation

The log aggregation script configures centralized logging:

```bash
sudo ./scripts/log-aggregation.sh
```

**What it does:**
- Configures rsyslog for centralized logging
- Sets up log rotation policies
- Creates log monitoring and alerting
- Configures log analysis tools
- Sets up automated log cleanup

**Key Features:**
- Centralized log collection on port 514
- Automated log rotation (30-day retention)
- Security event monitoring
- Log integrity validation

### Step 4: Backup Automation

The backup script creates a comprehensive backup solution:

```bash
sudo ./scripts/backup-automation.sh
```

**What it does:**
- Creates backup user and directory structure
- Configures automated daily/weekly/monthly backups
- Sets up database backup scripts
- Creates restore and validation tools
- Schedules backup jobs with cron

**Backup Schedule:**
- Daily: 2:00 AM (system files and configs)
- Weekly: Sunday 3:00 AM (full system backup)
- Monthly: 1st day 4:00 AM (archive backup)

## Configuration Customization

### SSH Configuration
Edit the SSH hardening settings in `configs/sshd_config_hardened`:

```bash
# Change SSH port (default: 2222)
Port 2222

# Add allowed users
AllowUsers sysadmin john jane

# Configure key algorithms
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512
```

### Monitoring Configuration
Customize Prometheus settings in `/etc/prometheus/prometheus.yml`:

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'custom_app'
    static_configs:
      - targets: ['localhost:8080']
```

### Backup Configuration
Modify backup settings in `/opt/backups/configs/backup.conf`:

```bash
# Backup retention (days)
BACKUP_RETENTION_DAYS="30"

# Compression level (1-9)
COMPRESSION_LEVEL="6"

# Email notifications
NOTIFICATION_EMAIL="admin@company.com"

# Additional directories to backup
SYSTEM_DIRS=(
    "/etc"
    "/var/www"
    "/opt/myapp"
)
```

## User Management

### Creating Admin Users
```bash
# Create a new admin user
sudo useradd -m -s /bin/bash newadmin

# Add to sudo group
sudo usermod -aG sudo newadmin

# Set up SSH key authentication
sudo mkdir -p /home/newadmin/.ssh
sudo cp /root/.ssh/authorized_keys /home/newadmin/.ssh/
sudo chown -R newadmin:newadmin /home/newadmin/.ssh
sudo chmod 700 /home/newadmin/.ssh
sudo chmod 600 /home/newadmin/.ssh/authorized_keys

# Add user to SSH allowed users
sudo sed -i 's/AllowUsers sysadmin/AllowUsers sysadmin newadmin/' /etc/ssh/sshd_config.d/99-hardening.conf
sudo systemctl restart sshd
```

### Managing Service Users
```bash
# Check monitoring users
id prometheus
id grafana

# Check backup user
id backup

# View user permissions
sudo -u backup ls -la /opt/backups/
sudo -u prometheus ls -la /etc/prometheus/
```

## Daily Operations

### Monitoring System Health
```bash
# Check all service status
sudo systemctl status sshd prometheus node_exporter grafana-server rsyslog

# View system metrics
curl -s http://localhost:9090/api/v1/query?query=node_load1

# Check monitoring health
sudo /usr/local/bin/check-monitoring.sh
```

### Log Management
```bash
# View security logs
sudo tail -f /var/log/security/auth-failures.log

# Check log aggregation status
sudo /usr/local/bin/log-status.sh

# Run log analysis
sudo /usr/local/bin/log-analysis.sh --security
```

### Backup Operations
```bash
# Check backup status
sudo -u backup /opt/backups/scripts/backup-status.sh

# Run manual backup
sudo -u backup /opt/backups/scripts/system-backup.sh daily

# Validate backups
sudo -u backup /opt/backups/scripts/backup-validation.sh

# List backup contents
sudo -u backup /opt/backups/scripts/system-restore.sh -l /opt/backups/daily/system_backup_*.tar.gz
```

## Troubleshooting

### Common Issues

#### SSH Connection Issues
```bash
# Check SSH service status
sudo systemctl status sshd

# Verify SSH configuration
sudo sshd -T | grep -E "port|permitrootlogin|passwordauthentication"

# Check firewall rules
sudo ufw status numbered  # Ubuntu
sudo firewall-cmd --list-all  # CentOS

# Test SSH connection
ssh -p 2222 -v user@localhost
```

#### Monitoring Issues
```bash
# Check Prometheus status
sudo systemctl status prometheus
curl -s http://localhost:9090/-/ready

# Check Node Exporter
sudo systemctl status node_exporter
curl -s http://localhost:9100/metrics | head

# Check Grafana
sudo systemctl status grafana-server
curl -s http://localhost:3000/api/health

# View service logs
sudo journalctl -u prometheus -f
sudo journalctl -u grafana-server -f
```

#### Log Aggregation Issues
```bash
# Check rsyslog status
sudo systemctl status rsyslog

# Test log generation
logger "TEST: Log aggregation test"
sudo grep "TEST:" /var/log/syslog

# Check log rotation
sudo logrotate -d /etc/logrotate.d/security-logs

# Verify log permissions
ls -la /var/log/security/
```

#### Backup Issues
```bash
# Check backup user permissions
sudo ls -la /opt/backups/

# Check cron jobs
sudo -u backup crontab -l

# Test backup creation
sudo -u backup /opt/backups/scripts/system-backup.sh daily

# Check backup logs
sudo tail -f /opt/backups/logs/backup_*.log
```

### Log File Locations

| Service | Log Location |
|---------|-------------|
| SSH | `/var/log/auth.log` |
| Prometheus | `journalctl -u prometheus` |
| Grafana | `/var/log/grafana/grafana.log` |
| rsyslog | `/var/log/syslog` |
| Backups | `/opt/backups/logs/` |
| Security Events | `/var/log/security/` |
| System Hardening | `/var/log/hardening.log` |

### Performance Tuning

#### Monitoring Performance
```bash
# Increase Prometheus retention
sudo sed -i 's/--storage.tsdb.retention.time=30d/--storage.tsdb.retention.time=90d/' /etc/systemd/system/prometheus.service
sudo systemctl daemon-reload
sudo systemctl restart prometheus

# Optimize Grafana performance
sudo sed -i 's/;max_concurrent_queries = 20/max_concurrent_queries = 50/' /etc/grafana/grafana.ini
sudo systemctl restart grafana-server
```

#### Backup Performance
```bash
# Increase compression for smaller backups
sudo sed -i 's/COMPRESSION_LEVEL="6"/COMPRESSION_LEVEL="9"/' /opt/backups/configs/backup.conf

# Use faster compression for quicker backups
sudo sed -i 's/pigz -$COMPRESSION_LEVEL/pigz -1/' /opt/backups/scripts/system-backup.sh
```

## Security Maintenance

### Regular Security Tasks

#### Weekly Security Review
```bash
# Check failed login attempts
sudo grep "Failed password" /var/log/auth.log | wc -l

# Review Fail2Ban status
sudo fail2ban-client status
sudo fail2ban-client status sshd

# Check for unauthorized changes
sudo aide --check

# Review firewall logs
sudo grep "UFW" /var/log/syslog | tail -20
```

#### Monthly Security Audit
```bash
# Update AIDE database
sudo aide --update
sudo mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Review user accounts
sudo grep -E "^[^:]+:[^!*]" /etc/shadow

# Check for SUID/SGID files
sudo find / -perm -4000 -o -perm -2000 2>/dev/null

# Audit system packages
sudo apt list --upgradable  # Ubuntu
sudo yum check-update  # CentOS
```

## Advanced Configuration

### Adding Custom Monitoring Targets
```bash
# Edit Prometheus configuration
sudo vim /etc/prometheus/prometheus.yml

# Add new scrape target
scrape_configs:
  - job_name: 'custom_application'
    static_configs:
      - targets: ['localhost:8080']
    scrape_interval: 30s

# Restart Prometheus
sudo systemctl restart prometheus
```

### Custom Log Parsing
```bash
# Add custom log patterns to rsyslog
sudo vim /etc/rsyslog.d/10-custom.conf

# Example: Parse application logs
:programname,isequal,"myapp" /var/log/applications/myapp.log

# Restart rsyslog
sudo systemctl restart rsyslog
```

### Backup Exclusions
```bash
# Edit backup configuration
sudo vim /opt/backups/configs/backup.conf

# Add exclusion patterns
EXCLUDE_PATTERNS=(
    "/tmp/*"
    "/var/cache/*"
    "/home/user/downloads/*"
    "*.iso"
    "*.log"
)
```

## Integration with External Systems

### SIEM Integration
```bash
# Configure rsyslog to forward to SIEM
echo "*.* @@siem-server:514" | sudo tee -a /etc/rsyslog.d/99-siem.conf
sudo systemctl restart rsyslog
```

### Cloud Backup Integration
```bash
# Configure remote backup sync
sudo vim /opt/backups/configs/backup.conf

# Enable remote backup
REMOTE_BACKUP_ENABLED="true"
REMOTE_HOST="backup-server.company.com"
REMOTE_USER="backup"
REMOTE_PATH="/data/backups/"
```

## Support and Maintenance

### Getting Help
- Review log files in `/var/log/` for error messages
- Check service status with `systemctl status <service>`
- Use `journalctl -u <service> -f` for real-time service logs
- Run built-in status scripts for health checks

### Regular Maintenance Schedule
- **Daily**: Review monitoring dashboards and alerts
- **Weekly**: Check backup status and log analysis
- **Monthly**: Security audit and system updates
- **Quarterly**: Disaster recovery testing

For additional support, refer to the documentation in the `docs/` directory or check the individual script help options.
