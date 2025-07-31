# Linux Infrastructure Architecture

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Linux Infrastructure Lab                         │
│                                                                     │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐ │
│  │   Security      │    │   Monitoring    │    │  Log Aggregation│ │
│  │   Hardening     │    │   Stack         │    │     Stack       │ │
│  │                 │    │                 │    │                 │ │
│  │ • SSH Config    │    │ • Prometheus    │    │ • rsyslog       │ │
│  │ • Fail2Ban      │    │ • Node Exporter │    │ • logrotate     │ │
│  │ • Firewall      │    │ • Grafana       │    │ • Log Analysis  │ │
│  │ • AIDE          │    │ • Alerting      │    │ • Monitoring    │ │
│  │ • Audit         │    │                 │    │                 │ │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘ │
│           │                       │                       │         │
│           └───────────────────────┼───────────────────────┘         │
│                                   │                                 │
│  ┌─────────────────────────────────┼─────────────────────────────┐   │
│  │              Core Linux System  │                             │   │
│  │                                 │                             │   │
│  │  ┌─────────────┐    ┌──────────┴────────┐    ┌─────────────┐  │   │
│  │  │   System    │    │     Network        │    │   Storage   │  │   │
│  │  │  Services   │    │   & Security       │    │ & Backups   │  │   │
│  │  │             │    │                    │    │             │  │   │
│  │  │ • systemd   │    │ • iptables/ufw     │    │ • File      │  │   │
│  │  │ • cron      │    │ • SSH (port 2222)  │    │   Systems   │  │   │
│  │  │ • networking│    │ • TLS/SSL          │    │ • Automated │  │   │
│  │  │ • logging   │    │ • VPN Ready        │    │   Backups   │  │   │
│  │  └─────────────┘    └───────────────────┘    │ • Validation│  │   │
│  └─────────────────────────────────────────────┬─────────────┘  │   │
│                                                 │                │   │
│  ┌─────────────────────────────────────────────┴─────────────┐  │   │
│  │                    Backup System                          │  │   │
│  │                                                           │  │   │
│  │  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐   │  │   │
│  │  │   Daily     │    │   Weekly    │    │   Monthly   │   │  │   │
│  │  │  Backups    │    │   Backups   │    │   Backups  │   │  │   │
│  │  │             │    │             │    │             │   │  │   │
│  │  │ • System    │    │ • Full      │    │ • Archive   │   │  │   │
│  │  │ • Configs   │    │   Image     │    │ • Long-term │   │  │   │
│  │  │ • Logs      │    │ • Database  │    │   Storage   │   │  │   │
│  │  │ • Data      │    │ • Validation│    │ • Compliance│   │  │   │
│  │  └─────────────┘    └─────────────┘    └─────────────┘   │  │   │
│  └─────────────────────────────────────────────────────────┘  │   │
└─────────────────────────────────────────────────────────────────┘   │
                                                                       │
┌─────────────────────────────────────────────────────────────────────┘
│                           External Interfaces
│
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  │  Remote Access  │    │   Monitoring    │    │     Backup      │
│  │                 │    │   Dashboard     │    │   Storage       │
│  │ • SSH (2222)    │    │                 │    │                 │
│  │ • VPN Access    │    │ • Grafana UI    │    │ • Local Storage │
│  │ • Admin Portal  │    │ • Prometheus    │    │ • Remote Sync   │
│  │                 │    │ • Alerts        │    │ • Cloud Storage │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Network Architecture

