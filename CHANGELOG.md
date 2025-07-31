# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.5.7] - 2025-07-31 🎉 **INITIAL PUBLIC RELEASE**

**Welcome to the NAS Docker Backup Script** - A reliable solution for automated Docker container and data backup on NAS systems.

### ✨ **Core Features**

#### 🐳 **Smart Docker Management**
- **Automatic Discovery**: Finds all Docker Compose stacks automatically
- **Graceful Operations**: Safe container shutdown and intelligent restart
- **Parallel Processing**: Configurable parallel operations (1-16 jobs) for faster backups
- **Flexible Modes**: Choose between `docker compose stop` (fast) or `down` (complete cleanup)

#### 🛡️ **Security & Reliability**
- **Fail-Safe Design**: Comprehensive error handling with automatic recovery
- **Data Protection**: Advanced delete-guard checks prevent accidental data loss
- **Thread-Safe Operations**: Atomic lock protection prevents concurrent executions
- **Secure Permissions**: Proper file ownership and permission management

#### 📦 **Advanced Backup Technology**
- **rsync-Based**: Incremental synchronization with intelligent fallback mechanisms
- **Three-Tier Fallback**: Optimized → Minimal → Basic flags for maximum compatibility
- **ACL Support**: Optional preservation of ACLs and extended attributes
- **Smart Exclusions**: Automatic log directory exclusion to prevent backup bloat

#### 🌍 **Multi-Language Support**
- **English**: Complete `docker_backup.sh` with full documentation
- **German**: Fully localized `docker_backup_de.sh` experience
- **Bilingual Documentation**: Complete README, guides, and manuals

#### ⚡ **Performance & Optimization**
- **Fast Execution**: Optimized container operations and health checks
- **Configurable Timeouts**: Customizable stop/start timeouts for different systems
- **Memory Efficient**: Smart buffer management and resource usage
- **Clean Output**: Streamlined logging with essential information focus

### 🔧 **Technical Specifications**

#### **System Requirements**
- **OS**: Linux (Ubuntu 20.04+, Debian 11+, NAS systems)
- **Dependencies**: Docker Compose v2, rsync, bash 4.0+, flock
- **Permissions**: sudo access or root execution capability
- **Storage**: Sufficient space for backup destination

#### **Tested Platforms**
- ✅ **UGREEN NAS DXP2800** (Primary development platform)
- ✅ **Ubuntu 20.04+** (Fully tested)
- ✅ **Debian 11+** (Fully tested)
- 🔄 **Synology DSM** (Compatible, testing in progress)
- 🔄 **QNAP QTS** (Compatible, testing in progress)

#### **Key Improvements in v3.5.7**
- **Enhanced Initialization**: Optimized startup sequence for better reliability
- **POSIX Compliance**: Improved compatibility across different Linux distributions
- **Robust Health Checks**: Accurate container status detection
- **Code Quality**: Consistent parameter handling and better maintainability

### 📖 **Getting Started**

#### **Quick Installation**
```bash
# Download the script
git clone https://github.com/florian101010/NAS-Docker-Backup-rsync.git
cd NAS-Docker-Backup-rsync

# Configure paths (edit the script)
nano docker_backup.sh  # or docker_backup_de.sh for German

# Test configuration
./docker_backup.sh --dry-run

# Run backup
./docker_backup.sh --auto
```

#### **Available Options**
- `--auto`: Fully automatic execution without confirmation
- `--dry-run`: Test mode - shows what would be done without changes
- `--skip-backup`: Only restart containers (no backup creation)
- `--parallel N`: Use N parallel jobs for faster operations
- `--use-stop`: Use `docker compose stop` instead of `down`
- `--preserve-acl`: Backup ACLs and extended attributes

### 🛡️ **Security Features**
- **Delete-Guard Protection**: Prevents accidental source directory deletion
- **Path Validation**: Comprehensive checks against dangerous backup destinations
- **Dependency Validation**: Early checks for all required tools
- **Safe Cleanup**: Only restarts containers that were actually stopped
- **Thread-Safe Logging**: Concurrent operation support with file locking

### 📊 **Well-Tested & Reliable**
- **Comprehensive Testing**: Extensively tested on real NAS environments
- **Robust Error Handling**: Detailed exit code analysis and recovery
- **Backup Verification**: Automatic size and file count validation
- **Cron Compatible**: Perfect for automated scheduled backups
- **Clean Logging**: Clear output with detailed log files

### 🎯 **Perfect For**
- **Home Labs**: Personal Docker environments and development setups
- **Small Business**: Reliable backup solution for business-critical containers
- **NAS Users**: Optimized for Synology, QNAP, UGREEN, and custom NAS systems
- **Production Environments**: Reliable backup solution with comprehensive safety features

