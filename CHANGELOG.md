# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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