```
Internet/WAN
     │
     ▼
┌─────────────────────────────────────────────────────────┐
│                   Firewall                              │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │
│  │   SSH       │  │  Monitoring │  │    Web      │     │
│  │ Port 2222   │  │ Port 3000   │  │  Port 80    │     │
│  │             │  │ Port 9090   │  │  Port 443   │     │
│  └─────────────┘  └─────────────┘  └─────────────┘     │
└─────────────────────────────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────────────────────────────┐
│                Internal Network                         │
│                  192.168.1.0/24                        │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              Linux Server                       │   │
│  │            192.168.1.100                        │   │
│  │                                                 │   │
│  │  ┌─────────────┐  ┌─────────────┐              │   │
│  │  │  Services   │  │   Storage   │              │   │
│  │  │             │  │             │              │   │
│  │  │ • SSH       │  │ • /var/log  │              │   │
│  │  │ • Prometheus│  │ • /opt/     │              │   │
│  │  │ • Grafana   │  │   backups   │              │   │
│  │  │ • rsyslog   │  │ • /etc      │              │   │
│  │  └─────────────┘  └─────────────┘              │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Security Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Security Layers                        │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                Layer 7: Application             │   │
│  │  • Web Application Firewall                     │   │
│  │  • Application-specific security                │   │
│  │  • Input validation and sanitization            │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │                Layer 6: Access Control          │   │
│  │  • SSH Key Authentication                       │   │
│  │  • Fail2Ban intrusion prevention               │   │
│  │  • User privilege management                    │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │                Layer 5: Network Security        │   │
│  │  • Firewall rules (iptables/ufw)               │   │
│  │  • Port restrictions                            │   │
│  │  • Network segmentation                         │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │                Layer 4: System Hardening        │   │
│  │  • Kernel parameter tuning                      │   │
│  │  • Service minimization                         │   │
│  │  • File system permissions                      │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │                Layer 3: File Integrity          │   │
│  │  • AIDE monitoring                              │   │
│  │  • System auditing (auditd)                    │   │
│  │  • Log integrity verification                   │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │                Layer 2: Monitoring & Alerting   │   │
│  │  • Real-time log analysis                       │   │
│  │  • Performance monitoring                       │   │
│  │  • Security event correlation                   │   │
│  └─────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────┐   │
│  │                Layer 1: Physical Security       │   │
│  │  • Data encryption at rest                      │   │
│  │  • Secure backup storage                        │   │
│  │  • Hardware security modules                    │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Data Flow Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Data Flow                           │
│                                                         │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│  │   System    │───▶│   rsyslog   │───▶│   Central   │ │
│  │    Logs     │    │   Server    │    │ Log Storage │ │
│  └─────────────┘    └─────────────┘    └─────────────┘ │
│         │                  │                  │        │
│         │                  ▼                  ▼        │
│         │           ┌─────────────┐    ┌─────────────┐ │
│         │           │ Log Analysis│    │ Log Rotation│ │
│         │           │  & Alerting │    │ & Retention │ │
│         │           └─────────────┘    └─────────────┘ │
│         │                                              │
│         ▼                                              │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐ │
│  │ Prometheus  │───▶│   Grafana   │───▶│  Dashboard  │ │
│  │   Metrics   │    │  Visualization   │   & Alerts  │ │
│  └─────────────┘    └─────────────┘    └─────────────┘ │
│         ▲                                              │
│         │                                              │
│  ┌─────────────┐                                       │
│  │Node Exporter│                                       │
│  │  (Metrics)  │                                       │
│  └─────────────┘                                       │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                Backup Data Flow                 │   │
│  │                                                 │   │
│  │  System ──▶ Daily ──▶ Weekly ──▶ Monthly      │   │
│  │   Data      Backup    Backup     Archive      │   │
│  │                                                 │   │
│  │  Config ──▶ Version ──▶ Remote ──▶ Cloud      │   │
│  │   Files     Control     Sync       Storage    │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Service Dependencies

```
┌─────────────────────────────────────────────────────────┐
│                Service Dependencies                     │
│                                                         │
│                    ┌─────────────┐                     │
│                    │   systemd   │                     │
│                    │  (init sys) │                     │
│                    └──────┬──────┘                     │
│                           │                            │
│           ┌───────────────┼───────────────┐            │
│           │               │               │            │
│           ▼               ▼               ▼            │
│    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐    │
│    │    SSH      │ │   rsyslog   │ │  networking │    │
│    │   Service   │ │   Service   │ │   Service   │    │
│    └──────┬──────┘ └──────┬──────┘ └──────┬──────┘    │
│           │               │               │            │
│           │               ▼               │            │
│           │        ┌─────────────┐        │            │
│           │        │  logrotate  │        │            │
│           │        │   Service   │        │            │
│           │        └─────────────┘        │            │
│           │                               │            │
│           └───────────────┬───────────────┘            │
│                           │                            │
│                           ▼                            │
│                    ┌─────────────┐                     │
│                    │ Prometheus  │                     │
│                    │   Service   │                     │
│                    └──────┬──────┘                     │
│                           │                            │
│                           ▼                            │
│                    ┌─────────────┐                     │
│                    │Node Exporter│                     │
│                    │   Service   │                     │
│                    └──────┬──────┘                     │
│                           │                            │
│                           ▼                            │
│                    ┌─────────────┐                     │
│                    │   Grafana   │                     │
│                    │   Service   │                     │
│                    └─────────────┘                     │
└─────────────────────────────────────────────────────────┘
```

## Storage Architecture

```
┌─────────────────────────────────────────────────────────┐
│                 Storage Layout                          │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │                    /                            │   │
│  │              Root Filesystem                    │   │
│  │                                                 │   │
│  │  ├── /etc          (Configuration files)       │   │
│  │  ├── /var/log      (System & application logs) │   │
│  │  ├── /home         (User directories)          │   │
│  │  ├── /opt          (Optional software)         │   │
│  │  └── /usr/local    (Local installations)       │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │              /opt/backups                       │   │
│  │            Backup Storage                       │   │
│  │                                                 │   │
│  │  ├── daily/       (Daily backups - 7 days)     │   │
│  │  ├── weekly/      (Weekly backups - 4 weeks)   │   │
│  │  ├── monthly/     (Monthly backups - 12 months)│   │
│  │  ├── configs/     (Configuration backups)      │   │
│  │  ├── scripts/     (Backup scripts)             │   │
│  │  └── logs/        (Backup operation logs)      │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │            /var/lib/prometheus                  │   │
│  │             Metrics Storage                     │   │
│  │                                                 │   │
│  │  └── data/        (Time-series data - 30 days) │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │            /var/lib/grafana                     │   │
│  │            Dashboard Storage                    │   │
│  │                                                 │   │
│  │  ├── dashboards/  (Dashboard definitions)      │   │
│  │  └── plugins/     (Grafana plugins)            │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

This architecture provides:

1. **Layered Security**: Multiple security controls at different layers
2. **Comprehensive Monitoring**: Full visibility into system performance and security
3. **Automated Operations**: Minimal manual intervention required
4. **Disaster Recovery**: Comprehensive backup and recovery capabilities
5. **Scalability**: Designed to accommodate growth and additional systems
6. **Compliance**: Meets security standards and best practices
