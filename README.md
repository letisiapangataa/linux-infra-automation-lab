# Linux Infrastructure Automation Lab

A practical lab for automating, securing, and managing Linux infrastructure.

---

## Features

### Security & Hardening
- SSH (key-only, port 2222), UFW/firewalld
- Fail2Ban, AIDE, system auditing
- Kernel hardening (sysctl)

### Monitoring & Alerts
- Prometheus and Grafana dashboards
- Node Exporter, custom alerts (CPU, memory, disk, etc.)

### Logging
- Centralized logs via rsyslog
- Security analysis and rotation

### Backups
- Daily, weekly, and monthly backups
- MySQL/PostgreSQL support, validation, and restore

---

## Quick Start

```bash
git clone https://github.com/letisiapangataa/linux-infra-automation-lab.git
cd linux-infra-automation-lab
sudo make install     # OR: sudo ./setup.sh
```

### Access
- SSH: ssh -p 2222 user@server-ip
- Grafana: http://server-ip:3000
- Prometheus: http://server-ip:9090

---

## Key Scripts

| Script                | Purpose                    |
|-----------------------|----------------------------|
| setup.sh              | Full install               |
| hardening.sh          | Secure system              |
| monitoring-setup.sh   | Set up Prometheus & Grafana|
| log-aggregation.sh    | Log management             |
| backup-automation.sh  | Backup setup               |

---

## Management Commands

```bash
make status     # Check all services
make security   # Run security audit
make backup     # Manual backup
make logs       # Analyze logs
make monitor    # Check monitoring
```

---

## Project Structure

```
scripts/         # Automation scripts
configs/         # SSH, Fail2Ban, sysctl configs
grafana/         # Dashboards
docs/            # Guides and recovery info
```

---

## Use Cases

- Public sector and critical infrastructure
- DevOps and security teams
- System administration and cybersecurity training

---

## Documentation

- Installation Guide: docs/installation-guide.md  
- Recovery Procedures: docs/recovery-procedures.md  
- Architecture Diagram: docs/architecture-diagram.md

---

## Contributing

All contributions are welcome. Run checks before submitting:

```bash
make check
make dev-test
```

---

## License

MIT License

---

## References

- CIS Benchmarks: https://www.cisecurity.org/cis-benchmarks/  
- Prometheus Documentation: https://prometheus.io/docs/  
- Grafana Documentation: https://grafana.com/docs/