---

## [3.5.6] - 2025-07-31 🔧 **Pre-Release: Security Enhancements**

### 🔒 Security Improvements
- **Enhanced**: Fixed rsync pipeline abort with `set -e -o pipefail`
  - Prevents script termination before fallback attempts can execute
  - Wrapped rsync pipeline with `set +e`/`set -e` for safe exit code capture
  - **Impact**: Prevents silent backup failure when rsync returns non-zero exit codes

- **Improved**: Removed unbound variable `rsync_opts` causing crashes under `set -u`
  - Eliminated undefined variable reference that caused immediate script termination
  - **Impact**: Script now runs reliably without variable expansion errors

- **Fixed**: Exclude pattern quotes breaking log exclusion
  - Changed `--exclude '/logs/**'` to `--exclude=/logs/**` for proper rsync parsing
  - **Impact**: Log directory now properly excluded from backups, preventing growth

- **Added**: Hard delete-guard checks to prevent data loss
  - Enhanced path validation with `readlink -f` for absolute path resolution
  - Prevents `BACKUP_DEST` inside `BACKUP_SOURCE` (dangerous with `--delete`)
  - Blocks dangerous destinations like `/`, `/root`, `/home`
  - **Impact**: Prevents accidental source directory deletion with `rsync --delete`

### 🔧 High-Impact Improvements
- **Enhanced Dependency Validation**: Added preflight checks for `timeout` and `docker compose`
  - Comprehensive tool validation before any operations begin
  - Clear installation instructions for missing dependencies
  - **Impact**: Prevents confusing failures during backup execution

- **Improved Cleanup Safety**: Cleanup now only restarts stacks that were actually stopped
  - Added `start_specific_stacks()` helper function
  - Prevents unintended startup of manually stopped containers
  - **Impact**: Safer cleanup behavior respects user's container state

### 📝 Documentation Updates
- Removed all `jq` references from documentation (README, QUICKSTART, MANUAL)
- Updated system requirements to reflect actual dependencies
- Enhanced troubleshooting guides with new safety features

---

## [3.5.5] - 2025-07-31 🔧 **Pre-Release: Parallel Mode & Dependency Cleanup**

### Fixed
- **Parallel Mode Enhancement**: Fixed variable expansion in parallel processing
  - Variables like `$STACKS_DIR`, `$COMPOSE_TIMEOUT_STOP/START`, `$docker_cmd` were not expanded in sub-shells
  - Replaced unsafe single-quoted variable references with robust parameter passing
  - Used `bash -c '...' _ "$var1" "$var2"` pattern for safe variable expansion
  - Prevents silent failures in parallel mode (`PARALLEL_JOBS > 1`)
  - **Impact**: Parallel mode now works correctly instead of silently failing

- **Parallel Mode Color Variables**: Fixed "unbound variable" errors with `set -u`
  - Exported color variables (`GREEN`, `RED`, `YELLOW`, `BLUE`, `CYAN`, `NC`) for sub-shells
  - Prevents script termination when parallel jobs try to use color codes
  - Ensures consistent colored output in both serial and parallel modes

### Removed
- **Unnecessary jq Dependency**: Eliminated unused `jq` requirement
  - Removed preflight check for `jq` package installation
  - Health checks now use `docker compose ps` directly without JSON parsing
  - Reduces system requirements and installation complexity
  - **Impact**: Script works on systems without `jq` installed

### Enhanced
- **Improved rsync Flag Handling**: Unified and optimized backup flag management
  - Consolidated duplicate `rsync_opts` and `RSYNC_FLAGS` variables into single `RSYNC_FLAGS`
  - Added automatic log directory exclusion (`--exclude '/logs/**'`) to prevent backup growth
  - Individual ACL/xattr flag testing (`-A`, `-X`, `-H`) for better compatibility
  - Cleaner flag accumulation with `+=` operator instead of string concatenation
  - More robust fallback mechanism with consistent variable usage

### Technical
- **Robust Parameter Passing**: Enhanced parallel processing reliability
  - All parallel `xargs` blocks now use safe parameter passing
  - Prevents variable expansion issues in complex shell environments
  - Maintains thread safety while ensuring correct variable values
  - Consistent implementation across both stop and start operations

---

## [3.5.4] - 2025-07-31 🧹 **LOG OUTPUT CLEANUP & OPTIMIZATION**

