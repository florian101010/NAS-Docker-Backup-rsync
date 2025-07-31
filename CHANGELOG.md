# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.5.3] - 2025-07-31 🎯 **HEALTHCHECK & BACKUP STATISTICS ENHANCEMENT**

### Fixed
- **Critical Healthcheck Issue**: Resolved missing healthcheck output at backup completion
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
    - **CRITICAL FIX**: Added `set +e`/`set -e` error handling to prevent script termination
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
- **Script Stability**: Eliminated critical stability issues
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

## [3.5.1] - 2025-07-31 🎉 **INITIAL PUBLIC RELEASE**

This is the first public release of the NAS Docker Backup Script - a production-ready, enterprise-grade solution for automated Docker container and data backup on NAS systems.

#### ✨ **Core Features**
- **Smart Docker Management**: Automatic container discovery, graceful shutdown, and intelligent restart
- **Production-Safe Operations**: Thread-safe parallel processing with atomic lock protection
- **Advanced Backup Technology**: rsync-based incremental synchronization with intelligent fallback mechanisms
- **Enterprise Security**: Fail-fast design, comprehensive validation, and secure permission handling
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
- **Production-ready**: Fail-fast design with helpful installation guidance

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
- **Optimized**: For production environments with multiple Docker stacks

---

**🎯 Ready for Use**: This release represents a stable, well-tested solution suitable for home labs, small businesses, and production environments where reliable Docker backups are needed.