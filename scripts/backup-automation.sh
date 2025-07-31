#!/bin/bash

# Backup Automation Script
# Author: Linux Infrastructure Automation Lab
# Description: Automated backup solution with validation and restore capabilities
# Date: $(date +%Y-%m-%d)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration variables
BACKUP_BASE_DIR="/opt/backups"
BACKUP_RETENTION_DAYS="30"
BACKUP_USER="backup"
NOTIFICATION_EMAIL="admin@localhost"
COMPRESSION_LEVEL="6"

# Logging setup
LOG_FILE="/var/log/backup-automation.log"
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
    print_status "Installing backup packages..."
    
    case $OS in
        ubuntu|debian)
            apt-get update
            apt-get install -y rsync tar gzip bzip2 xz-utils pv pigz mailutils cron
            ;;
        centos|rhel|fedora)
            yum update -y
            yum install -y rsync tar gzip bzip2 xz pv pigz mailx cronie
            systemctl enable crond
            systemctl start crond
            ;;
        *)
            print_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
    
    print_success "Backup packages installed"
}

# Create backup user and directories
setup_backup_environment() {
    print_status "Setting up backup environment..."
    
    # Create backup user
    if ! id "$BACKUP_USER" &>/dev/null; then
        useradd --system --shell /bin/bash --home-dir "$BACKUP_BASE_DIR" --create-home "$BACKUP_USER"
        print_status "Created backup user: $BACKUP_USER"
    fi
    
    # Create backup directory structure
    mkdir -p "$BACKUP_BASE_DIR"/{daily,weekly,monthly,configs,scripts,logs,temp}
    mkdir -p "$BACKUP_BASE_DIR"/restore/{system,configs,databases,files}
    
    # Set permissions
    chown -R "$BACKUP_USER":"$BACKUP_USER" "$BACKUP_BASE_DIR"
    chmod -R 750 "$BACKUP_BASE_DIR"
    
    print_success "Backup environment configured"
}

# Create backup configuration
create_backup_config() {
    print_status "Creating backup configuration..."
    
    cat > "$BACKUP_BASE_DIR/configs/backup.conf" << EOF
# Backup Configuration File
# Generated on $(date)

# Backup settings
BACKUP_BASE_DIR="$BACKUP_BASE_DIR"
BACKUP_RETENTION_DAYS="$BACKUP_RETENTION_DAYS"
COMPRESSION_LEVEL="$COMPRESSION_LEVEL"
NOTIFICATION_EMAIL="$NOTIFICATION_EMAIL"

# Directories to backup
SYSTEM_DIRS=(
    "/etc"
    "/var/log"
    "/var/spool/cron"
    "/root"
    "/home"
    "/opt"
    "/usr/local/bin"
    "/usr/local/sbin"
)

# Directories to exclude
EXCLUDE_PATTERNS=(
    "/tmp/*"
    "/var/tmp/*"
    "/var/cache/*"
    "/var/log/journal/*"
    "/proc/*"
    "/sys/*"
    "/dev/*"
    "/run/*"
    "/mnt/*"
    "/media/*"
    "*.sock"
    "*.lock"
    "*.tmp"
    "*~"
)

# Database backup settings
MYSQL_BACKUP_ENABLED="false"
MYSQL_USER="backup"
MYSQL_PASSWORD=""

POSTGRES_BACKUP_ENABLED="false"
POSTGRES_USER="postgres"

# Remote backup settings
REMOTE_BACKUP_ENABLED="false"
REMOTE_HOST=""
REMOTE_USER=""
REMOTE_PATH=""
EOF

    chown "$BACKUP_USER":"$BACKUP_USER" "$BACKUP_BASE_DIR/configs/backup.conf"
    print_success "Backup configuration created"
}