### Improved
- **Cleaner Log Output**: Removed redundant and verbose logging messages
  - Eliminated repetitive DEBUG messages during healthcheck process
    - Removed `"Healthcheck: Prüfe Stack $stack_name..."` for each individual stack
    - Removed `"Healthcheck: Stack $stack_name - Total: $total_count, Running: $running_count"` per stack
  - Removed redundant INFO messages during stack discovery
    - Eliminated `"Erkenne Docker-Stacks in $STACKS_DIR..."` message
    - Removed verbose `"Gefundene Stacks: ${#ALL_STACKS[@]} (stack1 stack2 stack3...)"` listing
  - Streamlined output focuses on essential information only

### Enhanced
- **Optimized User Experience**: Significantly cleaner terminal output
  - Backup completion now shows clean, focused status information
  - Eliminated 22+ redundant DEBUG messages per backup run (one per stack)
  - Removed duplicate stack listing that was already shown in final summary
  - Faster visual parsing of backup results without information overload
  - All essential information preserved in compact final status overview

### Technical
- **Maintained Functionality**: All core features preserved
  - Complete container status information still available in final summary
  - Stack processing information retained in "CONTAINER-ÄNDERUNGEN" section
  - Healthcheck results fully displayed in consolidated status overview
  - Log files still contain all necessary information for troubleshooting
  - No impact on backup reliability or container management functionality

---

## [3.5.3] - 2025-07-31 🎯 **HEALTHCHECK & BACKUP STATISTICS ENHANCEMENT**

### Fixed
- **Healthcheck Enhancement**: Resolved missing healthcheck output at backup completion
  - Fixed empty `ALL_STACKS` array causing "⚠️ Keine Stacks für Healthcheck gefunden" message
  - Added explicit `discover_docker_stacks` call before healthcheck execution
  - Ensures reliable container status overview after every backup run
  - Eliminated silent healthcheck failures that left users without status information
  - **Enhanced Healthcheck Robustness**: Improved timeout handling and error recovery
    - Increased timeouts from 5s to 15s for 22 stacks compatibility
    - Removed temporary file dependencies for better reliability
    - Added fallback mechanisms using `docker inspect` for container status
    - Eliminated `--status running` flag for broader Docker version compatibility
    - Added comprehensive debug logging for troubleshooting
    - **Enhanced**: Added `set +e`/`set -e` error handling to prevent script termination
      - Prevents healthcheck from stopping after first stack due to `set -euo pipefail`
      - Ensures all stacks are processed even if individual Docker commands fail
      - Guarantees complete container status overview is displayed

- **Double Container Start Prevention**: Completely eliminated duplicate container startup cycles
  - Moved `trap - EXIT` deactivation before healthcheck to prevent cleanup loop
  - Prevents unintended `cleanup()` function execution during normal script completion
  - Eliminates confusing double "SCHRITT 3" execution in terminal output

### Enhanced
- **Backup Statistics Overview**: New comprehensive backup summary at completion
  - Added `show_backup_summary()` function with detailed backup metrics
  - Displays source vs backup file sizes (formatted with human-readable units)
  - Shows file and directory counts for source and backup locations
  - Integrated into status overview between container operations and healthcheck
  - Includes timeout protection (30s for size calculation, 20s for file counting)
  - Graceful fallback messages when calculations are unavailable

- **Robust Implementation**: Enhanced reliability and error handling
  - Timeout protection prevents hanging on large directory calculations
  - Thread-safe temporary file handling for concurrent operations
  - Automatic cleanup of temporary calculation files
  - Skips statistics display when `--skip-backup` option is used
  - Consistent implementation in both English and German scripts

### Technical
- **Improved Script Flow**: Optimized backup completion sequence
  - Healthcheck now guaranteed to execute with populated stack data
  - Clean separation between backup statistics and container health monitoring
  - Better user experience with comprehensive status information
  - Enhanced logging for troubleshooting and monitoring

---

## [3.5.2] - 2025-07-31 ⚡ **PERFORMANCE & STABILITY OPTIMIZATION**

### Performance Improvements
- **Health Check Optimization**: Dramatically improved backup script performance
  - Removed individual 30-second health checks after each container start
  - Implemented consolidated health check integrated into final status overview
  - Reduced execution time by 11+ minutes for 22 stacks (eliminated 30s × 22 = 11min timeout overhead)
  - Better user experience with faster container startup process
  - No more separate "STEP 4" - seamlessly integrated into final report

### Enhanced
- **Container Health Monitoring**: Robust and compact health check implementation
  - Compact health status summary with clear visual indicators
  - Stack-level and container-level statistics in one overview
  - Better error reporting without script termination
  - Health check only runs when containers are successfully started (not in dry-run mode)
  - Integrated into final status overview instead of separate step

### Fixed
- **Script Stability**: Eliminated stability issues
  - Fixed script termination caused by health check failures
  - Prevented cleanup loop that caused container restart cycles
  - Robust error handling with fail-safe design (`return 0` guarantee)
  - Safe JSON processing with fallback mechanisms for jq operations
  - Defensive programming prevents script abort on health check errors

