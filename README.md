# Linux Infrastructure Automation Lab

This Linux Infrastructure Automation Lab is a comprehensive toolkit for automating, securing, monitoring, and managing Linux servers. It includes scripts and configurations for system hardening, centralized logging, monitoring with Prometheus and Grafana, automated backups, and more. The project is designed for DevOps, security teams, and system administrators to quickly deploy production-grade infrastructure with best practices.

## Step-by-Step Instructions

1. **Clone the Repository**
	```bash
	git clone https://github.com/letisiapangataa/linux-infra-automation-lab.git
	cd linux-infra-automation-lab
	```

2. **Install the Lab**
	```bash
	sudo make install
	# OR
	sudo ./setup.sh
	```
3. **Access Services**
	- SSH: `ssh -p 2222 user@server-ip`
	make logs       # Analyze logs
	make monitor    # Check monitoring

5. **Documentation**
	- Installation Guide: `docs/installation-guide.md`
	- Architecture Diagram: `docs/architecture-diagram.md`

6. **Verify Project Setup**
	chmod +x verify-project.sh
	./verify-project.sh
	```

A practical lab for automating, securing, and managing Linux infrastructure.


## Features

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

## Supporting Online Learning Resources

**Linux & System Administration:**
- [Linux Foundation Training: Introduction to Linux (LFS101x)](https://training.linuxfoundation.org/training/introduction-to-linux/)
- [edX: Linux System Administration Essentials](https://www.edx.org/learn/linux)
- [Coursera: Linux Server Management and Security](https://www.coursera.org/learn/linux-server-management-security)
- [Cybrary: Linux Fundamentals](https://www.cybrary.it/course/linux-fundamentals/)
- [DigitalOcean Community: Linux Tutorials](https://www.digitalocean.com/community/tutorials)
- [The Geek Stuff: 50 Linux Commands](https://www.thegeekstuff.com/2010/11/50-linux-commands/)
- [Linux Journey (Free Interactive)](https://linuxjourney.com/)
- [OverTheWire: Bandit (Linux Security Wargame)](https://overthewire.org/wargames/bandit/)

**Security & Hardening:**
- [CIS Benchmarks for Linux](https://www.cisecurity.org/cis-benchmarks/)
- [OpenSCAP Security Guide](https://www.open-scap.org/security-policies/scap-security-guide/)
- [Linux Security for Beginners (YouTube)](https://www.youtube.com/watch?v=V2aq5M3Q76U)
- [Practical Linux Hardening Guide (GitHub)](https://github.com/trimstray/the-practical-linux-hardening-guide)

**Monitoring & Observability:**
- [Prometheus Up & Running (O'Reilly)](https://www.oreilly.com/library/view/prometheus-up/9781492034131/)
- [Prometheus Official Documentation](https://prometheus.io/docs/)
- [Grafana Labs Tutorials](https://grafana.com/tutorials/)
- [Awesome Prometheus (Curated List)](https://github.com/roaldnefs/awesome-prometheus)
- [Monitoring Linux Performance with Grafana](https://grafana.com/blog/2021/03/31/how-to-monitor-linux-server-performance-with-grafana/)

**Backups & Disaster Recovery:**
- [DigitalOcean: How To Back Up, Restore, and Migrate a MySQL Database](https://www.digitalocean.com/community/tutorials/how-to-back-up-restore-and-migrate-a-mysql-database-on-ubuntu-20-04)
- [PostgreSQL: Backup and Restore](https://www.postgresql.org/docs/current/backup-dump.html)
- [Linux System Backup and Restore (YouTube)](https://www.youtube.com/watch?v=QvQZbYb2p2A)

**General DevOps & Automation:**
- [Awesome DevOps (Curated List)](https://github.com/ligurio/awesome-devops)
- [ShellCheck: Shell Script Analysis Tool](https://www.shellcheck.net/)
- [ExplainShell: Shell Command Explainer](https://explainshell.com/)

## Lab Resources

**Project Documentation:**
- [Installation Guide](docs/installation-guide.md)
- [Recovery Procedures](docs/recovery-procedures.md)
- [Architecture Diagram](docs/architecture-diagram.md)
- [Project Summary](PROJECT-SUMMARY.md)

**Configuration Templates:**
- [SSH Hardened Config](configs/sshd_config_hardened)
- [Fail2Ban Jail Local](configs/fail2ban_jail.local)
- [Sysctl Security Config](configs/sysctl_security.conf)

**Automation Scripts:**
- [System Hardening](scripts/hardening.sh)
- [Monitoring Setup](scripts/monitoring-setup.sh)
- [Log Aggregation](scripts/log-aggregation.sh)
- [Backup Automation](scripts/backup-automation.sh)

**Dashboards:**
- [Grafana Dashboard](grafana/linux-infrastructure-dashboard.json)

**Lab Practice & Testing:**
- [verify-project.sh: Project Verification Script](verify-project.sh)
- [setup.sh: Full Lab Installer](setup.sh)
- [Makefile: Management Interface](Makefile)

**External Lab Environments:**
- [Katacoda: Interactive Linux Labs](https://www.katacoda.com/courses/linux)
- [Play with Docker: Free Linux VMs](https://labs.play-with-docker.com/)
- [Google Cloud Shell: Free Cloud Linux Shell](https://shell.cloud.google.com/)

**References:**
- CIS Benchmarks: https://www.cisecurity.org/cis-benchmarks/  
- Prometheus Documentation: https://prometheus.io/docs/  
- Grafana Documentation: https://grafana.com/docs/

---

## License

MIT License


