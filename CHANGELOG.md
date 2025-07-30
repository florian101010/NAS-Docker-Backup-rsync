# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.4.9] - 2025-07-30

### 🚨 SECURITY FIXES

This release addresses critical security vulnerabilities that affect parallel operations. **Immediate upgrade required** for all users utilizing `--parallel N>1`.

#### Fixed
- **CRITICAL**: Function export missing in parallel sub-shells causing silent backup failures
- **CRITICAL**: Race conditions in log file access during parallel operations
- **CRITICAL**: Missing PID/lock file protection allowing concurrent executions
- **CRITICAL**: Environment variables not exported to sub-shells
- **CRITICAL**: Temp directory collisions in rsync flag validation

#### Added
- Atomic lock protection with `flock` for thread-safe execution
- Automatic lock file cleanup on normal and abnormal exit
- Complete environment variable export strategy for sub-shells
- Race-condition-free temporary directory creation using `mktemp -d`
- Thread-safe logging with direct log file access in parallel jobs

#### Security
- Prevents silent backup failures when using parallel operations
- Eliminates double execution in cron environments
- Ensures formatted container status output in parallel jobs
- Provides collision-free temporary file handling

## [3.4.8] - 2025-07-30

### Added
- Robust rsync flag validation with real functionality testing
- Three-tier fallback mechanism for rsync compatibility
- Enhanced terminal output with color-coded container status
- New `test_rsync_fix.sh` tool for isolated rsync validation
- Improved array-based rsync execution for complex flags

### Changed
- Replaced unreliable `grep`-based flag detection with actual rsync tests
- Enhanced container status formatting with visual indicators
- Optimized debug output and error handling for rsync operations

### Fixed
- Automatic fallback from `--info=progress2` to `--progress` for older rsync versions
- Proper handling of flags with equals signs in rsync commands
- Improved path validation and automatic target directory creation

## [3.4.7] - 2025-07-30

### Added
- Complete UGREEN NAS DXP2800 compatibility
- Optimized terminal output with structured, color-coded display
- Enhanced container status indicators with emoji symbols
- Improved stack name highlighting and visual organization

### Changed
- Refined terminal color scheme for better readability
- Structured output format with consistent indentation
- Enhanced error message formatting and clarity

### Fixed
- Terminal output optimization for various NAS systems
- Consistent color handling across different terminal types

## [3.4.6] - 2025-07-30

### Fixed
- **CRITICAL**: Array-based rsync execution bug causing parameter passing failures
- Dynamic flag validation for improved rsync compatibility
- String expansion issues in rsync parameter handling

## [3.4.5] - 2025-07-30

### Added
- Full UGREEN NAS DXP2800 compatibility
- Universal `--progress` flag support for older rsync versions

### Fixed
- Docker Compose ANSI handling for older versions
- Removed `--ansi never` flag for broader compatibility
- Replaced `--info=progress2` with universal `--progress` flag

## [3.4.4] - 2025-07-30

### Added
- Explicit `SUDO_CMD` export for maximum sub-shell compatibility
- Shell-agnostic robustness improvements
- Defensive programming enhancements for variable availability

### Fixed
- Potential variable availability issues in different shell environments
- Enhanced sub-shell compatibility across various Linux distributions

## [3.4.3] - 2025-07-30

### Fixed
- **CRITICAL**: Sub-shell variable handling in parallel operations
- Performance optimization by removing `-h` flag from rsync
- Increased minimum storage buffer from 5% to 10% for safety

### Security
- Improved memory management with safer storage buffer requirements
- Enhanced parallel operation stability

## [3.4.2] - 2025-07-30

### Fixed
- **CRITICAL**: NULL-byte delimiter implementation for stack names with special characters
- BusyBox/Alpine compatibility with automatic `numfmt` fallback
- Clean `SUDO_CMD` handling eliminating double spaces in output

### Added
- New `format_bytes()` function with automatic fallback for systems without GNU coreutils
- Robust special character handling in stack names
- Improved portability across Linux distributions

## [3.4.1] - 2025-07-30

### Security
- PATH security optimization (append instead of prepend)
- ACL tool availability checking before usage

### Added
- Robust stack name handling with proper escaping
- Enhanced logging consistency and error handling
- Improved compatibility checks for ACL tools

