# Docker NAS Backup Script - User Guide

## Table of Contents

- [Who is this guide for?](#who-is-this-guide-for)
- [Quick Start (for the impatient)](#quick-start-for-the-impatient)
- [Overview](#overview)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Cron Automation](#cron-automation)
- [Logging](#logging)
- [Security Features](#security-features)
- [Advanced Features](#advanced-features)
- [Backup Encryption](#backup-encryption)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Best Practices](#best-practices)

---

## Who is this guide for?

### Beginners - New to Docker/NAS?
- ✅ Follow the **step-by-step instructions**
- ✅ Use the **Quick Start section**
- ✅ All commands are explained and copy-pasteable

### Intermediate - You know Docker?
- ✅ Jump to **Configuration & Advanced Features**
- ✅ Use the **parameter reference**
- ✅ Adapt to your environment

### Experts - You want to understand everything?
- ✅ Technical details in **Advanced Features**
- ✅ Source code comments in the script
- ✅ Performance tuning options

---

## Quick Start (for the impatient)

### 3-Minute Setup

```bash
# 1. Make script executable
chmod +x docker_backup.sh

# 2. First backup (with confirmation)
./docker_backup.sh

# 3. Set up automatic backup
crontab -e
# Add: 0 2 * * * /path/to/docker_backup.sh --auto
```

**That's it!** Your backup now runs daily at 2:00 AM.

---

## Overview

The `docker_backup.sh` script creates consistent backups of all Docker containers and persistent data on the UGREEN NAS DXP2800. It automatically stops all containers, performs the backup, and restarts the containers.

### What does this script do?

**Simply explained:**
The script backs up your complete Docker setup while containers are cleanly stopped:

1. **Stops all containers** (cleanly, not brutally)
2. **Copies all data** (consistently, without data loss)
3. **Restarts all containers** (automatically)

### What gets backed up:

| Directory | Content | Importance |
|-----------|---------|------------|
| `/volume1/docker-nas/data/` | Container data (databases, files) | **CRITICAL** |
| `/volume1/docker-nas/stacks/` | docker-compose.yml files | **IMPORTANT** |
| `/volume1/docker-nas/logs/` | Log files | **USEFUL** |

### Version 3.5.1 - Critical Security Fixes

> **Important security updates implemented - July 30, 2025**

#### Critical Security Fixes (Version 3.5.1)
- **🔒 FUNCTION EXPORT FIX (PRIO 1 - CRITICAL)**: Fixes complete backup failure with parallelization
  - `export -f process_docker_output format_container_status` before all `xargs` blocks
  - **Problem fixed**: With `--parallel N>1` all `docker compose` pipes failed
  - **Impact**: Prevents silent backup failure without error message
  - **Status**: ✅ Implemented in lines 400 & 517
- **🛡️ PID/LOCK FILE PROTECTION (PRIO 2)**: Prevents duplicate cron execution
  - Atomic lock with `flock` for thread-safe execution
  - Automatic lock file cleanup on normal and abnormal exit
  - **Problem fixed**: Duplicate backup runs with cron jobs
  - **Status**: ✅ Implemented in lines 82-89 & 207
- **🔧 LOG RACE CONDITIONS FIX (PRIO 2)**: Thread-safe log output
  - Export of all critical environment variables: `LOG_FILE`, `BACKUP_DEST`, `BACKUP_SOURCE`
  - Direct logging instead of temporary files for formatted container status output
  - **Problem fixed**: Line chaos and missing formatted output in parallel jobs
  - **Status**: ✅ Implemented with complete variable export strategy
- **🔐 SECURE TEMP DIRECTORIES**: Race-condition-free temp creation
  - `mktemp -d` instead of `/tmp/rsync_test_$$` for collision-free temp directories
  - **Problem fixed**: Potential temp directory collisions with fast runs
  - **Status**: ✅ Implemented in line 631

#### New Features (Version 3.4.8)
- **🧪 ROBUST RSYNC FLAG VALIDATION**: Real functionality testing instead of grep
  - New `test_rsync_flag()` function with real rsync tests
  - Replaces unreliable `grep`-based flag detection
  - Automatic fallback from `--info=progress2` to `--progress`
  - 100% reliable compatibility checking
- **🔧 IMPROVED RSYNC EXECUTION**: New `execute_rsync_backup()` function
  - Robust path validation and automatic target directory creation
  - Secure array-based parameter passing for all flag types
  - Handles complex flags with equals signs correctly
  - Detailed debug output and error handling
- **🎯 THREE-TIER FALLBACK MECHANISM**: Automatic compatibility adaptation
  - Level 1: Optimized flags (`-a --delete --progress --stats --info=progress2`)
  - Level 2: Minimal flags (`-a --delete --progress`)
  - Level 3: Basic flags (`-a --delete`)
  - Guarantees functionality on all rsync versions
- **🎨 OPTIMIZED TERMINAL OUTPUT**: Improved readability and user-friendliness
  - Colored stack names: `→ Stopping Stack: paperless-ai` (highlighted in yellow)
  - Cyan arrows `→` for better orientation
  - Green ✅ and red ❌ status indicators with colors
  - Structured output with blue labels
  - Problematic stacks highlighted in red with bullet points
- **🧪 NEW TEST TOOLS**: Isolated validation and debugging
  - `test_rsync_fix.sh` for isolated rsync functionality testing
  - Improved logging with detailed error diagnosis
  - Automatic test results and recommendations

#### ✨ Features from Version 3.4.6 - CRITICAL RSYNC FIXES
- **🔧 ARRAY-BASED RSYNC EXECUTION**: Fixes critical parameter passing bug
- **🎯 DYNAMIC FLAG VALIDATION**: Intelligent rsync compatibility checking
- **🔧 STRING EXPANSION FIX**: Fixes final rsync parameter bug

#### ✨ Features from Version 3.4.5 - UGREEN NAS COMPATIBILITY
- **🔧 DOCKER COMPOSE ANSI FIX**: Removal of `--ansi never` for older Docker Compose versions
- **📡 RSYNC PROGRESS FIX**: Replaces `--info=progress2` with universal `--progress`
- **✅ UGREEN NAS DXP2800**: Full compatibility confirmed

### Version 3.4.4

#### New Features (Version 3.4.4)
- **🔒 SUDO_CMD EXPORT**: Explicit export for maximum sub-shell compatibility
  - `export SUDO_CMD` before xargs calls for defensive programming
  - Shell-agnostic robustness (not just Bash-specific)
  - Prevents potential variable availability issues in different shell environments

#### Features from Version 3.4.3
- **🔧 SUB-SHELL VARIABLE FIX**: Correction of `sudo_cmd_clean` variable in xargs sub-shells
- **⚡ RSYNC PERFORMANCE**: Removal of `-h` option for better log performance
- **🛡️ SAFER MEMORY BUFFER**: Minimum of 10% instead of 5% for `--buffer-percent`

#### Features from Version 3.4.2
- **🔧 NULL-BYTE DELIMITER FIX**: Critical bugfix for `printf %q` problem with stack names
  - Replaces `printf '%q\n'` with `printf '%s\0'` + `xargs -0` for robust special character handling
  - Prevents "file not found" errors with stack names containing spaces/special characters
- **📦 NUMFMT FALLBACK**: Compatibility for BusyBox/Alpine systems without `numfmt`
  - New `format_bytes()` function with automatic fallback
  - Supports GB/MB/KB formatting even without GNU coreutils
- **🧹 SUDO_CMD OPTIMIZATION**: Clean command output without double spaces
  - Improved `${SUDO_CMD:-}` syntax instead of `echo | xargs` workaround

#### Features from Version 3.4.1
- **Final micro-optimizations**: All cosmetic details perfected
- **PATH security**: Append instead of prepend for safe tool priorities
- **ACL tool check**: Check for `setfacl` availability before use
- **Robust xargs handling**: Null-byte delimiter for stack names with special characters
- **SUDO_CMD cleanup**: Eliminates double spaces in sub-shell strings

#### Features from Version 3.4
- **Complete help text documentation**: All flags are now documented in `--help`
- **Actual memory buffer usage**: `SPACE_BUFFER_PERCENT` is used correctly
- **Complete input validation**: All numeric parameters with range checking
- **Eliminated duplicate exit logs**: Cleanup only on errors, normal exit once
- **Start parallelization**: Container start also supports parallelization
- **Corrected parallel logic**: Exit status-based detection instead of container counting
- **Cron-safe PATH**: Automatic PATH export for cron environments
- **Secure log permissions**: 600 permissions and correct owner assignment
- **Race-condition-free ACL tests**: Unique filenames with PID + timestamp

#### Features from Version 3.3
- **Configurable memory buffer**: `--buffer-percent` flag for adjustable buffer
- **Parallelization**: `--parallel` flag for faster container operations
- **Improved color handling**: Colors only for terminal output
- **Robust input validation**: All numeric parameters are validated
- **Idempotent trap deactivation**: Clean exit handler without duplicates

#### Features from Version 3.2
- **Early log initialization**: LOG_FILE is created before first log_message calls
- **Complete ANSI cleanup**: All Docker outputs are color-free in log files
- **Input validation**: Numeric values for timeouts are validated
- **ACL fallback**: Automatic deactivation on unsupported filesystems
- **Optimized cleanup**: No more duplicate completion logs

#### Features from Version 3.1
- **Unified logging function**: ANSI-cleaned for log files, no more color codes
- **Improved trap handling**: Distinguishes between normal exit and signal/error
- **Configurable timeouts**: `--timeout-stop` and `--timeout-start` flags
- **ACL/xattr support**: `--preserve-acl` for Synology systems
- **ANSI-free Docker logs**: `--ansi never` for clean log files

#### Features from Version 3.0
- **Fail-fast settings**: `set -euo pipefail` prevents unnoticed errors
- **Signal handling**: Automatic container restart on script abort (CTRL+C, kill)
- **Robust stack detection**: Safe array handling for stack names with special characters
- **sudo optimization**: One-time privilege check, works as root or normal user
- **Intelligent Docker commands**: Selectable between `stop` (fast) and `down` (complete)
- **Global exit codes**: No collision with bash-internal variables

#### Features from Version 2.0
- **Extended error handling**: Start errors are now also tracked in FAILED_STACKS
- **Dynamic user detection**: Backup permissions are automatically set for the current user
- **Detailed rsync exit code analysis**: Specific error messages for various rsync problems
- **Extended backup verification**: Compares both size and file/directory count
- **Secure log files**: Temporary umask adjustment for better log security

## Installation

1. Check system requirements:
```bash
# Check system requirements first
command -v docker >/dev/null 2>&1 || { echo "❌ Docker not installed. Install Docker first."; exit 1; }
command -v rsync >/dev/null 2>&1 || { echo "❌ rsync not installed. Install: sudo apt install rsync"; exit 1; }
command -v flock >/dev/null 2>&1 || { echo "❌ flock not installed (package: util-linux)."; exit 1; }
echo "✅ System requirements met"
```

2. Download the scripts:
```bash
# Download the scripts directly
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/docker_backup.sh
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/test_rsync_fix.sh

# Make scripts executable
chmod +x docker_backup.sh test_rsync_fix.sh
```

3. Test the rsync fixes (recommended):
```bash
# Test rsync compatibility before first backup
sudo ./test_rsync_fix.sh
```

## Usage

### Basic Usage

```bash
# Interactive backup (with confirmation)
./docker_backup.sh

# Fully automatic backup (for cron jobs)
./docker_backup.sh --auto

# Test mode (shows only what would be done)
./docker_backup.sh --dry-run
```

### Available Options

| Option | Description |
|--------|-------------|
| `--auto` | Automatic execution without confirmation |
| `--dry-run` | Test mode without changes |
| `--skip-backup` | Only stops/starts containers (no backup) |
| `--no-verify` | Skips backup verification |
| `--use-stop` | Uses `docker compose stop` instead of `down` |
| `--preserve-acl` | Preserves ACLs and extended attributes (not encryption) |
| `--timeout-stop N` | Timeout for container stop (10-3600s, default: 60s) |
| `--timeout-start N` | Timeout for container start (10-3600s, default: 120s) |
| `--parallel N` | Parallel jobs for container ops (1-16, default: 1) |
| `--buffer-percent N` | Memory buffer in percent (10-100%, default: 20%) |
| `--help, -h` | Shows help |

### Examples

```bash
# Fully automatic backup for cron
./docker_backup.sh --auto

# Test without changes
./docker_backup.sh --dry-run

# Only container restart (e.g., after updates)
./docker_backup.sh --skip-backup --auto

# Backup without verification (faster)
./docker_backup.sh --auto --no-verify

# Fast backup with 'stop' instead of 'down'
./docker_backup.sh --auto --use-stop

# With ACL preservation for UGREEN NAS (if supported)
./docker_backup.sh --auto --preserve-acl

# Custom timeouts for large stacks
./docker_backup.sh --auto --timeout-stop 90 --timeout-start 180

# Parallel backup with more memory buffer
./docker_backup.sh --auto --parallel 4 --buffer-percent 30

# High-performance setup for large installations
./docker_backup.sh --auto --use-stop --parallel 8 --timeout-stop 45 --buffer-percent 25

# Fully automatic backup with all new features
./docker_backup.sh --auto --preserve-acl --parallel 4 --buffer-percent 15 --timeout-stop 90

# NEW in Version 3.5.1: SAFE with parallelization (critical fixes implemented)
./docker_backup.sh --auto --parallel 4 --use-stop --buffer-percent 20

# NEW in Version 3.5.1: test rsync fixes
./test_rsync_fix.sh
```

### New Test Tools (Version 3.5.1)

```bash
# Test rsync fixes in isolation (recommended before first backup)
./test_rsync_fix.sh

# Expected output:
# === RSYNC FIX VALIDATION TEST ===
# ✅ RSYNC FIXES WORK!
# Working flags: -a --delete --progress --stats --info=progress2
# === TEST COMPLETED ===
```

## How it works

### Step 1: Stop containers
- Automatic detection of all Docker stacks in `/volume1/docker-nas/stacks/`
- **Selectable shutdown**: `docker compose down` (default) or `docker compose stop` (with `--use-stop`)
- **Extended container status formatting**: Colored symbols for container actions
  - ▶ Container started (green)
  - ⏸ Container stopped (yellow)
  - 🗑 Container removed (red)
  - 📦 Container created (blue)
- Robust array handling for stack names with special characters
- Tracking which containers were running

### Step 2: Create backup
- Consistent backup with `rsync`
- Source: `/volume1/docker-nas/`
- Target: `/volume2/backups/docker-nas_backups/`
- Incremental backup with `--delete` option

### Step 3: Start containers
- All stacks are started with `docker compose up -d`
- **Signal handler**: Automatic recovery even on script abort (CTRL+C)
- Automatic recovery even on backup errors

## Configuration

The most important paths can be adjusted in the script:

```bash
DATA_DIR="/path/to/your/docker/data"
STACKS_DIR="/path/to/your/docker/stacks"
BACKUP_SOURCE="/path/to/your/docker"
BACKUP_DEST="/path/to/your/backup/destination"
LOG_DIR="/path/to/your/logs"
```

## Cron Automation

For regular backups, you can set up a cron job:

```bash
# Edit crontab
crontab -e

# Example: Daily at 2:00 AM (fast with --use-stop)
0 2 * * * /path/to/docker_backup.sh --auto --use-stop >> /path/to/logs/cron_backup.log 2>&1

# Example: Weekly on Sundays at 3:00 AM (complete with down)
0 3 * * 0 /path/to/docker_backup.sh --auto >> /path/to/logs/cron_backup.log 2>&1

# NEW Version 3.5.1: SAFE parallelization for cron (critical fixes implemented)
0 2 * * * /path/to/docker_backup.sh --auto --parallel 4 --use-stop --buffer-percent 20 >> /path/to/logs/cron_backup.log 2>&1

# Example: Run as root (automatic detection)
0 2 * * * /path/to/docker_backup.sh --auto --use-stop

# Example: With ACL support for NAS (if supported)
0 2 * * * /path/to/docker_backup.sh --auto --preserve-acl --timeout-stop 90

# Example: High-performance setup for large installations (Version 3.5.1+)
0 2 * * * /path/to/docker_backup.sh --auto --parallel 6 --use-stop --buffer-percent 25

# Example: Daily backup with safe parallelization (Version 3.5.1+)
0 2 * * * /path/to/docker_backup.sh --auto --preserve-acl --parallel 4 --buffer-percent 15 2>&1 | logger -t docker_backup

# Example: Weekly complete backup (Sundays at 1:00)
0 1 * * 0 /path/to/docker_backup.sh --auto --preserve-acl --parallel 2 --timeout-stop 120 2>&1 | logger -t docker_backup_weekly
```

## Logging

All actions are logged:
- Log files: `/path/to/your/logs/docker_backup_YYYYMMDD_HHMMSS.log`
- Detailed information about each step
- Error handling and warnings

## Security Features

### Environment Validation
- Checks Docker availability
- Validates critical directories
- Checks disk space
- **Intelligent sudo handling**: Works as root or normal user

### Error Handling
- **Fail-fast**: Script aborts immediately on unhandled errors
- **Intelligent signal handler**: Distinguishes between normal exit and abort
- **Configurable timeouts**: Adjustable container stop/start times
- **Complete input validation**: All parameters with range checking (Version 3.4)
- Containers are always restarted (even on backup errors)
- **ANSI-cleaned logs**: No color codes in log files
- **Bulletproof parallelization**: Start + stop support 1-16 parallel jobs (Version 3.4)
- **Cron-safe execution**: Optimized PATH order for cron environments (Version 3.4.1)
- **Secure log files**: 600 permissions and correct owner assignment (Version 3.4)
- **ACL tool compatibility**: Automatic check for `setfacl` availability (Version 3.4.1)
- **Robust stack names**: NULL-byte delimiter for safe special character handling (Version 3.4.2)
- **BusyBox compatibility**: Automatic numfmt fallback for lean systems (Version 3.4.2)
- Detailed error logging
- Robust exit codes for automation

### Backup Verification
- Size comparison between source and backup
- **File/directory count comparison** for structural integrity
- **ACL/xattr support** for UGREEN NAS (optional, if filesystem supports)
- **Configurable memory buffer**: Adjustable from 10-100% for safe backups (Version 3.4.3)
- **Race-condition-free ACL tests**: Unique filenames (Version 3.4)
- **Intelligent ACL detection**: Check for tool availability before use (Version 3.4.1)
- **Universal byte formatting**: Automatic fallback without numfmt dependency (Version 3.4.2)
- **Optimized parallelization**: Corrected variable handling in sub-shells (Version 3.4.3)
- **Performance-optimized logs**: Removed human-readable formatting for better speed (Version 3.4.3)
- **Shell-agnostic robustness**: Explicit SUDO_CMD export for maximum compatibility (Version 3.4.4)
- Warning on deviations > 5%
- Optionally disableable with `--no-verify`

## Best Practices

1. **🚨 UPGRADE TO VERSION 3.5.1** - Critical security fixes for parallelization
2. **Test first with --dry-run**
3. **Monitor the first runs** manually
4. **Check logs regularly**
5. **Test backup restoration** occasionally
6. **Keep enough free disk space** (at least 120% of source size)
7. **🔒 Use parallelization safely** - Only with Version 3.5.1 or higher

### 🚨 CRITICAL SECURITY WARNING
**Versions before 3.5.1 have critical bugs with `--parallel N>1`:**
- ❌ **Silent backup failure** without error message
- ❌ **Duplicate cron execution** possible
- ❌ **Log race conditions** in parallel jobs

**➜ IMMEDIATELY upgrade to Version 3.5.1 for safe parallelization!**

## Troubleshooting

### Containers won't start
```bash
# Check container status
docker ps -a

# Check logs of a specific container
docker logs <container_name>

# Manual start of a stack
cd /volume1/docker-nas/stacks/<stack_name>
sudo docker compose up -d
```

### Backup errors
```bash
# Check disk space
df -h /volume2

# Check permissions
ls -la /volume2/backups/

# Test manual backup
sudo rsync -avh --dry-run /volume1/docker-nas/ /volume2/backups/docker-nas_backups/
```

### Log analysis
```bash
# Show latest log file
tail -f /volume1/docker-nas/logs/docker_backup_*.log

# Search for errors in logs
grep -i error /volume1/docker-nas/logs/docker_backup_*.log
```

## Integration with existing backup tools

The script can be combined with existing backup tools:

```bash
# After local backup, perform remote backup
./docker_backup.sh --auto && ./do_backup.sh --auto
```

## Maintenance

### Log rotation
```bash
# Delete old logs (older than 30 days)
find /volume1/docker-nas/logs/ -name "docker_backup_*.log" -mtime +30 -delete
```

### Backup cleanup
```bash
# Manually check and delete old backups
ls -la /volume2/backups/docker-nas_backups/
```

---

## Advanced Features

### Performance Optimization

#### Using parallelization (Version 3.5.1+):
```bash
# For small systems (2-4 containers):
./docker_backup.sh --parallel 2

# For medium systems (5-10 containers):
./docker_backup.sh --parallel 4

# For large systems (10+ containers):
./docker_backup.sh --parallel 8
```

#### Fast backups:
```bash
# Fastest mode (for daily backups):
./docker_backup.sh --auto --use-stop --parallel 4 --no-verify

# Balanced mode (recommended):
./docker_backup.sh --auto --parallel 2 --buffer-percent 15
```

### Advanced Configuration

#### Adjusting timeouts:
```bash
# For slow containers (databases):
./docker_backup.sh --timeout-stop 180 --timeout-start 300

# For fast containers:
./docker_backup.sh --timeout-stop 30 --timeout-start 60
```

#### Memory management:
```bash
# Conservative mode (more memory buffer):
./docker_backup.sh --buffer-percent 30

# Aggressive mode (less buffer):
./docker_backup.sh --buffer-percent 10
```

---

## Backup Encryption

### Backup Encryption Basics

The script creates unencrypted backups. For encryption, use external GPG pipelines after backup completion as shown below.

### Creating encrypted backup

#### Step 1: Perform normal backup
```bash
# First create normal backup
./docker_backup.sh --auto
```

#### Step 2: Encrypt backup
```bash
# Create encrypted backup (with password prompt)
tar -czf - /volume2/@home/florian/Backups/docker-nas-backup-rsync/ | \
gpg --symmetric --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 \
--s2k-digest-algo SHA512 --s2k-count 65011712 --force-mdc \
> /volume2/@home/florian/Backups/docker-backup-encrypted_$(date +%Y%m%d_%H%M%S).tar.gz.gpg
```

#### Step 3: Delete unencrypted backup (optional)
```bash
# Only if encrypted backup was created successfully
rm -rf /volume2/@home/florian/Backups/docker-nas-backup-rsync/
```

### Restoring encrypted backup

#### Step 1: Stop containers
```bash
./docker_backup.sh --skip-backup --auto  # Only stops containers
```

#### Step 2: Decrypt and restore backup
```bash
# Decrypt and restore directly
gpg --decrypt /volume2/@home/florian/Backups/docker-backup-encrypted_YYYYMMDD_HHMMSS.tar.gz.gpg | \
tar -xzf - -C /

# Or first decrypt, then restore
gpg --decrypt /volume2/@home/florian/Backups/docker-backup-encrypted_YYYYMMDD_HHMMSS.tar.gz.gpg \
> /tmp/backup_decrypted.tar.gz
tar -xzf /tmp/backup_decrypted.tar.gz -C /
rm /tmp/backup_decrypted.tar.gz
```

#### Step 3: Start containers
```bash
./docker_backup.sh --skip-backup --auto  # Only starts containers
```

### Automated encrypted backups

#### Create password file securely:
```bash
# Password file with secure permissions
echo "YOUR_VERY_SECURE_PASSWORD" | sudo tee /volume1/docker-nas/.backup_password
sudo chmod 600 /volume1/docker-nas/.backup_password
sudo chown root:root /volume1/docker-nas/.backup_password
```

#### Cron job for encrypted backups:
```bash
# Edit crontab
sudo crontab -e

# Daily encrypted backup at 2:00 AM
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto && \
tar -czf - /volume2/@home/florian/Backups/docker-nas-backup-rsync/ | \
gpg --symmetric --cipher-algo AES256 --passphrase-file /volume1/docker-nas/.backup_password \
> /volume2/@home/florian/Backups/docker-backup-encrypted_$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz.gpg && \
rm -rf /volume2/@home/florian/Backups/docker-nas-backup-rsync/
```

### Security best practices for encryption

1. **Use strong passwords** (at least 20 characters, mixed)
2. **Store password file securely** (600 permissions, root-owned)
3. **Test encrypted backups** (regular restoration tests)
4. **Rotate old encrypted backups** (automatic cleanup)
5. **Password backup** (store securely in another location)

---

## FAQ

### General Questions

#### How long does a backup take?
This depends on the amount of data:
- First backup: 1-5 minutes per GB
- Follow-up backups: 10-30 seconds (only changes)
- Example: 10 GB → First time 20 min, then 30 sec

#### Can I abort the script during a running backup?
Yes! The script has a signal handler:
- CTRL+C → Containers are automatically started
- Kill signal → Cleanup is executed
- Never just close the terminal!

#### What happens if a container doesn't start?
The script:
- ✅ Logs the error
- ✅ Tries to start other containers
- ✅ Gives detailed error message
- ✅ Exit code shows problem

#### Can I exclude individual containers from backup?
Yes, several possibilities:
1. Temporarily rename stack directory
2. Temporarily rename docker-compose.yml
3. Modify script (for experts)

### Technical Questions

#### Why are containers stopped? Can't this be done without?
Container stop is necessary for:
- ✅ **Consistency**: No running write operations
- ✅ **Integrity**: Databases are consistent
- ✅ **Completeness**: All files are available
- ❌ Live backup would be inconsistent and unreliable

#### What's the difference between 'stop' and 'down'?
- `docker compose stop`: Stops containers, keeps networks
- `docker compose down`: Stops containers, removes networks
- **Recommendation**: `down` for complete cleanup (default)
- **Alternative**: `--use-stop` for faster restart

#### How does parallelization work?
The script can stop/start multiple containers simultaneously:
- `--parallel 1`: Serial (default, safe)
- `--parallel 4`: 4 containers simultaneously (faster)
- **Advantage**: Significantly faster with many containers
- **Disadvantage**: Higher system load

#### What does rsync do exactly?
rsync creates incremental backups:
- **First execution**: Copies everything
- **Follow-up executions**: Only changes
- `--delete`: Removes files that were deleted in source
- **Result**: Backup is exact copy of source

### Customization Questions

#### Can I use the script for other directories?
Yes! Simply change the paths in the script:
```bash
# For any Docker installation:
DATA_DIR="/your/path/data"
STACKS_DIR="/your/path/stacks"
BACKUP_SOURCE="/your/path"
BACKUP_DEST="/backup/target"
```

#### Does the script work on Synology/QNAP?
Yes! With path adjustments:
- **Synology**: `/volume1/docker/` → `/volume1/docker/`
- **QNAP**: `/share/Container/` → `/share/Container/`
- **Important**: Docker must be installed

#### Can I have multiple backup targets?
Yes, several possibilities:
1. Run script multiple times with different targets
2. Copy to additional targets with rsync after backup
3. Extend script (for experts)

### Emergency Questions

#### Backup failed, what now?
Step-by-step diagnosis:

1. **Check log file:**
   ```bash
   tail -50 /volume1/docker-nas/logs/docker_backup_*.log
   ```

2. **Common errors:**
   - `Docker is not available` → `sudo systemctl start docker`
   - `Not enough disk space` → Check backup target
   - `Permission denied` → Check permissions

3. **Start containers manually:**
   ```bash
   find /volume1/docker-nas/stacks -name "docker-compose.yml" -execdir docker compose up -d \;
   ```

#### Which version do I have?
Check version in script:
```bash
head -10 docker_backup.sh | grep "Version"
# Should show: Version 3.5.1