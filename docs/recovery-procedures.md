# Recovery and Testing Procedures

## Overview

This document outlines the disaster recovery procedures, backup validation, and testing protocols for the Linux Infrastructure Automation Lab.

## Disaster Recovery Procedures

### 1. System Recovery from Backup

#### Prerequisites
- Access to backup storage location
- Bootable Linux rescue media
- Network connectivity (if using remote backups)

#### Recovery Steps

1. **Boot from rescue media**
   ```bash
   # Boot from USB/CD rescue environment
   # Mount target disk
   mkdir /mnt/recovery
   mount /dev/sda1 /mnt/recovery
   ```

2. **Restore system files**
   ```bash
   # Navigate to backup location
   cd /opt/backups/daily
   
   # Find latest backup
   ls -la system_backup_*.tar.gz | tail -1
   
   # Restore system (example)
   tar -xzf system_backup_20240131_120000.tar.gz -C /mnt/recovery/
   ```

3. **Restore bootloader**
   ```bash
   # Mount required filesystems
   mount --bind /dev /mnt/recovery/dev
   mount --bind /proc /mnt/recovery/proc
   mount --bind /sys /mnt/recovery/sys
   
   # Chroot and restore GRUB
   chroot /mnt/recovery
   grub-install /dev/sda
   update-grub
   ```

4. **Verify system integrity**
   ```bash
   # Run file system check
   fsck -f /dev/sda1
   
   # Verify critical services
   systemctl status sshd
   systemctl status prometheus
   systemctl status grafana-server
   ```

### 2. Configuration Recovery

#### SSH Configuration Recovery
```bash
# Restore SSH hardening configuration
cp /opt/backups/configs/sshd_config_hardened /etc/ssh/sshd_config.d/99-hardening.conf
systemctl restart sshd
```

#### Monitoring Recovery
```bash
# Restore Prometheus configuration
systemctl stop prometheus
cp -r /opt/backups/configs/prometheus/* /etc/prometheus/
chown -R prometheus:prometheus /etc/prometheus/
systemctl start prometheus

# Restore Grafana dashboards
cp /opt/backups/configs/grafana/*.json /var/lib/grafana/dashboards/
chown -R grafana:grafana /var/lib/grafana/dashboards/
systemctl restart grafana-server
```

### 3. Database Recovery

#### MySQL Recovery
```bash
# Stop MySQL service
systemctl stop mysql

# Restore from backup
zcat /opt/backups/daily/mysql/database_name_20240131_120000.sql.gz | mysql -u root -p database_name

# Start MySQL service
systemctl start mysql
```

#### PostgreSQL Recovery
```bash
# Stop PostgreSQL service
systemctl stop postgresql

# Restore from backup
sudo -u postgres psql < /opt/backups/daily/postgres/postgres_all_20240131_120000.sql

# Start PostgreSQL service
systemctl start postgresql
```

## Backup Validation Procedures

### 1. Automated Validation

The system includes automated backup validation:

```bash
# Run backup validation script
sudo -u backup /opt/backups/scripts/backup-validation.sh

# Check validation logs
tail -f /opt/backups/logs/validation_*.log
```

### 2. Manual Backup Testing

#### Test Backup Integrity
```bash
# Test tar archive integrity
tar -tzf /opt/backups/daily/system_backup_*.tar.gz > /dev/null

# List backup contents
tar -tzf /opt/backups/daily/system_backup_*.tar.gz | head -20

# Verify specific files
tar -xzf /opt/backups/daily/system_backup_*.tar.gz ./etc/passwd -O
```

#### Test Restore Process
```bash
# Create test restore directory
mkdir /tmp/test_restore

# Extract sample files
tar -xzf /opt/backups/daily/system_backup_*.tar.gz -C /tmp/test_restore ./etc/hosts ./etc/passwd

# Verify extracted files
ls -la /tmp/test_restore/etc/
diff /etc/hosts /tmp/test_restore/etc/hosts

# Cleanup
rm -rf /tmp/test_restore
```

### 3. Database Backup Testing

#### MySQL Backup Test
```bash
# Create test database
mysql -u root -p -e "CREATE DATABASE test_restore;"

# Restore backup to test database
zcat /opt/backups/daily/mysql/original_db_*.sql.gz | mysql -u root -p test_restore

# Verify data
mysql -u root -p test_restore -e "SHOW TABLES;"

# Cleanup
mysql -u root -p -e "DROP DATABASE test_restore;"
```

