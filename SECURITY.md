# Security Policy

## Supported Versions

We actively support the following versions with security updates:

| Version | Supported          | Security Status |
| ------- | ------------------ | --------------- |
| 3.4.9   | ✅ Yes             | Current stable  |
| 3.4.8   | ⚠️ Upgrade required | Critical fixes available |
| 3.4.7   | ⚠️ Upgrade required | Critical fixes available |
| < 3.4.7 | ❌ No              | End of support  |

## Critical Security Notice

**⚠️ IMPORTANT**: Versions prior to 3.4.9 contain critical security vulnerabilities when using parallel operations (`--parallel N>1`). These vulnerabilities can lead to:

- Silent backup failures without error notification
- Race conditions in concurrent operations
- Potential data integrity issues
- Unauthorized concurrent executions

**Immediate action required**: Upgrade to version 3.4.9 or later if you use parallel operations.

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow responsible disclosure practices:

### 🔒 Private Reporting (Preferred)

For security vulnerabilities, please **DO NOT** create a public GitHub issue. Instead:

1. **Email**: Send details to [security@your-domain.com] (replace with actual email)
2. **Subject**: `[SECURITY] Docker NAS Backup Script - [Brief Description]`
3. **Include**:
   - Detailed description of the vulnerability
   - Steps to reproduce the issue
   - Potential impact assessment
   - Suggested fix (if available)
   - Your contact information for follow-up

### 📋 Information to Include

When reporting a security vulnerability, please provide:

```
**Vulnerability Type**: [e.g., Race condition, Input validation, Privilege escalation]
**Affected Versions**: [e.g., 3.4.8 and earlier]
**Attack Vector**: [e.g., Local, Remote, Physical access required]
**Severity**: [Critical/High/Medium/Low]

**Description**:
[Detailed description of the vulnerability]

**Reproduction Steps**:
1. Step 1
2. Step 2
3. Step 3

**Impact**:
[What could an attacker achieve?]

**Suggested Fix**:
[If you have ideas for fixing the issue]

**Environment**:
- OS: [e.g., Ubuntu 22.04]
- Script Version: [e.g., 3.4.8]
- Docker Version: [e.g., 24.0.5]
```

### 🕐 Response Timeline

We aim to respond to security reports according to the following timeline:

- **Initial Response**: Within 48 hours
- **Vulnerability Assessment**: Within 1 week
- **Fix Development**: Within 2 weeks (for critical issues)
- **Public Disclosure**: After fix is released and users have time to update

### 🏆 Security Researcher Recognition

We appreciate security researchers who help improve our project's security:

- **Hall of Fame**: Security researchers will be credited in our security acknowledgments
- **CVE Assignment**: We will work with you to obtain CVE numbers for significant vulnerabilities
- **Coordinated Disclosure**: We support responsible disclosure timelines

## Security Best Practices

### For Users

1. **Keep Updated**: Always use the latest version
2. **Validate Downloads**: Verify checksums when downloading releases
3. **Secure Configuration**: 
   - Use appropriate file permissions (600 for logs, 700 for scripts)
   - Limit sudo access to necessary users only
   - Regularly review cron job configurations
4. **Monitor Logs**: Regularly check backup logs for anomalies
5. **Test Backups**: Regularly verify backup integrity and restoration procedures

### For Developers

1. **Input Validation**: All user inputs must be validated and sanitized
2. **Privilege Minimization**: Use minimum required privileges
3. **Race Condition Prevention**: Ensure atomic operations and proper locking
4. **Error Handling**: Fail securely and don't leak sensitive information
5. **Code Review**: All security-related changes require thorough review

## Known Security Considerations

### Current Security Features

- **Fail-Fast Design**: `set -euo pipefail` prevents silent failures
- **Input Validation**: All parameters are validated with range checking
- **Atomic Locking**: PID/lock files prevent concurrent executions
- **Signal Handling**: Proper cleanup on interruption
- **Privilege Handling**: Secure sudo usage with validation
- **Log Security**: ANSI-free logs with restricted permissions

### Areas of Security Focus

1. **Parallel Operations**: Thread-safe execution with proper synchronization
2. **File Operations**: Race-condition-free temporary file handling
3. **Command Injection**: Proper escaping and validation of all inputs
4. **Privilege Escalation**: Minimal and controlled sudo usage
5. **Information Disclosure**: Logs don't contain sensitive information

## Security Changelog

### Version 3.4.9 (2025-07-30) - Critical Security Release

**Fixed Critical Vulnerabilities:**
- **CVE-TBD-001**: Function export missing in parallel sub-shells causing silent failures
- **CVE-TBD-002**: Race conditions in log file access during parallel operations
- **CVE-TBD-003**: Missing atomic lock protection allowing concurrent executions
- **CVE-TBD-004**: Environment variables not exported to sub-shells
- **CVE-TBD-005**: Temporary directory collisions in rsync validation

**Security Improvements:**
- Added atomic lock protection with automatic cleanup
- Implemented thread-safe logging mechanisms
- Enhanced environment variable isolation
- Improved temporary file handling security

## Vulnerability Disclosure Policy

### Scope

This security policy covers:
- The main `docker_backup.sh` script
- Associated utility scripts (`test_rsync_fix.sh`)
- Documentation that could impact security
- Configuration recommendations

### Out of Scope

- Third-party dependencies (Docker, rsync, etc.)
- Operating system vulnerabilities
- Network security issues
- Physical security concerns

### Disclosure Timeline

1. **Day 0**: Vulnerability reported privately
2. **Day 1-2**: Initial response and acknowledgment
3. **Day 3-7**: Vulnerability assessment and impact analysis
4. **Day 8-14**: Fix development and testing
5. **Day 15**: Security release published
6. **Day 30**: Public disclosure (if agreed upon)

## Contact Information

- **Security Email**: [security@your-domain.com] (replace with actual)
- **PGP Key**: [Link to PGP public key if available]
- **GitHub**: Create a private security advisory for this repository

## Acknowledgments

We thank the following security researchers for their contributions:

- [Security Researcher Name] - [Vulnerability Description] - [Date]
- Community feedback and security analysis contributions

---

**Remember**: Security is a shared responsibility. Help us keep the Docker NAS Backup Script secure by following responsible disclosure practices and keeping your installations updated.