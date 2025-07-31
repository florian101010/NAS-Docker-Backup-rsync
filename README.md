# 🐳 NAS - Docker Backup Script (rsync)

<div align="center">

## 🌍 Choose Your Language / Sprache wählen

[![English](https://img.shields.io/badge/🇺🇸_English-blue?style=for-the-badge)](#english-version)
[![Deutsch](https://img.shields.io/badge/🇩🇪_Deutsch-red?style=for-the-badge)](README_DE.md)

---

</div>

## English Version

[![Version](https://img.shields.io/badge/version-3.5.7-blue.svg)](https://github.com/florian101010/NAS-Docker-Backup-rsync/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-orange.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](https://www.kernel.org/)
[![Downloads](https://img.shields.io/github/downloads/florian101010/NAS-Docker-Backup-rsync/total.svg)](https://github.com/florian101010/NAS-Docker-Backup-rsync/releases)
[![Stars](https://img.shields.io/github/stars/florian101010/NAS-Docker-Backup-rsync.svg)](https://github.com/florian101010/NAS-Docker-Backup-rsync/stargazers)

> **Automated Docker backup script for NAS systems** - gracefully stops containers, synchronizes data with rsync, and restarts everything.

**🎯 Perfect for:** Home labs • Small businesses • Production environments • Any Docker setup on NAS devices

**🏆 Why choose this script:** Traditional backup methods **corrupt Docker data** when containers are running. This script solves that problem by intelligently managing your entire Docker ecosystem - automatically discovering containers, gracefully stopping them for data consistency, creating comprehensive backups of everything (stacks, volumes, configs), and seamlessly restarting services.

**✅ Tested & Optimized for:** UGREEN NAS • compatible with Synology • QNAP • Custom Linux NAS • Ubuntu • Debian

## 🚀 Key Features

### 🐳 **Smart Docker Management**
- **🔍 Automatic Container Discovery**: Finds all Docker Compose stacks and containers automatically
- **⏸️ Graceful Container Shutdown**: Safely stops containers to prevent data corruption during backup
- **🔄 Intelligent Restart**: Automatically restarts all services after backup completion
- **📦 Complete Stack Backup**: Backs up Docker Compose files, volumes, and persistent data (networks recreated by Compose when using `down`; with `--use-stop` networks are kept)
- **🔧 Flexible Stop Modes**: Choose between `docker compose stop` (fast) or `down` (complete cleanup)

### 🚀 **Performance & Reliability**
- **⚡ Parallel Processing**: Configurable parallel container operations (1-16 jobs) for faster backups
- **🛡️ Production-Safe**: Thread-safe operations with atomic lock protection
- **🎯 Smart Recovery**: Automatic container restart even on backup failures with signal handling
- **📊 Real-time Monitoring**: Live container status tracking with color-coded progress indicators

### 💾 **Advanced Backup Features**
- **🔄 rsync-based Synchronization**: Standard rsync behavior with intelligent flag validation and multi-tier fallback
- **🔐 External Encryption**: Script creates unencrypted backups. Encryption via external GPG pipelines after backup completion (examples provided)
- **✅ Backup Verification**: Automatic verification of backup integrity and completeness
- **📈 Comprehensive Logging**: Detailed logs with ANSI-free output and race-condition-free parallel logging

### ⚙️ **Enterprise-Grade Configuration**
- **🎛️ Highly Configurable**: Extensive command-line options for timeouts, buffers, and behavior
- **🕒 Flexible Scheduling**: Perfect for cron automation with various timing options
- **🔒 Security Features**: Fail-fast design, input validation, and secure permission handling
- **🌐 NAS Optimized**: Tested on UGREEN (DXP2800) - (TBC) compatible with Synology, QNAP, and custom Linux NAS systems

## ⚠️ Important Disclaimer

**This script is provided "as is" without warranty of any kind.** Always test thoroughly in a safe environment and maintain independent backups before production use. The authors assume no responsibility for any data loss, system damage, or service interruption that may result from using this script.

## 📋 Requirements

- **OS**: Linux (tested on Ubuntu, Debian, UGREEN NAS DXP2800)
- **Shell**: Bash 4.0+
- **Tools**: Docker Compose v2 (`docker compose`), rsync, flock
- **Permissions**: sudo access or root execution

## ⚡ Quick Start (5 Minutes)

### 1️⃣ One-Line Installation with System Check

**🇺🇸 English Version:**
```bash
# Check system requirements first
command -v docker >/dev/null 2>&1 || { echo "❌ Docker not installed. Install Docker first."; exit 1; }
command -v rsync >/dev/null 2>&1 || { echo "❌ rsync not installed. Install: sudo apt install rsync"; exit 1; }
command -v flock >/dev/null 2>&1 || { echo "❌ flock not installed (prevents overlapping backups). Install: sudo apt install util-linux"; exit 1; }
echo "✅ System requirements met"

# Download and install
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/docker_backup.sh && \
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/test_rsync_fix.sh && \
chmod +x docker_backup.sh test_rsync_fix.sh && \
echo "✅ Installation complete! Next: Test compatibility with ./test_rsync_fix.sh, then configure your paths in the script."
```

**🇩🇪 German Version:**
```bash
# Systemvoraussetzungen prüfen
command -v docker >/dev/null 2>&1 || { echo "❌ Docker nicht installiert. Installieren Sie Docker zuerst."; exit 1; }
command -v rsync >/dev/null 2>&1 || { echo "❌ rsync nicht installiert. Installation: sudo apt install rsync"; exit 1; }
command -v flock >/dev/null 2>&1 || { echo "❌ flock nicht installiert (verhindert doppelte Backups). Installation: sudo apt install util-linux"; exit 1; }
echo "✅ Systemvoraussetzungen erfüllt"

# Download und Installation
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/docker_backup_de.sh && \
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/test_rsync_fix_de.sh && \
chmod +x docker_backup_de.sh test_rsync_fix_de.sh && \
echo "✅ Installation abgeschlossen! Weiter: Kompatibilität testen mit ./test_rsync_fix_de.sh, dann Pfade im Script konfigurieren."
```

### 2️⃣ Configure Your Paths
Edit these 5 lines in [`docker_backup.sh`](docker_backup.sh) (lines 25-37):
```bash
# Open script with nano editor
nano docker_backup.sh

# Configure these paths for your system:
DATA_DIR="/volume1/docker-nas/data"          # Your Docker data directory
STACKS_DIR="/volume1/docker-nas/stacks"      # Your Docker Compose files
BACKUP_SOURCE="/volume1/docker-nas"          # Source directory to backup - other example: /volume1/@docker
BACKUP_DEST="/volume2/backups/docker-nas-backup" # Where to store backups
LOG_DIR="/volume1/docker-nas/logs"           # Log file location
```

### 3️⃣ Test & Run
```bash
# Test first (safe - no changes made)
./docker_backup.sh --dry-run

# Run interactive backup
./docker_backup.sh

# Automated backup (for cron)
./docker_backup.sh --auto
```

### 4️⃣ Next Steps Checklist
After installation, follow these steps in order:

**✅ Immediate Setup (Required):**
1. **Test compatibility**: `./test_rsync_fix.sh`
2. **Configure paths**: Edit script with your NAS paths
3. **Test configuration**: `./docker_backup.sh --dry-run`
4. **First backup**: `./docker_backup.sh` (interactive)

**⚙️ Production Setup (Recommended):**

5. **Setup automation**: Add to cron for daily backups
6. **Test restore**: Verify you can restore from backup
7. **Monitor logs**: Check backup logs regularly

**🔒 Security Setup (Optional):**

8. **Preserve ACLs**: Use `--preserve-acl` for file permissions (not encryption)
9. **Secure backup location**: Ensure backup destination has proper permissions

## 🌍 Language Support

| Language | Script File | Status |
|----------|-------------|---------|
| **🇺🇸 English** | [`docker_backup.sh`](docker_backup.sh) | ✅ Main version |
| **🇩🇪 German** | [`docker_backup_de.sh`](docker_backup_de.sh) | ✅ Fully translated |

## 📊 Usage Examples

```bash
# 🧪 Test mode (safe - shows what would happen)
./docker_backup.sh --dry-run

# 🎯 Interactive backup with confirmation
./docker_backup.sh

# 🤖 Automated backup (perfect for cron)
./docker_backup.sh --auto

# ⚡ High-performance parallel backup
./docker_backup.sh --auto --parallel 4 --use-stop

# 📋 Backup with ACL preservation (not encryption)
./docker_backup.sh --auto --preserve-acl
```

## 📖 Detailed Configuration

**💡 Pro Tips:**
- Always test with `--dry-run` first
- Ensure backup destination has 2x source size available
- Use `--parallel 4` for faster backups on powerful systems
- Set up cron for automated daily backups

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
| `--preserve-acl` | Preserve ACLs and extended attributes (not encryption) | Enabled |
| `--skip-backup` | Only restart containers | Disabled |
| `--no-verify` | Skip backup verification | Disabled |

## 🔄 Automation with Cron

### Safe Parallel Cron Examples (v3.5.1+)

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

### Required Dependencies
- **`flock`**: Provides exclusive execution (no overlapping runs) and thread-safe logging when using parallel operations

### Backup Verification
- Directory size comparison with configurable tolerance
- File and directory count verification
- ACL and extended attributes support (when available)
- Detailed error reporting with specific rsync exit code analysis
- External encryption via GPG pipelines after backup completion (not integrated in script)

## 📊 Monitoring & Logging

### Log Files
- Location: `/path/to/your/logs/docker_backup_YYYYMMDD_HHMMSS.log`
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

**Missing dependencies:**
```bash
# flock not found error
sudo apt install util-linux  # Ubuntu/Debian
sudo yum install util-linux  # CentOS/RHEL

```

**Containers won't start:**
```bash
# Check container status
docker ps -a

# Check specific container logs
docker logs <container_name>

# Manual stack restart
cd /path/to/your/stacks/<stack_name>
sudo docker compose up -d
```

**Backup failures:**
```bash
# Check available space
df -h /path/to/backup/destination

# Test rsync manually
sudo rsync -av --dry-run /path/to/source/ /path/to/destination/
```

**Permission issues:**
```bash
# Check backup destination permissions
ls -la /path/to/backup/destination

# Fix permissions if needed
sudo chown -R $(whoami):$(id -gn) /path/to/backup/destination
```

### Dependency Validation

**Quick smoke tests:**
```bash
# Validate flock works (mutex simulation)
LOCK=/tmp/test.lock; exec 9>"$LOCK"; flock -n 9 && echo "✅ flock OK"
```

## 🔐 Backup Encryption

The script creates unencrypted backups. For encryption, use external GPG pipelines **after** backup completion as shown below.

### Quick Encryption Setup

```bash
# 1. Create normal backup
./docker_backup.sh --auto

# 2. Encrypt backup with GPG
tar -czf - /path/to/backup/ | \
gpg --symmetric --cipher-algo AES256 \
> backup_encrypted_$(date +%Y%m%d_%H%M%S).tar.gz.gpg

# 3. Secure password storage for automation
echo "YOUR_SECURE_PASSWORD" | sudo tee /path/to/.backup_password
sudo chmod 600 /path/to/.backup_password
```

### Automated Encrypted Backups

```bash
# Cron job for daily encrypted backups
0 2 * * * /path/to/docker_backup.sh --auto && \
tar -czf - /path/to/backup/ | \
gpg --symmetric --cipher-algo AES256 --passphrase-file /path/to/.backup_password \
> /path/to/backup_encrypted_$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz.gpg
```

### Restoring Encrypted Backups

```bash
# Decrypt and restore
gpg --decrypt backup_encrypted_YYYYMMDD_HHMMSS.tar.gz.gpg | tar -xzf - -C /
```

**📖 For detailed encryption documentation, see [Backup Encryption Guide](docs/EN/MANUAL_EN.md#backup-encryption)**

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Development Setup
```bash
git clone https://github.com/florian101010/NAS-Docker-Backup-rsync.git
cd NAS-Docker-Backup-rsync
chmod +x docker_backup.sh test_rsync_fix.sh
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🎯 Use Cases & Success Stories

**Perfect for these scenarios:**
- 🏠 **Home Labs**: Protect your self-hosted services (Plex, Nextcloud, etc.)
- 🏢 **Small Business**: Backup critical Docker applications safely
- 🔧 **Development**: Consistent backup of development environments
- 📊 **Production**: Enterprise-grade backup for production Docker stacks

## 🙏 Acknowledgments

- 🛠️ **Built on rsync**: Powered by the robust [rsync project](https://rsync.samba.org/) for reliable file synchronization
- 🐳 **Docker Integration**: Leverages [Docker](https://www.docker.com/) and [Docker Compose](https://docs.docker.com/compose/) ecosystem
- ✅ **Tested & Optimized**: UGREEN NAS DXP2800
- 🌟 **Open Source**: MIT licensed for maximum flexibility

## 📈 Version History

See [CHANGELOG.md](CHANGELOG.md) for detailed release notes.

## 📚 Documentation

### Quick Start
- 🚀 **[Quick Start Guide (English)](QUICKSTART.md)** - Get up and running in 5 minutes
- 🚀 **[Schnellstart-Anleitung (Deutsch)](QUICKSTART_DE.md)** - In 5 Minuten zum ersten Backup

### Detailed Guides
- 🇺🇸 **[English Manual](docs/EN/MANUAL_EN.md)** - Complete user guide in English
- 🇩🇪 **[German Manual](docs/DE/ANLEITUNG_DE.md)** - Vollständige Anleitung auf Deutsch

### Automation
- 🇺🇸 **[Cron Automation (EN)](docs/EN/CRON_AUTOMATION_EN.md)** - Setting up automated backups
- 🇩🇪 **[Cron Automatisierung (DE)](docs/DE/CRON_AUTOMATISIERUNG_DE.md)** - Automatisierte Backups einrichten

### Development
- 🛠️ **[Contributing Guide](CONTRIBUTING.md)** - How to contribute to this project
- 🔒 **[Security Policy](SECURITY.md)** - Security guidelines and reporting

---

---

## 📸 Screenshots

### Backup Process in Action

<img width="1672" height="2886" alt="github1_screenshot_optimized" src="https://github.com/user-attachments/assets/c93101ed-8cf3-4d9a-bdf1-2f8d916adf4f" />
<img width="1672" height="2886" alt="github2_screenshot_optimized" src="https://github.com/user-attachments/assets/c41afa70-a1cb-4983-b88c-d6f3bf144232" />
<img width="1672" height="2886" alt="github3_screenshot_optimized" src="https://github.com/user-attachments/assets/0357fff5-9466-4f83-b2a4-85f452d290a9" />



