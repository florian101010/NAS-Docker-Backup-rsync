# Docker NAS Backup Script

[![Version](https://img.shields.io/badge/version-3.4.9-blue.svg)](https://github.com/your-username/docker-nas-backup/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-orange.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](https://www.kernel.org/)

A robust, production-ready backup solution for Docker-based NAS systems with advanced parallelization and comprehensive error handling.

## 🚀 Features

- **🔒 Production-Safe Parallelization**: Thread-safe parallel container operations with critical security fixes
- **🛡️ Atomic Lock Protection**: Prevents concurrent executions with automatic cleanup
- **📊 Comprehensive Logging**: Detailed logs with ANSI-free output and race-condition-free parallel logging
- **⚡ High Performance**: Configurable parallel jobs (1-16) with intelligent resource management
- **🔧 Flexible Operation Modes**: Choose between `docker compose stop` (fast) or `down` (complete cleanup)
- **📈 Advanced Monitoring**: Container status tracking, backup verification, and detailed progress reporting
- **🎯 Smart Recovery**: Automatic container restart even on backup failures with signal handling
- **🔄 Incremental Backups**: rsync-based with intelligent flag validation and multi-tier fallback
- **⚙️ Highly Configurable**: Extensive command-line options for timeouts, buffers, and behavior

## 🚨 Critical Security Update (v3.4.9)

**⚠️ IMPORTANT**: Versions prior to 3.4.9 contain critical bugs when using `--parallel N>1`. Upgrade immediately for safe parallelization.

### Fixed Critical Issues:
- **Silent Backup Failures**: Functions not exported to parallel sub-shells
- **Race Conditions**: Concurrent log file access and temp directory collisions  
- **Double Execution**: Missing PID/lock file protection for cron jobs
- **Missing Variables**: Environment variables not available in sub-shells

## 📋 Requirements

- **OS**: Linux (tested on Ubuntu, Debian, UGREEN NAS DXP2800)
- **Shell**: Bash 4.0+
- **Tools**: Docker, docker-compose, rsync, flock
- **Permissions**: sudo access or root execution

## 🚀 Quick Start

### Installation

```bash
# Download the script
wget https://github.com/your-username/docker-nas-backup/releases/latest/download/docker_backup.sh
chmod +x docker_backup.sh

# Test rsync compatibility (recommended)
./test_rsync_fix.sh
```

### Basic Usage

```bash
# Interactive backup with confirmation
./docker_backup.sh

# Automated backup for cron jobs
./docker_backup.sh --auto

# Test mode (shows what would be done)
./docker_backup.sh --dry-run

# High-performance parallel backup (v3.4.9+ only)
./docker_backup.sh --auto --parallel 4 --use-stop
```

## 📖 Configuration

### Default Paths
```bash
DATA_DIR="/volume1/docker-nas/data"
STACKS_DIR="/volume1/docker-nas/stacks"
BACKUP_SOURCE="/volume1/docker-nas"
BACKUP_DEST="/volume2/@home/florian/Backups/docker-nas-backup-rsync"
LOG_DIR="/volume1/docker-nas/logs"
```

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--auto` | Automated execution without confirmation | Interactive |
| `--dry-run` | Test mode without changes | Disabled |
| `--parallel N` | Parallel container operations (1-16) | 1 |
| `--use-stop` | Use `stop` instead of `down` | `down` |
| `--timeout-stop N` | Container stop timeout (10-3600s) | 60s |
| `--timeout-start N` | Container start timeout (10-3600s) | 120s |
| `--buffer-percent N` | Storage buffer percentage (10-100%) | 20% |
| `--preserve-acl` | Preserve ACLs and extended attributes | Disabled |
| `--skip-backup` | Only restart containers | Disabled |
| `--no-verify` | Skip backup verification | Enabled |

## 🔄 Automation with Cron

### Safe Parallel Cron Examples (v3.4.9+)

```bash
# Daily fast backup with parallelization
0 2 * * * /path/to/docker_backup.sh --auto --parallel 4 --use-stop

# Weekly complete backup
0 1 * * 0 /path/to/docker_backup.sh --auto --parallel 2 --preserve-acl

# High-performance setup for large installations
0 2 * * * /path/to/docker_backup.sh --auto --parallel 6 --buffer-percent 25
```

## 🛡️ Security Features

### Fail-Safe Design
- **Fail-Fast**: `set -euo pipefail` prevents unnoticed errors
- **Signal Handling**: Automatic container recovery on interruption (CTRL+C, kill)
- **Input Validation**: All parameters validated with range checking
- **Atomic Operations**: Lock-protected execution prevents race conditions

### Backup Verification
- Directory size comparison with configurable tolerance
- File and directory count verification
- ACL and extended attributes support (when available)
- Detailed error reporting with specific rsync exit code analysis

## 📊 Monitoring & Logging

### Log Files
- Location: `/volume1/docker-nas/logs/docker_backup_YYYYMMDD_HHMMSS.log`
- ANSI-free output for clean log files
- Detailed container status with color-coded terminal output
- Thread-safe logging for parallel operations

### Container Status Indicators
- ▶ Container started (green)
- ⏸ Container stopped (yellow)  
- 🗑 Container removed (red)
- 📦 Container created (blue)

## 🔧 Troubleshooting

### Common Issues

**Containers won't start:**
```bash
# Check container status
docker ps -a

# Check specific container logs
docker logs <container_name>

# Manual stack restart
cd /volume1/docker-nas/stacks/<stack_name>
sudo docker compose up -d
```

**Backup failures:**
```bash
# Check available space
df -h /volume2

# Test rsync manually
sudo rsync -av --dry-run /volume1/docker-nas/ /volume2/backups/
```

**Permission issues:**
```bash
# Check backup destination permissions
ls -la /volume2/backups/

# Fix permissions if needed
sudo chown -R $(whoami):$(id -gn) /volume2/backups/
```

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup
```bash
git clone https://github.com/your-username/docker-nas-backup.git
cd docker-nas-backup
chmod +x docker_backup.sh test_rsync_fix.sh
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Tested and optimized for UGREEN NAS DXP2800
- Compatible with Synology, QNAP, and custom Linux NAS systems
- Community feedback and security analysis contributions

## 📈 Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed release notes.

---

**⚠️ Security Notice**: Always upgrade to the latest version for critical security fixes. Version 3.4.9+ is required for safe parallel operations.