#### PostgreSQL Backup Test
```bash
# Create test database
sudo -u postgres createdb test_restore

# Restore backup
sudo -u postgres psql test_restore < /opt/backups/daily/postgres/original_db_*.sql

# Verify data
sudo -u postgres psql test_restore -c "\dt"

# Cleanup
sudo -u postgres dropdb test_restore
```

## Testing Protocols

### 1. Security Testing

#### SSH Security Verification
```bash
# Test SSH hardening
ssh -p 2222 user@server

# Verify fail2ban status
fail2ban-client status sshd

# Check firewall rules
ufw status numbered  # Ubuntu
firewall-cmd --list-all  # CentOS/RHEL
```

#### System Hardening Verification
```bash
# Check disabled services
systemctl list-unit-files | grep disabled

# Verify kernel parameters
sysctl -a | grep -E "net.ipv4.ip_forward|kernel.dmesg_restrict"

# Check file permissions
ls -la /etc/shadow /etc/passwd /etc/group
```

### 2. Monitoring Testing

#### Prometheus Testing
```bash
# Check Prometheus targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[].health'

# Test metrics collection
curl -s http://localhost:9100/metrics | grep node_cpu_seconds_total

# Verify alert rules
curl -s http://localhost:9090/api/v1/rules
```

#### Grafana Testing
```bash
# Test Grafana API
curl -s http://admin:admin123@localhost:3000/api/health

# Verify dashboard
curl -s http://admin:admin123@localhost:3000/api/dashboards/home

# Test data source connection
curl -s http://admin:admin123@localhost:3000/api/datasources/proxy/1/api/v1/label/__name__/values
```

### 3. Log Aggregation Testing

#### Rsyslog Testing
```bash
# Send test messages
logger -p auth.info "TEST: Authentication test message"
logger -p daemon.warning "TEST: Daemon warning message"

# Verify log reception
grep "TEST:" /var/log/auth.log
grep "TEST:" /var/log/daemon.log

# Check remote log collection
tail -f /var/log/remote/*/syslog.log
```

#### Log Rotation Testing
```bash
# Force log rotation
logrotate -f /etc/logrotate.d/security-logs

# Verify rotation worked
ls -la /var/log/security/*.log*

# Check compressed logs
zcat /var/log/security/auth.log.1.gz | head -10
```

## Performance Testing

### 1. System Performance
```bash
# CPU stress test
stress-ng --cpu 4 --timeout 60s

# Memory stress test
stress-ng --vm 2 --vm-bytes 1G --timeout 60s

# I/O stress test
stress-ng --io 4 --timeout 60s
```

### 2. Monitoring Performance
```bash
# Check Prometheus query performance
time curl -s "http://localhost:9090/api/v1/query?query=node_cpu_seconds_total"

# Monitor during stress test
watch -n 1 'curl -s "http://localhost:9090/api/v1/query?query=100-avg(irate(node_cpu_seconds_total{mode=\"idle\"}[5m]))*100"'
```

## Maintenance Schedules

### Daily Tasks
- Automated backup execution (2:00 AM)
- Log rotation and cleanup
- Security monitoring alerts
- System health checks

### Weekly Tasks
- Full backup validation
- Security audit review
- Performance metrics analysis
- Disk space monitoring

### Monthly Tasks
- Disaster recovery drill
- Security configuration review
- Backup retention cleanup
- Documentation updates

## Contact Information

### Emergency Contacts
- System Administrator: admin@localhost
- Security Team: security@localhost
- Infrastructure Team: infra@localhost

### Escalation Procedures
1. **Level 1**: System Administrator (0-30 minutes)
2. **Level 2**: Security Team (30-60 minutes)
3. **Level 3**: Infrastructure Team (1-2 hours)
4. **Level 4**: External Support (2+ hours)

## Recovery Time Objectives (RTO)

| Service | RTO | RPO |
|---------|-----|-----|
| SSH Access | 15 minutes | 1 hour |
| Monitoring | 30 minutes | 4 hours |
| Log Aggregation | 45 minutes | 1 hour |
| Full System | 2 hours | 24 hours |

## Appendix

### Common Recovery Commands
```bash
# Service management
systemctl restart service_name
systemctl status service_name
journalctl -u service_name -f

# File system checks
fsck -f /dev/device
mount -o remount,rw /
df -h

# Network troubleshooting
ip addr show
netstat -tuln
ss -tuln

# Log analysis
tail -f /var/log/syslog
grep -i error /var/log/syslog
journalctl -p err -n 50
```

### Recovery Checklists
See separate recovery checklist documents for detailed step-by-step procedures.
