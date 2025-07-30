# Contributing to Docker NAS Backup Script

Thank you for your interest in contributing to the Docker NAS Backup Script! This document provides guidelines and information for contributors.

## 🤝 How to Contribute

### Reporting Issues

Before creating an issue, please:

1. **Search existing issues** to avoid duplicates
2. **Use the latest version** (v3.4.9+) to ensure the issue hasn't been fixed
3. **Test with `--dry-run`** to isolate the problem
4. **Include system information** (OS, Docker version, NAS type)

#### Bug Report Template

```markdown
**Environment:**
- OS: [e.g., Ubuntu 22.04, UGREEN NAS DXP2800]
- Script Version: [e.g., 3.4.9]
- Docker Version: [e.g., 24.0.5]
- Bash Version: [e.g., 5.1.16]

**Command Used:**
```bash
./docker_backup.sh --auto --parallel 4
```

**Expected Behavior:**
[Describe what should happen]

**Actual Behavior:**
[Describe what actually happened]

**Log Output:**
```
[Include relevant log entries]
```

**Additional Context:**
[Any other relevant information]
```

### Suggesting Features

For feature requests:

1. **Check the roadmap** in the documentation
2. **Explain the use case** and why it's valuable
3. **Consider backward compatibility**
4. **Provide implementation ideas** if possible

## 🛠️ Development Setup

### Prerequisites

- Linux environment (Ubuntu/Debian recommended)
- Docker and docker-compose installed
- Bash 4.0+ with development tools
- Test NAS environment or Docker stacks for testing

### Getting Started

```bash
# Clone the repository
git clone https://github.com/your-username/docker-nas-backup.git
cd docker-nas-backup

# Make scripts executable
chmod +x docker_backup.sh test_rsync_fix.sh

# Test the setup
./docker_backup.sh --help
./test_rsync_fix.sh
```

### Development Environment

```bash
# Create test Docker stacks for development
mkdir -p test-stacks/{stack1,stack2,stack3}

# Create minimal docker-compose.yml files for testing
for stack in test-stacks/*/; do
    cat > "$stack/docker-compose.yml" << EOF
version: '3.8'
services:
  test:
    image: alpine:latest
    command: sleep 3600
EOF
done
```

## 📝 Coding Standards

### Shell Script Guidelines

1. **Follow existing style** and formatting
2. **Use `set -euo pipefail`** for robust error handling
3. **Quote variables** to prevent word splitting
4. **Use meaningful function names** with clear purposes
5. **Add comments** for complex logic
6. **Validate inputs** with proper error messages

### Code Quality Checklist

- [ ] **Shellcheck clean**: No warnings from `shellcheck docker_backup.sh`
- [ ] **Error handling**: All commands have proper error handling
- [ ] **Input validation**: All parameters are validated
- [ ] **Documentation**: Functions and complex logic are documented
- [ ] **Backward compatibility**: Changes don't break existing functionality
- [ ] **Testing**: Changes are tested with various scenarios

### Example Code Style

```bash
# Good: Proper error handling and validation
validate_numeric() {
    local value="$1"
    local param_name="$2"
    local min_val="${3:-1}"
    local max_val="${4:-999999}"
    
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}❌ FEHLER: $param_name muss eine positive Zahl sein: $value${NC}"
        exit 1
    fi
    
    if [[ $value -lt $min_val || $value -gt $max_val ]]; then
        echo -e "${RED}❌ FEHLER: $param_name außerhalb des gültigen Bereichs ($min_val-$max_val): $value${NC}"
        exit 1
    fi
}

# Good: Proper function documentation
# Funktion zum Stoppen aller Docker-Stacks
# Globals:
#   ALL_STACKS - Array aller gefundenen Stacks
#   RUNNING_STACKS - Array der gestoppten Stacks
# Arguments:
#   None
# Returns:
#   0 on success, 1 on partial failure
stop_all_docker_stacks() {
    # Implementation...
}
```

## 🧪 Testing

### Manual Testing

Before submitting changes:

1. **Test basic functionality**:
   ```bash
   ./docker_backup.sh --dry-run
   ./docker_backup.sh --help
   ```