# Create system backup script
create_system_backup_script() {
    print_status "Creating system backup script..."
    
    cat > "$BACKUP_BASE_DIR/scripts/system-backup.sh" << 'EOF'
#!/bin/bash

# System Backup Script
# Performs full system backup with compression and validation

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../configs/backup.conf"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Backup metadata
BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_TYPE="${1:-daily}"
BACKUP_DIR="$BACKUP_BASE_DIR/$BACKUP_TYPE"
BACKUP_NAME="system_backup_${BACKUP_DATE}.tar.gz"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_NAME"
LOG_FILE="$BACKUP_BASE_DIR/logs/backup_${BACKUP_DATE}.log"

# Logging functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE" >&2
}

# Create exclude file
create_exclude_file() {
    local exclude_file="$BACKUP_BASE_DIR/temp/exclude_${BACKUP_DATE}.txt"
    
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        echo "$pattern" >> "$exclude_file"
    done
    
    # Add backup directory itself to exclusions
    echo "$BACKUP_BASE_DIR/*" >> "$exclude_file"
    
    echo "$exclude_file"
}

# Validate backup integrity
validate_backup() {
    local backup_file="$1"
    
    log "Validating backup integrity..."
    
    if tar -tzf "$backup_file" >/dev/null 2>&1; then
        log "Backup validation successful"
        return 0
    else
        log_error "Backup validation failed"
        return 1
    fi
}

# Calculate backup statistics
calculate_stats() {
    local backup_file="$1"
    local start_time="$2"
    local end_time="$3"
    
    local file_size=$(du -h "$backup_file" | cut -f1)
    local duration=$((end_time - start_time))
    local file_count=$(tar -tzf "$backup_file" | wc -l)
    
    cat > "$BACKUP_BASE_DIR/logs/stats_${BACKUP_DATE}.txt" << EOL
Backup Statistics
================
Date: $(date)
Type: $BACKUP_TYPE
File: $BACKUP_NAME
Size: $file_size
Duration: ${duration}s
Files: $file_count
EOL

    log "Backup completed - Size: $file_size, Duration: ${duration}s, Files: $file_count"
}

# Send notification
send_notification() {
    local status="$1"
    local message="$2"
    
    if command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "Backup $status - $(hostname)" "$NOTIFICATION_EMAIL"
    fi
    
    logger "BACKUP $status: $message"
}

# Main backup function
perform_backup() {
    log "Starting $BACKUP_TYPE backup..."
    
    # Ensure backup directory exists
    mkdir -p "$BACKUP_DIR"
    
    # Create exclude file
    local exclude_file
    exclude_file=$(create_exclude_file)
    
    # Start backup
    local start_time=$(date +%s)
    
    log "Creating backup archive: $BACKUP_NAME"
    
    if tar --use-compress-program="pigz -$COMPRESSION_LEVEL" \
           --exclude-from="$exclude_file" \
           --create \
           --file="$BACKUP_PATH" \
           --verbose \
           "${SYSTEM_DIRS[@]}" >> "$LOG_FILE" 2>&1; then
        
        local end_time=$(date +%s)
        
        # Validate backup
        if validate_backup "$BACKUP_PATH"; then
            calculate_stats "$BACKUP_PATH" "$start_time" "$end_time"
            send_notification "SUCCESS" "System backup completed successfully"
            
            # Clean up old backups
            cleanup_old_backups
            
            log "Backup process completed successfully"
            return 0
        else
            log_error "Backup validation failed, removing corrupt backup"
            rm -f "$BACKUP_PATH"
            send_notification "FAILED" "Backup validation failed"
            return 1
        fi
    else
        log_error "Backup creation failed"
        send_notification "FAILED" "Backup creation failed"
        return 1
    fi
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up old backups (retention: $BACKUP_RETENTION_DAYS days)..."
    
    find "$BACKUP_DIR" -name "system_backup_*.tar.gz" -type f -mtime +$BACKUP_RETENTION_DAYS -delete
    find "$BACKUP_BASE_DIR/logs" -name "backup_*.log" -type f -mtime +$BACKUP_RETENTION_DAYS -delete
    find "$BACKUP_BASE_DIR/logs" -name "stats_*.txt" -type f -mtime +$BACKUP_RETENTION_DAYS -delete
    
    log "Old backup cleanup completed"
}

