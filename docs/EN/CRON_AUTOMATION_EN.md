# Docker Backup Script - Cron Automation

## Table of Contents

- [Overview](#overview)
- [Cron Basics](#cron-basics)
- [Preparation for Cron](#preparation-for-cron)
- [Cron Job Configuration](#cron-job-configuration)
- [Backup Strategies](#backup-strategies)
- [Logging and Monitoring](#logging-and-monitoring)
- [Security Aspects](#security-aspects)
- [Troubleshooting](#troubleshooting)
- [Advanced Configurations](#advanced-configurations)
- [Best Practices](#best-practices)

---

## Overview

Automating the Docker Backup Script with Cron enables regular, unattended backups of your Docker containers and data. This document explains all aspects of Cron integration in detail.

### Why Cron Automation?

- **Reliability**: Backups run automatically, even when you're not there
- **Consistency**: Regular backup cycles without human error
- **Flexibility**: Different backup strategies for different times
- **Security**: Minimizes the risk of data loss from forgotten backups

---

## Cron Basics

### What is Cron?

Cron is a time-based job scheduler in Unix-like operating systems. It automatically executes commands at specified times.

### Understanding Cron Syntax

```
* * * * * command
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, 0 and 7 = Sunday)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
```

### Cron Syntax Examples

| Cron Expression | Meaning |
|-----------------|---------|
| `0 2 * * *` | Daily at 2:00 AM |
| `30 1 * * 0` | Sundays at 1:30 AM |
| `0 */6 * * *` | Every 6 hours |
| `15 14 1 * *` | 1st of every month at 2:15 PM |
| `0 22 * * 1-5` | Monday to Friday at 10:00 PM |

### Special Cron Expressions

| Expression | Meaning |
|------------|---------|
| `@reboot` | At system startup |
| `@yearly` | Once per year (0 0 1 1 *) |
| `@monthly` | Once per month (0 0 1 * *) |
| `@weekly` | Once per week (0 0 * * 0) |
| `@daily` | Once daily (0 0 * * *) |
| `@hourly` | Once hourly (0 * * * *) |

---

## Preparation for Cron

### 1. Prepare Script Paths

```bash
# Copy script to fixed location
sudo cp docker_backup.sh /usr/local/bin/docker_backup.sh
sudo chmod +x /usr/local/bin/docker_backup.sh

# Or keep in current directory
chmod +x /path/to/docker_backup.sh
```

### 2. Test Environment Variables

Cron runs with minimal environment. Test the script:

```bash
# Simulate cron-like environment
env -i HOME="$HOME" PATH="/usr/bin:/bin" /path/to/docker_backup.sh --dry-run
```

### 3. Check Permissions

```bash
# Script permissions
ls -la /path/to/docker_backup.sh
# Should be: -rwxr-xr-x or -rwx------

# Log directory permissions
ls -ld /path/to/logs/
# Should be: drwxr-xr-x or drwx------

# Backup target permissions
ls -ld /path/to/backup/destination/
# Should be: drwxr-xr-x or drwx------
```

### 4. Sudo Configuration (if required)

For passwordless sudo (recommended for Cron):

```bash
# Edit sudoers file
sudo visudo

# Add (replace 'username' with your username):
username ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose, /usr/bin/rsync
```

---

## Cron Job Configuration

### Edit Crontab

```bash
# For current user
crontab -e

# For root (if required)
sudo crontab -e

# Show crontab
crontab -l
```

### Basic Cron Jobs

#### Daily Backup

```bash
# Daily at 2:00 AM - Fast backup
0 2 * * * /path/to/docker_backup.sh --auto --use-stop

# Daily at 3:00 AM - Complete backup
0 3 * * * /path/to/docker_backup.sh --auto
```

#### Weekly Backup

```bash
# Sundays at 1:00 AM - Complete backup with ACL
0 1 * * 0 /path/to/docker_backup.sh --auto --preserve-acl
```

#### Multi-Backup Strategy

```bash
# Daily fast backup (Monday-Saturday)
0 2 * * 1-6 /path/to/docker_backup.sh --auto --use-stop --parallel 4

# Sundays complete backup
0 1 * * 0 /path/to/docker_backup.sh --auto --preserve-acl --parallel 2
```

---

## Backup Strategies

### Strategy 1: Simple Daily Backups

**Suitable for**: Small to medium installations

```bash
# Crontab entry
0 2 * * * /path/to/docker_backup.sh --auto --use-stop >> /path/to/logs/cron_backup.log 2>&1
```

**Advantages**:
- Easy to understand and maintain
- Consistent backup times
- Low maintenance effort

**Disadvantages**:
- No differentiation between weekdays
- Always same backup depth

### Strategy 2: Differentiated Backup Cycles

**Suitable for**: Medium to large installations

```bash
# Monday-Friday: Fast backups
0 2 * * 1-5 /path/to/docker_backup.sh --auto --use-stop --parallel 4 --buffer-percent 15

# Saturday: Backup with verification
0 1 * * 6 /path/to/docker_backup.sh --auto --parallel 2 --buffer-percent 25

# Sunday: Complete backup with ACL
0 0 * * 0 /path/to/docker_backup.sh --auto --preserve-acl --parallel 2 --timeout-stop 120
```

**Advantages**:
- Optimized for different requirements
- Weekend for intensive backups
- Flexible resource usage

### Strategy 3: High-Frequency Backups

**Suitable for**: Critical production environments

```bash
# Every 6 hours: Fast backups
0 */6 * * * /path/to/docker_backup.sh --auto --use-stop --parallel 6 --no-verify

# Daily at 2:00: Complete backup
0 2 * * * /path/to/docker_backup.sh --auto --parallel 4 --buffer-percent 20

# Weekly: Backup with ACL and encryption
0 1 * * 0 /path/to/docker_backup.sh --auto --preserve-acl && /path/to/encrypt_backup.sh
```

**Advantages**:
- Minimal data loss on failures
- Multiple backup levels
- High availability

**Disadvantages**:
- Higher system load
- More storage space required
- More complex maintenance

### Strategy 4: Encrypted Backups

**Suitable for**: Security-critical environments

```bash
# Daily encrypted backup
0 2 * * * /path/to/docker_backup.sh --auto --parallel 4 && tar -czf - /path/to/backup/destination/ | gpg --symmetric --cipher-algo AES256 --passphrase-file /path/to/.backup_password > /path/to/backup/destination/docker-backup-encrypted_$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz.gpg && rm -rf /path/to/backup/destination/

# Weekly cleanup of old encrypted backups
0 3 * * 0 find /path/to/backup/destination/ -name "docker-backup-encrypted_*.tar.gz.gpg" -mtime +30 -delete
```

---

## Logging and Monitoring

### Logging Configuration

#### Standard Logging

```bash
# Simple logging to file
0 2 * * * /path/to/docker_backup.sh --auto >> /path/to/logs/cron_backup.log 2>&1
```

#### Advanced Logging Options

```bash
# With timestamp and rotation
0 2 * * * /path/to/docker_backup.sh --auto >> /path/to/logs/cron_backup_$(date +\%Y\%m).log 2>&1

# Use system logger
0 2 * * * /path/to/docker_backup.sh --auto 2>&1 | logger -t docker_backup

# Separate logs for success and error
0 2 * * * /path/to/docker_backup.sh --auto >> /path/to/logs/cron_backup_success.log 2>> /path/to/logs/cron_backup_error.log
```

### Set up Log Rotation

#### Automatic Log Rotation

```bash
# Cron job for log cleanup (daily at 4:00)
0 4 * * * find /path/to/logs/ -name "cron_backup*.log" -mtime +30 -delete

# Compression of old logs
0 4 * * 0 gzip /path/to/logs/cron_backup_$(date -d '1 week ago' +\%Y\%m\%d)*.log 2>/dev/null
```

#### Configure Logrotate

```bash
# Create /etc/logrotate.d/docker-backup
sudo tee /etc/logrotate.d/docker-backup << EOF
/path/to/logs/cron_backup*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 $(whoami) $(id -gn)
}
EOF
```

### Monitoring and Notifications

#### Email Notifications

```bash
# Send email on errors (requires mailutils)
0 2 * * * /path/to/docker_backup.sh --auto || echo "Docker Backup failed on $(date)" | mail -s "Backup Error" admin@example.com
```

#### Webhook Notifications

```bash
# Success/Error webhook
0 2 * * * /path/to/docker_backup.sh --auto && curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" -d '{"text":"Docker Backup successful"}' || curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" -d '{"text":"Docker Backup failed"}'
```

#### Create Status File

```bash
# Status file for monitoring
0 2 * * * /path/to/docker_backup.sh --auto && echo "SUCCESS $(date)" > /path/to/logs/last_backup_status || echo "FAILED $(date)" > /path/to/logs/last_backup_status
```

---

## Security Aspects

### Cron Security

#### Crontab Permissions

```bash
# Check crontab files
ls -la /var/spool/cron/crontabs/$(whoami)
# Should be: -rw------- (600)

# Check cron logs
sudo ls -la /var/log/cron*
```

#### Secure Script Paths

```bash
# Use absolute paths
0 2 * * * /usr/bin/env bash /path/to/docker_backup.sh --auto

# Set PATH explicitly
0 2 * * * PATH=/usr/local/bin:/usr/bin:/bin /path/to/docker_backup.sh --auto
```

### Backup Security

#### PID/Lock File Protection

The script (Version 3.4.9+) automatically prevents duplicate execution:

```bash
# Multiple cron jobs are safe
0 2 * * * /path/to/docker_backup.sh --auto --parallel 4
30 2 * * * /path/to/docker_backup.sh --auto --use-stop
```

#### Secure Password Management

```bash
# Password file for encrypted backups
echo "SECURE_PASSWORD" | sudo tee /path/to/.backup_password
sudo chmod 600 /path/to/.backup_password
sudo chown root:root /path/to/.backup_password
```

---

## Troubleshooting

### Common Cron Problems

#### Problem: Cron job doesn't run

**Diagnosis**:
```bash
# Check cron service
sudo systemctl status cron

# Check cron logs
sudo tail -f /var/log/cron.log

# Check crontab
crontab -l
```

**Solutions**:
```bash
# Start cron service
sudo systemctl start cron
sudo systemctl enable cron

# Check crontab syntax
crontab -l | crontab -
```

#### Problem: Script doesn't run in cron

**Diagnosis**:
```bash
# Test environment
env -i HOME="$HOME" PATH="/usr/bin:/bin" /path/to/docker_backup.sh --dry-run

# Check permissions
ls -la /path/to/docker_backup.sh
```

**Solutions**:
```bash
# Use full paths
0 2 * * * /usr/bin/env bash /path/to/docker_backup.sh --auto

# Set PATH in crontab
PATH=/usr/local/bin:/usr/bin:/bin
0 2 * * * /path/to/docker_backup.sh --auto
```

#### Problem: Sudo password required

**Diagnosis**:
```bash
# Test sudo configuration
sudo -n docker ps
```

**Solution**:
```bash
# Set up passwordless sudo
sudo visudo
# Add: username ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose
```

#### Problem: Logs are not created

**Diagnosis**:
```bash
# Check log directory
ls -ld /path/to/logs/

# Test write permissions
touch /path/to/logs/test.log
```

**Solution**:
```bash
# Create log directory
mkdir -p /path/to/logs/
chmod 755 /path/to/logs/
```

### Debug Techniques

#### Debug Cron Job

```bash
# Create debug cron job
* * * * * /path/to/docker_backup.sh --dry-run >> /tmp/cron_debug.log 2>&1

# Check after 2-3 minutes
cat /tmp/cron_debug.log
```

#### Compare Environment

```bash
# Interactive environment
env > /tmp/interactive_env.txt

# Cron environment
* * * * * env > /tmp/cron_env.txt

# Show differences
diff /tmp/interactive_env.txt /tmp/cron_env.txt
```

---

## Advanced Configurations

### Conditional Backups

#### Backup only on changes

```bash
# Extend script for change detection
0 2 * * * [ "$(find /path/to/data -newer /path/to/logs/last_backup_marker 2>/dev/null | wc -l)" -gt 0 ] && /path/to/docker_backup.sh --auto && touch /path/to/logs/last_backup_marker
```

#### Backup based on system load

```bash
# Only at low load
0 2 * * * [ "$(uptime | awk '{print $10}' | cut -d',' -f1)" \< "2.0" ] && /path/to/docker_backup.sh --auto
```

### Multi-Destination Backups

```bash
# Backup to multiple targets
0 2 * * * /path/to/docker_backup.sh --auto && rsync -av /path/to/backup/destination/ /mnt/external_backup/docker-nas-backup-$(date +\%Y\%m\%d)/
```

### Backup Rotation

```bash
# Automatic backup rotation
0 3 * * * find /path/to/backup/destination/ -name "docker-nas-backup-*" -type d -mtime +7 -exec rm -rf {} \;

# Backup archiving
0 4 * * 0 tar -czf /path/to/archives/docker-backup-$(date +\%Y\%m\%d).tar.gz /path/to/backup/destination/ && rm -rf /path/to/backup/destination/
```

---

## Best Practices

### Timing Best Practices

1. **Choose low system load**: Backups in early morning hours (1-4 AM)
2. **Use maintenance windows**: Backups outside main usage hours
3. **Staggered backups**: Different services at different times
4. **Plan buffer times**: Enough time between different backup jobs

### Resource Management

```bash
# Reduce CPU priority
0 2 * * * nice -n 10 /path/to/docker_backup.sh --auto

# Reduce IO priority (ionice)
0 2 * * * ionice -c 3 /path/to/docker_backup.sh --auto

# Combined
0 2 * * * nice -n 10 ionice -c 3 /path/to/docker_backup.sh --auto --parallel 2
```

### Monitoring Best Practices

1. **Regular log review**: Weekly check of backup logs
2. **Automatic alerts**: Immediate notification on backup failures
3. **Backup verification**: Regular restoration tests
4. **Disk space monitoring**: Monitor available storage space

### Security Best Practices

1. **Minimal permissions**: Only grant necessary sudo rights
2. **Secure paths**: Absolute paths and secure PATH variable
3. **Log security**: Protect logs from unauthorized access
4. **Backup encryption**: Encrypt sensitive data backups

### Maintenance Best Practices

```bash
# Monthly crontab review
0 0 1 * * crontab -l > /path/to/logs/crontab_backup_$(date +\%Y\%m).txt

# Quarterly backup test
0 2 1 */3 * /path/to/docker_backup.sh --dry-run --verbose >> /path/to/logs/quarterly_test.log 2>&1

# Annual configuration backup
0 1 1 1 * tar -czf /path/to/backups/cron_config_$(date +\%Y).tar.gz /var/spool/cron/crontabs/ /etc/cron.d/ /path/to/
```

---

## Example Configurations

### Small Installation (1-5 containers)

```bash
# Simple daily backups
0 2 * * * /path/to/docker_backup.sh --auto --use-stop >> /path/to/logs/cron_backup.log 2>&1

# Weekly log cleanup
0 3 * * 0 find /path/to/logs/ -name "*.log" -mtime +14 -delete
```

### Medium Installation (5-15 containers)

```bash
# Differentiated backup strategy
0 2 * * 1-6 /path/to/docker_backup.sh --auto --use-stop --parallel 2 --buffer-percent 15
0 1 * * 0 /path/to/docker_backup.sh --auto --preserve-acl --parallel 2 --timeout-stop 90

# Monitoring and cleanup
0 3 * * * echo "Backup Status: $(tail -1 /path/to/logs/docker_backup_*.log | grep -o 'successful\|failed')" | logger -t docker_backup_monitor
0 4 * * 0 find /path/to/logs/ -name "*.log" -mtime +30 -delete
```

### Large Installation (15+ containers)

```bash
# High-frequency, optimized backups
0 */8 * * * /path/to/docker_backup.sh --auto --use-stop --parallel 6 --no-verify --buffer-percent 10
0 2 * * * /path/to/docker_backup.sh --auto --parallel 4 --buffer-percent 20
0 1 * * 0 /path/to/docker_backup.sh --auto --preserve-acl --parallel 2 --timeout-stop 120

# Advanced monitoring
*/15 * * * * [ -f /path/to/logs/last_backup_status ] && [ "$(find /path/to/logs/last_backup_status -mmin +480)" ] && echo "ALERT: Backup overdue" | mail -s "Backup Alert" admin@example.com

# Automatic optimization
0 5 * * 0 nice -n 15 ionice -c 3 find /path/to/backup/destination/ -type f -name "*.log" -exec gzip {} \;
```

---

**Version 3.4.9 Compatibility**: All examples are optimized for the current script version and use the implemented security fixes for safe parallelization.