### Technical
- **Script Efficiency**: Optimized container management workflow
  - Eliminated timeout issues during container startup
  - Allows containers more time to fully initialize before health validation
  - Maintains comprehensive health monitoring without performance penalty
  - Consistent implementation in both English and German scripts
  - New `perform_consolidated_health_check()` function with compact reporting
  - Fail-safe design ensures script always completes successfully

---

## [3.5.1] - 2025-07-31 


#### ✨ **Core Features**
- **Smart Docker Management**: Automatic container discovery, graceful shutdown, and intelligent restart
- **Safe Operations**: Thread-safe parallel processing with atomic lock protection
- **Advanced Backup Technology**: rsync-based incremental synchronization with intelligent fallback mechanisms
- **Security Features**: Fail-fast design, comprehensive validation, and secure permission handling
- **Multi-Language Support**: Complete English and German localization (scripts + documentation)
- **NAS Optimized**: Tested and optimized for UGREEN, Synology, QNAP, and custom Linux NAS systems

#### 🛡️ **Security & Reliability**
- Thread-safe logging with flock protection for parallel operations
- Backup source validation with delete-guard protection
- Automatic container recovery on script interruption (CTRL+C, kill signals)
- Secure log file permissions with proper owner assignment
- Input validation with range checking for parameters
- **Early dependency validation**: Preflight checks for `jq` and `flock` with clear error messages
- **Comprehensive documentation**: Updated README with complete dependency requirements and troubleshooting

#### ⚡ **Performance Features**
- Configurable parallel container operations (1-16 jobs) for faster backups
- Intelligent Docker command selection (`stop` vs `down`) for optimal performance
- Three-tier rsync fallback mechanism for maximum compatibility
- Configurable timeouts and storage buffers for different system requirements

#### 📖 **Documentation**
- Multi-language documentation (English/German)
- Installation guides and quick-start tutorials
- Cron automation examples for automated backups
- Troubleshooting guides and best practices

#### 🌍 **Multi-Language Support**
- **English**: `docker_backup.sh` with complete English documentation
- **German**: `docker_backup_de.sh` with fully localized German experience
- Bilingual README with professional language selection
- Localized test scripts and comprehensive documentation

#### 🔧 **Technical Specifications**
- **Requirements**: Linux, Bash 4.0+, Docker Compose v2, rsync, flock, jq
- **Tested Platforms**: Ubuntu, Debian, UGREEN NAS DXP2800 (to be tested: Synology, QNAP)
- **Backup Method**: rsync incremental synchronization (not snapshot-based)
- **ACL Support**: Optional ACL and extended attributes preservation (ext4/XFS/Btrfs/ZFS)
- **Dependency Management**: Automated validation with installation guidance for all required tools

#### 📊 **Well-Tested & Reliable**
- Robust error handling with detailed exit code analysis
- Backup verification (size, file count, integrity checks)
- Cron-safe automation with proper environment handling
- Clean logging with ANSI-free output
- **Enhanced UX**: Clear dependency validation prevents confusing error states
- **Reliable**: Fail-fast design with helpful installation guidance

#### 🆕 **Latest Improvements (v3.5.1)**
- **Enhanced Documentation**: Updated README with complete `jq` and `flock` requirements
- **Improved System Checks**: Extended one-line system validation in both English and German
- **Better Error Messages**: Clear dependency validation with distribution-specific installation commands
- **Preflight Validation**: Early checks prevent confusing "backup already running" messages when dependencies are missing
- **Troubleshooting Guide**: Added specific sections for dependency installation and validation
- **Smoke Tests**: Quick validation commands for `jq` and `flock` functionality

---

## Migration Guide

### First-Time Installation

1. **Download**: Get the latest release from GitHub
2. **Test Compatibility**: Run `./test_rsync_fix.sh` to verify system compatibility
3. **Configure**: Edit script paths for your NAS system
4. **Test**: Run `./docker_backup.sh --dry-run` to validate configuration
5. **Deploy**: Set up automated backups with cron

### System Requirements

- **Minimum**: Linux with Docker Compose v2, rsync, bash 4.0+
- **Recommended**: Modern NAS system with sufficient storage for backup destination
- **Permissions**: sudo access or root execution capability

### Compatibility

- **Fully Tested**: UGREEN NAS DXP2800, Ubuntu 20.04+, Debian 11+
- **Compatible**: (TBC) Synology DSM, QNAP QTS, custom Linux NAS systems
- **Optimized**: For environments with multiple Docker stacks

---

**🎯 Ready for Use**: This release represents a stable, well-tested solution suitable for home labs, small businesses, and environments where reliable Docker backups are needed.