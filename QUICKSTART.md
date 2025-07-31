# 🚀 Docker Backup Script - Quick Start Guide

> **Get your first backup running in 5 minutes!**
> Version 3.5.1 "Production Ready"
> **✅ TESTED AND CONFIRMED FUNCTIONAL - July 30, 2025**

---

## ⚡ Get Started Immediately

### 📋 **What you need:**
- ✅ Linux system with Docker
- ✅ Docker containers already running
- ✅ 5 minutes of your time

### 🎯 **4 Steps to Backup (NEW with rsync test):**

#### **Step 1: Download and prepare scripts**
```bash
# Download scripts directly
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/docker_backup.sh
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/test_rsync_fix.sh

# Optional: Download German version
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/docker_backup_de.sh

# Make scripts executable
chmod +x docker_backup.sh test_rsync_fix.sh
# If using German version:
chmod +x docker_backup_de.sh

# Show help (optional)
./docker_backup.sh --help
# Or for German version:
./docker_backup_de.sh --help
```

### 🌍 **Language Versions Available:**

| Language | Script | Comments & Messages |
|----------|--------|-------------------|
| **🇺🇸 English** | `docker_backup.sh` | English comments and user messages |
| **🇩🇪 German** | `docker_backup_de.sh` | German comments and user messages |

**💡 Both versions have identical functionality - choose your preferred language!**

#### **Step 2: Test rsync fixes (NEW!)**
```bash
# Test the new rsync fixes in isolation
sudo ./test_rsync_fix.sh

# Expected output:
# ✅ RSYNC FIXES WORKING!
```

#### **Step 3: First test backup**
```bash
# Dry run (shows only what would happen)
sudo ./docker_backup.sh --dry-run

# Real backup with confirmation
sudo ./docker_backup.sh

# Or using German version:
sudo ./docker_backup_de.sh --dry-run
sudo ./docker_backup_de.sh
```

#### **Step 4: Set up automation**
```bash
# Cron job for daily backup at 2:00 AM
sudo crontab -e

# Add this line:
0 2 * * * /path/to/docker_backup.sh --auto
```

**🎉 Done! Your backup now runs automatically.**

---

## 🔧 Quick Adjustments

### 📁 **Adjust paths (if needed)**

Open `docker_backup.sh` and change these lines:

```bash
# Lines 19-24 in the script:
DATA_DIR="/path/to/your/docker/data"         # Your container data
STACKS_DIR="/path/to/your/docker/stacks"     # Your docker-compose files
BACKUP_SOURCE="/path/to/your/docker"         # What gets backed up
BACKUP_DEST="/path/to/your/backup/destination"  # Where it gets backed up
```

### 🎛️ **Common adjustments:**

| System | Typical Paths |
|--------|---------------|
| **UGREEN NAS** | `/volume1/docker-nas/` → `/volume2/backups/` |
| **Synology** | `/volume1/docker/` → `/volume2/backup/` |
| **QNAP** | `/share/Container/` → `/share/Backup/` |
| **Ubuntu** | `/opt/docker/` → `/backup/docker/` |

---

## ⚡ Important Commands

### 🧪 **New test commands (Version 3.5.1):**
```bash
# Test rsync fixes (NEW!)
sudo ./test_rsync_fix.sh

# Expected output:
# ✅ RSYNC FIXES WORKING!
```

### 🎯 **Basic commands:**
```bash
# Interactive backup (with confirmation)
sudo ./docker_backup.sh

# Automatic backup (no questions asked)
sudo ./docker_backup.sh --auto

# Test mode (no changes)
sudo ./docker_backup.sh --dry-run

# Only restart containers
sudo ./docker_backup.sh --skip-backup --auto

# German version examples:
sudo ./docker_backup_de.sh --auto
sudo ./docker_backup_de.sh --dry-run
```

### 🚀 **Performance commands:**
```bash
# Fast backup (stop instead of down)
./docker_backup.sh --auto --use-stop

# Parallel backup (4 containers simultaneously)
./docker_backup.sh --auto --parallel 4

# With ACL preservation (file permissions, not encryption)
./docker_backup.sh --auto --preserve-acl

# Without verification (faster)
./docker_backup.sh --auto --no-verify
```

---

## 📊 What happens during backup?

### 🔄 **The process:**
1. **Stop containers** (cleanly, not brutally)
2. **Copy data** (only changes)
3. **Start containers** (automatically)