### Fixed
- Eliminated "command not found" logs on systems without ACL support
- Clean command output without cosmetic spacing issues
- Consistent ANSI escape sequence removal

## [3.4.0] - 2025-07-30

### Added
- Complete help text documentation for all command-line flags
- Actual storage buffer percentage usage in space calculations
- Comprehensive input validation with range checking for all numeric parameters
- Parallel container start operations matching stop functionality
- Cron-safe PATH configuration with automatic export
- Secure log file permissions (600) with proper owner assignment
- Race-condition-free ACL testing with unique filenames

### Fixed
- Eliminated duplicate exit logs (cleanup only on errors)
- Corrected parallel operation logic with exit-status-based detection
- Proper container counting in parallel operations

### Changed
- Enhanced error handling with single, clean exit logging
- Improved parallel job tracking and status reporting

## [3.3.0] - 2025-07-30

### Added
- Configurable storage buffer with `--buffer-percent` flag
- Parallel container operations with `--parallel` flag (1-16 jobs)
- Enhanced color handling (colors only for terminal output)
- Comprehensive numeric parameter validation
- Idempotent trap deactivation for clean exits

### Changed
- Improved input validation for all configurable parameters
- Enhanced parallel processing capabilities for large installations

## [3.2.0] - 2025-07-30

### Added
- Early log file initialization before first log messages
- Complete ANSI code removal from all Docker outputs in log files
- Numeric value validation for timeout parameters
- Automatic ACL fallback for unsupported filesystems
- Optimized cleanup handling without duplicate logs

### Fixed
- Log file creation timing issues
- ANSI escape sequences in log files
- ACL support detection and graceful degradation

## [3.1.0] - 2025-07-30

### Added
- Unified logging function with ANSI-free log file output
- Enhanced trap handling distinguishing normal exit from signals/errors
- Configurable timeouts with `--timeout-stop` and `--timeout-start` flags
- ACL and extended attributes support with `--preserve-acl` flag
- ANSI-free Docker logs with `--ansi never` flag

### Changed
- Improved signal handling and cleanup procedures
- Enhanced container timeout management
- Better support for Synology and advanced NAS systems

## [3.0.0] - 2025-07-30

### Added
- Fail-fast settings with `set -euo pipefail` for maximum robustness
- Comprehensive signal handling with automatic container recovery
- Robust stack detection with safe array handling for special characters
- Intelligent Docker command selection (`stop` vs `down`)
- Global exit code management avoiding bash variable collisions
- sudo optimization with single privilege check

### Changed
- **BREAKING**: Enhanced error handling may catch previously ignored issues
- Improved container management with intelligent operation modes
- Enhanced security with fail-fast error detection

### Security
- Automatic container restart on script interruption (CTRL+C, kill)
- Robust privilege handling for both root and regular user execution
- Safe handling of stack names containing special characters

## [2.0.0] - 2025-07-30

### Added
- Enhanced error handling with start failure tracking in `FAILED_STACKS`
- Dynamic user detection with automatic backup permission assignment
- Detailed rsync exit code analysis with specific error messages
- Extended backup verification comparing both size and file/directory counts
- Secure log files with temporary umask adjustment

### Changed
- **BREAKING**: Improved error tracking may reveal previously hidden issues
- Enhanced backup verification process with comprehensive checks
- Better permission management for backup destinations

### Security
- Improved log file security with restricted permissions
- Enhanced backup integrity verification

---

## Migration Guide

### Upgrading to 3.4.9 (Critical)

**⚠️ REQUIRED**: This upgrade fixes critical security vulnerabilities in parallel operations.

1. **Immediate Action Required**: Stop using `--parallel N>1` with versions prior to 3.4.9
2. **Backup Current Setup**: Ensure you have working backups before upgrading
3. **Test After Upgrade**: Run `./docker_backup.sh --dry-run --parallel 2` to verify functionality
4. **Update Cron Jobs**: Safe to use parallel operations in automated scripts after upgrade

### Breaking Changes

- **v3.0.0**: Enhanced error handling may catch previously ignored issues
- **v2.0.0**: Improved error tracking may reveal previously hidden container problems

### Compatibility

- **Minimum Requirements**: Bash 4.0+, Linux with Docker and rsync
- **Tested Platforms**: Ubuntu, Debian, UGREEN NAS DXP2800, Synology, QNAP
- **Recommended**: Latest version for all security fixes and performance improvements