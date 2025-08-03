# Linux Infrastructure Automation Lab (Development)

An almost* production-ready Linux infrastructure management and security lab showcasing enterprise-grade system engineering practices. This project showcases automated deployment, security hardening, monitoring, and backup solutions suitable for public sector and critical infrastructure environments.

---

## Project Overview

This project provides a complete, automated Linux infrastructure solution with enterprise-level security, monitoring, and operational capabilities:

### Security & Hardening
- **SSH Hardening**: Custom port (2222), key-only authentication, connection limits
- **Firewall Configuration**: UFW/firewalld with minimal attack surface
- **System Auditing**: Real-time file integrity monitoring with AIDE
- **Intrusion Prevention**: Fail2Ban with custom rules and alerting
- **Kernel Hardening**: Security-focused sysctl parameters

### Monitoring & Alerting
- **Prometheus Stack**: Metrics collection and storage (30-day retention)
- **Grafana Dashboards**: Real-time system visualization and alerting
- **Node Exporter**: Comprehensive system metrics collection
- **Custom Alerts**: CPU, memory, disk, and security event monitoring

### Log Management
- **Centralized Logging**: rsyslog with remote collection capabilities
- **Log Analysis**: Automated security event correlation and reporting
- **Log Rotation**: Automated cleanup with configurable retention
- **Real-time Monitoring**: 15-minute security event scanning

### Backup & Recovery
- **Automated Backups**: Daily, weekly, and monthly backup schedules
- **Backup Validation**: Automated integrity checking and test restores
- **Database Support**: MySQL and PostgreSQL backup scripts
- **Disaster Recovery**: Complete system restore procedures

---

## Quick Start

### One-Command Installation
```bash
# Clone the repository
git clone https://github.com/letisiapangataa/linux-infra-automation-lab.git
cd linux-infra-automation-lab

# Run complete setup (requires sudo)
sudo make install
# OR
sudo ./setup.sh
```

### Post-Installation Access
- **SSH**: `ssh -p 2222 user@server-ip`
- **Grafana**: `http://server-ip:3000` (admin/admin123)
- **Prometheus**: `http://server-ip:9090`

---

## Key Components

### Automation Scripts

| Script | Purpose | Features |
|--------|---------|----------|
| **`setup.sh`** | Master installation script | Complete automated deployment |
| **`hardening.sh`** | Security hardening | SSH, firewall, auditing, AIDE, Fail2Ban |
| **`monitoring-setup.sh`** | Monitoring stack | Prometheus, Grafana, Node Exporter |
| **`log-aggregation.sh`** | Log management | rsyslog, rotation, analysis, alerting |
| **`backup-automation.sh`** | Backup system | Automated backups, validation, restore |

### Management Tools