# Main execution
main() {
    log "=== System Backup Started ==="
    
    if perform_backup; then
        log "=== System Backup Completed Successfully ==="
        exit 0
    else
        log "=== System Backup Failed ==="
        exit 1
    fi
}

# Run main function
main "$@"
EOF

    chmod +x "$BACKUP_BASE_DIR/scripts/system-backup.sh"
    chown "$BACKUP_USER":"$BACKUP_USER" "$BACKUP_BASE_DIR/scripts/system-backup.sh"
    
    print_success "System backup script created"
}

# Create database backup scripts
create_database_backup_scripts() {
    print_status "Creating database backup scripts..."
    
    # MySQL backup script
    cat > "$BACKUP_BASE_DIR/scripts/mysql-backup.sh" << 'EOF'
#!/bin/bash

# MySQL Backup Script

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../configs/backup.conf"
source "$CONFIG_FILE"

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
MYSQL_BACKUP_DIR="$BACKUP_BASE_DIR/daily/mysql"
LOG_FILE="$BACKUP_BASE_DIR/logs/mysql_backup_${BACKUP_DATE}.log"

# Create backup directory
mkdir -p "$MYSQL_BACKUP_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [[ "$MYSQL_BACKUP_ENABLED" == "true" ]]; then
    log "Starting MySQL backup..."
    
    # Get list of databases
    DATABASES=$(mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" -e "SHOW DATABASES;" | grep -Ev "Database|information_schema|mysql|performance_schema|sys")
    
    for db in $DATABASES; do
        log "Backing up database: $db"
        mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" \
                  --routines --triggers --single-transaction \
                  "$db" | gzip > "$MYSQL_BACKUP_DIR/${db}_${BACKUP_DATE}.sql.gz"
    done
    
    log "MySQL backup completed"
else
    log "MySQL backup is disabled"
fi
EOF

    # PostgreSQL backup script
    cat > "$BACKUP_BASE_DIR/scripts/postgres-backup.sh" << 'EOF'
#!/bin/bash

# PostgreSQL Backup Script

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../configs/backup.conf"
source "$CONFIG_FILE"

BACKUP_DATE=$(date +%Y%m%d_%H%M%S)
POSTGRES_BACKUP_DIR="$BACKUP_BASE_DIR/daily/postgres"
LOG_FILE="$BACKUP_BASE_DIR/logs/postgres_backup_${BACKUP_DATE}.log"

# Create backup directory
mkdir -p "$POSTGRES_BACKUP_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

if [[ "$POSTGRES_BACKUP_ENABLED" == "true" ]]; then
    log "Starting PostgreSQL backup..."
    
    # Backup all databases
    sudo -u "$POSTGRES_USER" pg_dumpall | gzip > "$POSTGRES_BACKUP_DIR/postgres_all_${BACKUP_DATE}.sql.gz"
    
    # Get list of individual databases
    DATABASES=$(sudo -u "$POSTGRES_USER" psql -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")
    
    for db in $DATABASES; do
        db=$(echo "$db" | tr -d ' ')
        if [[ -n "$db" ]]; then
            log "Backing up database: $db"
            sudo -u "$POSTGRES_USER" pg_dump "$db" | gzip > "$POSTGRES_BACKUP_DIR/${db}_${BACKUP_DATE}.sql.gz"
        fi
    done
    
    log "PostgreSQL backup completed"
else
    log "PostgreSQL backup is disabled"
fi
EOF

    chmod +x "$BACKUP_BASE_DIR/scripts/mysql-backup.sh"
    chmod +x "$BACKUP_BASE_DIR/scripts/postgres-backup.sh"
    chown "$BACKUP_USER":"$BACKUP_USER" "$BACKUP_BASE_DIR/scripts/"*.sh
    
    print_success "Database backup scripts created"
}

# Create restore scripts
create_restore_scripts() {
    print_status "Creating restore scripts..."
    
    # System restore script
    cat > "$BACKUP_BASE_DIR/scripts/system-restore.sh" << 'EOF'
#!/bin/bash

# System Restore Script

set -euo pipefail

# Source configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../configs/backup.conf"
source "$CONFIG_FILE"

print_usage() {
    echo "Usage: $0 [OPTIONS] BACKUP_FILE"
    echo "Options:"
    echo "  -d, --destination DIR    Restore to specific directory (default: /)"
    echo "  -l, --list              List contents of backup file"
    echo "  -t, --test              Test restore (dry run)"
    echo "  -h, --help              Show this help message"
    echo
    echo "Examples:"
    echo "  $0 -l /opt/backups/daily/system_backup_20240131_120000.tar.gz"
    echo "  $0 -t /opt/backups/daily/system_backup_20240131_120000.tar.gz"
    echo "  $0 /opt/backups/daily/system_backup_20240131_120000.tar.gz"
}

list_backup_contents() {
    local backup_file="$1"
    echo "Listing contents of: $backup_file"
    tar -tzf "$backup_file" | head -50
    echo "..."
    echo "Total files: $(tar -tzf "$backup_file" | wc -l)"
}

test_restore() {
    local backup_file="$1"
    local destination="$2"
    
    echo "Testing restore from: $backup_file"
    echo "Destination: $destination"
    
    # Create temporary directory for test
    local test_dir="/tmp/restore_test_$$"
    mkdir -p "$test_dir"
    
    echo "Extracting to test directory: $test_dir"
    if tar -xzf "$backup_file" -C "$test_dir"; then
        echo "Test restore successful"
        echo "Test files extracted to: $test_dir"
        ls -la "$test_dir"
        rm -rf "$test_dir"
        return 0
    else
        echo "Test restore failed"
        rm -rf "$test_dir"
        return 1
    fi
}

perform_restore() {
    local backup_file="$1"
    local destination="$2"
    
    echo "WARNING: This will overwrite existing files!"
    echo "Backup file: $backup_file"
    echo "Destination: $destination"
    echo
    read -p "Are you sure you want to continue? (yes/no): " confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        echo "Restore cancelled"
        return 1
    fi
    
    echo "Starting restore..."
    if tar -xzf "$backup_file" -C "$destination" --overwrite; then
        echo "Restore completed successfully"
        return 0
    else
        echo "Restore failed"
        return 1
    fi
}

# Parse command line options
DESTINATION="/"
LIST_ONLY=false
TEST_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--destination)
            DESTINATION="$2"
            shift 2
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -t|--test)
            TEST_ONLY=true
            shift
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
        *)
            BACKUP_FILE="$1"
            shift
            ;;
    esac