2. **Test parallel operations** (critical):
   ```bash
   ./docker_backup.sh --dry-run --parallel 2
   ./docker_backup.sh --dry-run --parallel 4
   ```

3. **Test error conditions**:
   ```bash
   # Test with invalid parameters
   ./docker_backup.sh --parallel 0
   ./docker_backup.sh --timeout-stop abc
   ```

4. **Test rsync compatibility**:
   ```bash
   ./test_rsync_fix.sh
   ```

### Test Scenarios

- [ ] **Serial operation** (`--parallel 1`)
- [ ] **Parallel operation** (`--parallel 2-8`)
- [ ] **Different Docker commands** (`--use-stop` vs default)
- [ ] **Various timeout values**
- [ ] **ACL preservation** (if supported)
- [ ] **Dry-run mode** accuracy
- [ ] **Error recovery** (interrupt with CTRL+C)
- [ ] **Cron compatibility** (non-interactive environment)

## 📋 Pull Request Process

### Before Submitting

1. **Create a feature branch** from `main`
2. **Test thoroughly** with various scenarios
3. **Update documentation** if needed
4. **Add changelog entry** for significant changes
5. **Ensure backward compatibility**

### Pull Request Template

```markdown
## Description
[Brief description of changes]

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Tested with `--dry-run`
- [ ] Tested serial operation
- [ ] Tested parallel operation (if applicable)
- [ ] Tested error conditions
- [ ] Tested on target NAS system

## Checklist
- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Documentation updated (if applicable)
- [ ] Changelog updated (if applicable)
- [ ] No breaking changes (or clearly documented)
```

### Review Process

1. **Automated checks** (if available) must pass
2. **Manual review** by maintainers
3. **Testing** on different systems
4. **Documentation review** for clarity
5. **Backward compatibility** verification

## 🔒 Security Considerations

### Critical Areas

When contributing to these areas, extra care is required:

- **Parallel operations**: Ensure thread safety
- **File operations**: Prevent race conditions
- **Input validation**: Sanitize all user inputs
- **Privilege handling**: Secure sudo usage
- **Signal handling**: Proper cleanup on interruption

### Security Review

For security-related changes:

1. **Threat modeling**: Consider potential attack vectors
2. **Input sanitization**: Validate and sanitize all inputs
3. **Privilege escalation**: Minimize sudo usage
4. **Race conditions**: Ensure atomic operations
5. **Error disclosure**: Don't leak sensitive information

## 📚 Documentation

### Documentation Standards

- **Clear and concise** language
- **Step-by-step instructions** for complex procedures
- **Examples** for all major features
- **Troubleshooting** sections for common issues
- **Security warnings** for critical operations

### Documentation Updates

When adding features:

1. **Update README.md** with new options
2. **Add examples** to documentation
3. **Update help text** in the script
4. **Add changelog entry**
5. **Update version compatibility** notes

## 🎯 Priority Areas

### High Priority

1. **Security fixes** - Always highest priority
2. **Data integrity** - Backup reliability improvements
3. **Compatibility** - Support for more NAS systems
4. **Performance** - Optimization for large installations

### Medium Priority

1. **User experience** - Better error messages, progress indicators
2. **Monitoring** - Enhanced logging and status reporting
3. **Automation** - Improved cron integration
4. **Testing** - Automated test suite development

### Low Priority

1. **Code cleanup** - Refactoring without functional changes
2. **Documentation** - Minor improvements and clarifications
3. **Cosmetic changes** - UI/output formatting improvements

## 🏆 Recognition

Contributors will be:

- **Listed in CHANGELOG.md** for significant contributions
- **Mentioned in release notes** for major features
- **Added to contributors list** in README.md
- **Credited in commit messages** and pull requests

## 📞 Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Documentation**: Check existing docs first
- **Code Review**: Ask for feedback during development

## 🔄 Release Process

### Version Numbering

- **Major** (X.0.0): Breaking changes or major new features
- **Minor** (X.Y.0): New features, backward compatible
- **Patch** (X.Y.Z): Bug fixes, security updates

### Release Criteria

- All tests pass
- Documentation updated
- Changelog updated
- Security review completed (for security-related changes)
- Backward compatibility maintained (or breaking changes documented)

---

Thank you for contributing to making Docker NAS backups more reliable and secure! 🚀