| Tool | Command | Purpose |
|------|---------|---------|
| **System Status** | `make status` | Check all service health |
| **Security Audit** | `make security` | Run security analysis |
| **Log Analysis** | `make logs` | Interactive log analysis |
| **Backup Management** | `make backup` | Manual backup execution |
| **Monitoring Health** | `make monitor` | Check monitoring stack |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Linux Infrastructure Lab                         │
│                                                                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐ │
│  │   Security      │    │   Monitoring    │    │  Log Aggregation│ │
│  │   Layer         │    │   Stack         │    │     System      │ │
│  │                 │    │                 │    │                 │ │
│  │ • SSH (2222)    │    │ • Prometheus    │    │ • rsyslog (514) │ │
│  │ • Fail2Ban      │    │ • Grafana (3000)│   │ • Log Analysis  │ │
│  │ • Firewall      │    │ • Node Exporter │    │ • Retention     │ │
│  │ • AIDE          │    │ • Alerting      │    │ • Monitoring    │ │
│  │ • Auditing      │    │ • Dashboards    │    │ • Rotation      │ │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘ │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    Backup & Recovery                        │   │
│  │                                                             │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐     │   │
│  │  │   Daily     │    │   Weekly    │    │   Monthly   │     │   │
│  │  │  (02:00)    │    │  (Sun 03:00)│    │  (1st 04:00)│     │   │
│  │  │             │    │             │    │             │     │   │
│  │  │ • System    │    │ • Full      │    │ • Archive   │     │   │
│  │  │ • Configs   │    │   Backup    │    │ • Long-term │     │   │
│  │  │ • Logs      │    │ • Database  │    │   Storage   │     │   │
│  │  │ • Validation│    │ • Validation│    │ • Compliance│     │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘     │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
linux-infra-automation-lab/
├── setup.sh                    # Master installation script
├── Makefile                     # Management commands
├── README.md                    # Project documentation
├── scripts/                     # Core automation scripts
│   ├── hardening.sh            # Security hardening
│   ├── monitoring-setup.sh     # Monitoring stack
│   ├── log-aggregation.sh      # Log management
│   └── backup-automation.sh    # Backup automation
├── configs/                     # Configuration templates
│   ├── sshd_config_hardened    # SSH hardening config
│   ├── fail2ban_jail.local     # Fail2Ban configuration
│   └── sysctl_security.conf    # Kernel security parameters
├── grafana/                     # Grafana dashboards
│   └── linux-infrastructure-dashboard.json
├── docs/                        # Documentation
│   ├── installation-guide.md   # Detailed installation guide
│   ├── recovery-procedures.md  # Disaster recovery docs
│   └── architecture-diagram.md # System architecture
└── backup/                      # Backup configurations
```

---

## Use Cases

### Public Sector Infrastructure
- **Government Agencies**: Secure, auditable infrastructure management
- **Critical Infrastructure**: Power grids, water systems, transportation
- **Defense Contractors**: Security-focused system administration
- **Educational Institutions**: IT infrastructure management training

### Enterprise Applications
- **DevOps Teams**: Infrastructure automation and monitoring
- **Security Teams**: Security hardening and incident response
- **System Administrators**: Operational excellence and best practices
- **Compliance Teams**: Audit trails and regulatory compliance

### Educational & Training
- **System Administration Courses**: Hands-on Linux infrastructure
- **Cybersecurity Training**: Security hardening and monitoring
- **DevOps Bootcamps**: Infrastructure as Code practices
- **Professional Certification**: RHCE, LPIC, CompTIA Linux+

---

## Advanced Features

### Security Features
- **Multi-layered Security**: Defense in depth architecture
- **Real-time Monitoring**: Continuous security event detection
- **Automated Response**: Fail2Ban with custom actions
- **Audit Compliance**: Full audit trail for regulatory requirements
- **File Integrity**: AIDE monitoring with alerting

### Monitoring Capabilities
- **Custom Dashboards**: Tailored Grafana visualizations
- **Alert Management**: Prometheus alerting with escalation
- **Performance Metrics**: System, application, and security metrics
- **Capacity Planning**: Historical data analysis and trending
- **SLA Monitoring**: Uptime and performance tracking

### Automation Benefits
- **Zero-touch Deployment**: Fully automated installation
- **Consistent Configuration**: Repeatable, version-controlled setup
- **Operational Efficiency**: Reduced manual intervention
- **Error Reduction**: Automated validation and testing
- **Scalability**: Easy replication across multiple systems

---

## Monitoring & Alerting

### Key Metrics Tracked
- **System Performance**: CPU, memory, disk, network utilization
- **Security Events**: Failed logins, intrusion attempts, file changes
- **Service Health**: Process monitoring, port availability, response times
- **Resource Usage**: Storage consumption, backup status, log volume
- **Network Activity**: Connection tracking, bandwidth utilization

### Alert Conditions
- **High CPU Usage**: >80% for 5+ minutes
- **Memory Pressure**: >85% utilization
- **Disk Space**: >90% full
- **Failed Authentication**: >20 attempts per hour
- **Service Downtime**: Critical service unavailable
- **File Integrity**: Unauthorized system file changes

---

## Security Standards Compliance

### Security Frameworks
- **CIS Benchmarks**: Center for Internet Security hardening guidelines
- **NIST Framework**: National Institute of Standards and Technology
- **ISO 27001**: International security management standards
- **FISMA**: Federal Information Security Management Act
- **SOC 2**: Service Organization Control 2 compliance

### Security Controls Implemented
- **Access Control**: Role-based access with SSH key authentication
- **Network Security**: Firewall configuration with minimal exposure
- **Audit Logging**: Comprehensive system and security event logging
- **Incident Response**: Automated detection and alerting
- **Data Protection**: Encryption at rest and in transit
- **Vulnerability Management**: Regular security updates and patching

---

## Getting Started

### Prerequisites
- **Operating System**: Ubuntu 20.04+ or CentOS 8+/RHEL 8+
- **Hardware**: 4GB RAM, 50GB storage, 2+ CPU cores
- **Network**: Internet connectivity for package downloads
- **Access**: Root/sudo privileges

### Installation Options

#### Option 1: Complete Automated Setup
```bash
git clone https://github.com/letisiapangataa/linux-infra-automation-lab.git
cd linux-infra-automation-lab
sudo make install
```

#### Option 2: Step-by-Step Installation
```bash
git clone https://github.com/letisiapangataa/linux-infra-automation-lab.git
cd linux-infra-automation-lab
sudo ./scripts/hardening.sh
sudo ./scripts/monitoring-setup.sh
sudo ./scripts/log-aggregation.sh
sudo ./scripts/backup-automation.sh
```

#### Option 3: Custom Installation
```bash
# Install only specific components
sudo ./scripts/hardening.sh          # Security only
sudo ./scripts/monitoring-setup.sh   # Monitoring only
```

---

## Documentation

### Available Guides
- **[Installation Guide](docs/installation-guide.md)**: Comprehensive setup instructions
- **[Recovery Procedures](docs/recovery-procedures.md)**: Disaster recovery and testing
- **[Architecture Diagram](docs/architecture-diagram.md)**: System design and components

### Management Commands
```bash
make status      # Check all service status
make security    # Run security analysis
make logs        # Interactive log analysis
make backup      # Execute manual backup
make monitor     # Check monitoring health
make test        # Run system validation
make clean       # Remove all components
```

---

## Contributing

Contributions are welcome! This project serves as both a learning resource and a production-ready infrastructure template.

### Development Setup
```bash
git clone https://github.com/letisiapangataa/linux-infra-automation-lab.git
cd linux-infra-automation-lab
make check       # Verify requirements
make dev-test    # Run syntax checks
```

### Contribution Guidelines
- Follow existing code style and documentation standards
- Test all changes in a virtualized environment
- Update documentation for new features
- Include security considerations for all modifications

---

## License

MIT License - See LICENSE file for details

---

## References & Resources

### Security Standards
- [CIS Benchmarks for Linux](https://www.cisecurity.org/cis-benchmarks/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Ubuntu Server Security Guide](https://ubuntu.com/server/docs/security)

### Technology Documentation
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [rsyslog Documentation](https://www.rsyslog.com/doc/)

### Learning Resources
- [Linux System Administration](https://www.redhat.com/en/services/training)
- [DevOps and Infrastructure as Code](https://aws.amazon.com/devops/)
- [Cybersecurity Best Practices](https://www.sans.org/white-papers/)

---

## Contact & Support

For questions, issues, or contributions:
- **GitHub Issues**: [Project Issues](https://github.com/letisiapangataa/linux-infra-automation-lab/issues)
- **Documentation**: Check the `docs/` directory for detailed guides
- **Community**: Share your implementations and improvements

---

## Project Highlights

This project demonstrates:
- **Enterprise-grade Infrastructure**: Production-ready automation and monitoring
- **Security-first Approach**: Comprehensive hardening and compliance
- **Operational Excellence**: Automated deployment, monitoring, and maintenance
- **Educational Value**: Real-world skills development and best practices
- **Scalable Design**: Easily adaptable to various environments and requirements

**Perfect for showcasing system administration, DevOps, and cybersecurity expertise in professional portfolios and interviews.**