done

# Validate backup file
if [[ -z "${BACKUP_FILE:-}" ]]; then
    echo "Error: Backup file not specified"
    print_usage
    exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "Error: Backup file does not exist: $BACKUP_FILE"
    exit 1
fi

# Execute requested action
if [[ "$LIST_ONLY" == true ]]; then
    list_backup_contents "$BACKUP_FILE"
elif [[ "$TEST_ONLY" == true ]]; then
    test_restore "$BACKUP_FILE" "$DESTINATION"
else
    perform_restore "$BACKUP_FILE" "$DESTINATION"
fi
EOF

    chmod +x "$BACKUP_BASE_DIR/scripts/system-restore.sh"
    chown "$BACKUP_USER":"$BACKUP_USER" "$BACKUP_BASE_DIR/scripts/system-restore.sh"
    
    print_success "Restore scripts created"
}

# Create backup monitoring and status scripts
create_monitoring_scripts() {
    print_status "Creating backup monitoring scripts..."
    
    # Backup status script
    cat > "$BACKUP_BASE_DIR/scripts/backup-status.sh" << 'EOF'
#!/bin/bash

# Backup Status Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../configs/backup.conf"
source "$CONFIG_FILE"

echo "=== Backup Status Report ==="
echo "Generated: $(date)"
echo

# Check backup directories
echo "Backup Directory Status:"
for backup_type in daily weekly monthly; do
    backup_dir="$BACKUP_BASE_DIR/$backup_type"
    if [[ -d "$backup_dir" ]]; then
        file_count=$(find "$backup_dir" -name "*.tar.gz" -type f | wc -l)
        total_size=$(du -sh "$backup_dir" 2>/dev/null | cut -f1)
        latest_backup=$(find "$backup_dir" -name "*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
        
        echo "  $backup_type: $file_count files, $total_size"
        if [[ -n "$latest_backup" ]]; then
            latest_date=$(stat -c %y "$latest_backup" | cut -d. -f1)
            echo "    Latest: $(basename "$latest_backup") ($latest_date)"
        fi
    else
        echo "  $backup_type: Directory not found"
    fi
done

echo

# Check recent backup logs
echo "Recent Backup Activity:"
if [[ -d "$BACKUP_BASE_DIR/logs" ]]; then
    find "$BACKUP_BASE_DIR/logs" -name "backup_*.log" -type f -mtime -7 | \
    while read -r log_file; do
        if grep -q "SUCCESS" "$log_file"; then
            status="SUCCESS"
        elif grep -q "FAILED" "$log_file"; then
            status="FAILED"
        else
            status="UNKNOWN"
        fi
        log_date=$(basename "$log_file" | sed 's/backup_\(.*\)\.log/\1/')
        echo "  $log_date: $status"
    done
else
    echo "  No backup logs found"
fi

echo

# Check disk usage
echo "Backup Storage Usage:"
df -h "$BACKUP_BASE_DIR" | tail -1 | awk '{print "  Used: " $3 " / " $2 " (" $5 ")"}'

echo

# Check cron jobs
echo "Scheduled Backup Jobs:"
if crontab -l 2>/dev/null | grep -q backup; then
    crontab -l | grep backup | while read -r job; do
        echo "  $job"
    done
else
    echo "  No backup cron jobs found"
fi
EOF

    chmod +x "$BACKUP_BASE_DIR/scripts/backup-status.sh"
    chown "$BACKUP_USER":"$BACKUP_USER" "$BACKUP_BASE_DIR/scripts/backup-status.sh"
    
    print_success "Monitoring scripts created"
}

# Setup cron jobs
setup_cron_jobs() {
    print_status "Setting up backup cron jobs..."
    
    # Create cron jobs for backup user
    cat > /tmp/backup-cron << EOF
# Backup Automation Cron Jobs
# Daily backup at 2:00 AM
0 2 * * * $BACKUP_BASE_DIR/scripts/system-backup.sh daily

# Weekly backup on Sunday at 3:00 AM
0 3 * * 0 $BACKUP_BASE_DIR/scripts/system-backup.sh weekly

# Monthly backup on 1st day at 4:00 AM
0 4 1 * * $BACKUP_BASE_DIR/scripts/system-backup.sh monthly

# Database backups at 1:30 AM daily
30 1 * * * $BACKUP_BASE_DIR/scripts/mysql-backup.sh
35 1 * * * $BACKUP_BASE_DIR/scripts/postgres-backup.sh

# Backup status report daily at 6:00 AM
0 6 * * * $BACKUP_BASE_DIR/scripts/backup-status.sh | mail -s "Daily Backup Report - \$(hostname)" $NOTIFICATION_EMAIL
EOF

    # Install cron jobs for backup user
    sudo -u "$BACKUP_USER" crontab /tmp/backup-cron
    rm /tmp/backup-cron
    
    print_success "Backup cron jobs configured"
}

# Create validation and test scripts
create_validation_scripts() {
    print_status "Creating backup validation scripts..."
    
    cat > "$BACKUP_BASE_DIR/scripts/backup-validation.sh" << 'EOF'
#!/bin/bash

# Backup Validation Script
# Validates backup integrity and performs test restores

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/../configs/backup.conf"
source "$CONFIG_FILE"

LOG_FILE="$BACKUP_BASE_DIR/logs/validation_$(date +%Y%m%d).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

validate_all_backups() {
    log "Starting backup validation process..."
    
    local validation_errors=0
    
    for backup_type in daily weekly monthly; do
        backup_dir="$BACKUP_BASE_DIR/$backup_type"
        
        if [[ -d "$backup_dir" ]]; then
            log "Validating $backup_type backups..."
            
            find "$backup_dir" -name "*.tar.gz" -type f | while read -r backup_file; do
                log "Checking: $(basename "$backup_file")"
                
                if tar -tzf "$backup_file" >/dev/null 2>&1; then
                    log "✓ Valid: $(basename "$backup_file")"
                else
                    log "✗ Invalid: $(basename "$backup_file")"
                    ((validation_errors++))
                fi
            done
        fi
    done
    
    if [[ $validation_errors -eq 0 ]]; then
        log "All backups passed validation"
        return 0
    else
        log "Found $validation_errors invalid backups"
        return 1
    fi
}

perform_test_restore() {
    log "Performing test restore..."
    
    # Find most recent daily backup
    latest_backup=$(find "$BACKUP_BASE_DIR/daily" -name "*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [[ -n "$latest_backup" ]]; then
        log "Testing restore of: $(basename "$latest_backup")"
        
        # Create temporary test directory
        test_dir="/tmp/backup_test_$$"
        mkdir -p "$test_dir"
        
        # Extract a small portion for testing
        if tar -xzf "$latest_backup" -C "$test_dir" "./etc/hostname" 2>/dev/null; then
            log "✓ Test restore successful"
            rm -rf "$test_dir"
            return 0
        else
            log "✗ Test restore failed"
            rm -rf "$test_dir"
            return 1
        fi
    else
        log "No backup found for testing"
        return 1
    fi
}

# Main execution
main() {
    log "=== Backup Validation Started ==="
    
    if validate_all_backups && perform_test_restore; then
        log "=== Backup Validation Completed Successfully ==="
        exit 0
    else
        log "=== Backup Validation Failed ==="
        exit 1
    fi
}

main "$@"
EOF

    chmod +x "$BACKUP_BASE_DIR/scripts/backup-validation.sh"
    chown "$BACKUP_USER":"$BACKUP_USER" "$BACKUP_BASE_DIR/scripts/backup-validation.sh"
    
    print_success "Validation scripts created"
}

# Main execution
main() {
    print_status "Starting Backup Automation Setup..."
    print_status "Timestamp: $(date)"
    
    check_root
    detect_os
    
    install_packages
    setup_backup_environment
    create_backup_config
    create_system_backup_script
    create_database_backup_scripts
    create_restore_scripts
    create_monitoring_scripts
    create_validation_scripts
    setup_cron_jobs
    
    print_success "Backup automation setup completed successfully!"
    
    # Run initial status check
    print_status "Running initial backup status check..."
    sudo -u "$BACKUP_USER" "$BACKUP_BASE_DIR/scripts/backup-status.sh"
    
    echo
    print_status "Backup automation configured:"
    print_status "- Daily backups: 2:00 AM"
    print_status "- Weekly backups: Sunday 3:00 AM"
    print_status "- Monthly backups: 1st day 4:00 AM"
    print_status "- Backup location: $BACKUP_BASE_DIR"
    print_status "- Retention: $BACKUP_RETENTION_DAYS days"
    print_status "- Backup user: $BACKUP_USER"
    
    echo
    print_status "Available commands:"
    print_status "- sudo -u $BACKUP_USER $BACKUP_BASE_DIR/scripts/backup-status.sh"
    print_status "- sudo -u $BACKUP_USER $BACKUP_BASE_DIR/scripts/system-backup.sh daily"
    print_status "- sudo -u $BACKUP_USER $BACKUP_BASE_DIR/scripts/system-restore.sh --help"
    print_status "- sudo -u $BACKUP_USER $BACKUP_BASE_DIR/scripts/backup-validation.sh"
}

# Run main function
main "$@"