### ⏱️ **Time required:**
- **First backup**: 1-5 minutes (depending on data amount)
- **Follow-up backups**: 10-30 seconds (only changes)
- **Container downtime**: 30-60 seconds

### 💾 **Storage space:**
- **Required**: ~100% of source size
- **Recommended**: 120% for buffer
- **Backup type**: Incremental sync (only changes, no snapshot history)

---

## 🆘 Quick Troubleshooting

### ❌ **"Docker is not available"**
```bash
# Start Docker
sudo systemctl start docker
```

### ❌ **"Sudo permission required"**
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Log in again!
```

### ❌ **"Directory not found"**
```bash
# Find your Docker directories
find /volume* -name "docker-compose.yml" 2>/dev/null
# Adjust paths in script
```

### ❌ **"Not enough disk space"**
```bash
# Check disk space
df -h
# Use less buffer
./docker_backup.sh --buffer-percent 10
```

---

## 📝 Logs & Monitoring

### 📍 **Find log files:**
```bash
# Standard log directory
ls -la /path/to/your/logs/

# Show latest logs
tail -f /path/to/your/logs/docker_backup_*.log
```

### ✅ **Check success:**
```bash
# Last successful backups
grep "successfully completed" /path/to/your/logs/docker_backup_*.log | tail -3
```

### ❌ **Find errors:**
```bash
# Search for errors in logs
grep "ERROR" /path/to/your/logs/docker_backup_*.log
```

---

## 🎯 Recommended Setups

### 🏠 **Home users (simple):**
```bash
# Daily backup at 2:00 AM
0 2 * * * /path/to/docker_backup.sh --auto
```

### 🏢 **Small businesses (robust):**
```bash
# Backup with parallelization and ACL support
0 2 * * * /path/to/docker_backup.sh --auto --parallel 4 --preserve-acl --buffer-percent 25
```

### ⚡ **Large installation (performance):**
```bash
# Fast daily backup
0 2 * * 1-6 /path/to/docker_backup.sh --auto --use-stop --parallel 8
# Complete weekly backup with ACL support
0 1 * * 0 /path/to/docker_backup.sh --auto --parallel 4 --preserve-acl
```

---

## 🔒 Encrypted Backups (Optional)

### **Simple encryption:**
```bash
# 1. Create normal backup
sudo ./docker_backup.sh --auto

# 2. Encrypt backup (with password prompt)
tar -czf - /path/to/backup/ | gpg --symmetric --cipher-algo AES256 > /path/to/backup-encrypted_$(date +%Y%m%d_%H%M%S).tar.gz.gpg

# 3. Delete unencrypted backup
rm -rf /path/to/backup/
```

### **Restore encrypted backup:**
```bash
# 1. Stop containers
sudo ./docker_backup.sh --skip-backup

# 2. Decrypt and restore
gpg --decrypt /path/to/backup-encrypted_YYYYMMDD_HHMMSS.tar.gz.gpg | tar -xzf - -C /

# 3. Start containers
sudo ./docker_backup.sh --skip-backup
```

**💡 Tip:** For detailed encryption guide see [README.md](README.md)

---

## 📚 Further Help

- 📖 **Complete guide**: [`README.md`](README.md)
- 🇩🇪 **German version**: [`QUICKSTART_DE.md`](QUICKSTART_DE.md)
- 🔧 **Technical details**: [`docs/EN/MANUAL_EN.md`](docs/EN/MANUAL_EN.md)
- ❓ **Problems?**: See FAQ in README.md

---

## ✅ Checklist Version 3.5.1

- [ ] Scripts made executable (`chmod +x docker_backup.sh test_rsync_fix.sh`)
- [ ] **NEW:** rsync fixes tested (`sudo ./test_rsync_fix.sh`)
- [ ] Paths in script checked/adjusted
- [ ] First test backup performed (`sudo ./docker_backup.sh --dry-run`)
- [ ] Real backup tested (`sudo ./docker_backup.sh`)
- [ ] Cron job set up
- [ ] Log directory checked
- [ ] Backup destination has enough space

**🎉 Everything done? Perfect! Your Docker backup now runs automatically.**

### **🏆 Version 3.5.1 Highlights:**
- ✅ **Critical security fixes** → Safe parallelization
- ✅ **Robust rsync flag validation** → Real tests instead of grep
- ✅ **Improved array-based execution** → Secure parameter passing
- ✅ **Three-tier fallback mechanism** → Automatic compatibility
- ✅ **Production ready** → Tested and stable

---

> **💡 Tip**: Perform a restore test every 2-3 months to ensure your backups are working!