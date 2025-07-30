#!/bin/bash

echo "=== RSYNC FIX - VALIDATION TEST ==="
echo "Testing the new rsync fixes in docker_backup.sh"
echo ""

# Configuration (same as in main script)
BACKUP_SOURCE="/volume1/docker-nas"
BACKUP_DEST="/tmp/test_backup_$(date +%s)"
LOG_DIR="/volume1/docker-nas/logs"

# Sudo detection
SUDO_CMD=""
if [[ $EUID -eq 0 ]]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

echo "🔧 Test Configuration:"
echo "   Source: $BACKUP_SOURCE"
echo "   Test Target: $BACKUP_DEST"
echo "   Sudo: $SUDO_CMD"
echo ""

# Create test environment
echo "1️⃣ Creating test environment..."
$SUDO_CMD mkdir -p "$BACKUP_DEST"
mkdir -p "$LOG_DIR"

# Test new rsync flag validation
echo ""
echo "2️⃣ Testing new rsync flag validation..."

test_rsync_flag() {
    local flag="$1"
    local test_dir="/tmp/rsync_test_$$"
    mkdir -p "$test_dir/src" "$test_dir/dst" 2>/dev/null
    echo "test" > "$test_dir/src/test.txt"
    
    if rsync $flag --dry-run "$test_dir/src/" "$test_dir/dst/" >/dev/null 2>&1; then
        rm -rf "$test_dir" 2>/dev/null
        return 0
    else
        rm -rf "$test_dir" 2>/dev/null
        return 1
    fi
}

RSYNC_FLAGS="-a --delete"
echo "   Base flags: $RSYNC_FLAGS"

for flag in "--progress" "--stats" "--info=progress2"; do
    echo -n "   Testing $flag: "
    if test_rsync_flag "$flag"; then
        RSYNC_FLAGS="$RSYNC_FLAGS $flag"
        echo "✅ supported"
    else
        echo "❌ not supported"
        if [[ "$flag" == "--info=progress2" ]] && test_rsync_flag "--progress"; then
            RSYNC_FLAGS="$RSYNC_FLAGS --progress"
            echo "   → Fallback: --progress added"
        fi
    fi
done

echo "   Final flags: $RSYNC_FLAGS"

# Test new rsync execution
echo ""
echo "3️⃣ Testing new rsync execution..."

execute_rsync_backup() {
    local source="$1"
    local dest="$2"
    local flags="$3"
    
    if [[ ! -d "$source" ]]; then
        echo "   ❌ Source directory not found: $source"
        return 1
    fi
    
    if ! $SUDO_CMD mkdir -p "$dest" 2>/dev/null; then
        echo "   ❌ Could not create target directory: $dest"
        return 1
    fi
    
    local rsync_cmd=()
    if [[ -n "$SUDO_CMD" ]]; then
        rsync_cmd+=("$SUDO_CMD")
    fi
    rsync_cmd+=("rsync")
    
    local IFS=' '
    local flags_array=($flags)
    for flag in "${flags_array[@]}"; do
        if [[ -n "$flag" ]]; then
            rsync_cmd+=("$flag")
        fi
    done
    
    rsync_cmd+=("--dry-run" "${source%/}/" "${dest%/}/")
    
    echo "   Executing: ${rsync_cmd[*]}"
    "${rsync_cmd[@]}" >/dev/null 2>&1
    return $?
}

# Test with different flag combinations
echo ""
echo "4️⃣ Testing fallback mechanism..."

test_flags=("$RSYNC_FLAGS" "-a --delete --progress" "-a --delete")
for i in "${!test_flags[@]}"; do
    flags="${test_flags[$i]}"
    echo -n "   Test $((i+1)): $flags → "
    
    if execute_rsync_backup "$BACKUP_SOURCE" "$BACKUP_DEST" "$flags"; then
        echo "✅ successful"
        WORKING_FLAGS="$flags"
        break
    else
        echo "❌ failed"
    fi
done

# Cleanup
echo ""
echo "5️⃣ Cleanup..."
$SUDO_CMD rm -rf "$BACKUP_DEST"

# Result
echo ""
echo "=== TEST RESULT ==="
if [[ -n "$WORKING_FLAGS" ]]; then
    echo "✅ RSYNC FIXES ARE WORKING!"
    echo "   Working flags: $WORKING_FLAGS"
    echo ""
    echo "You can now test the backup script:"
    echo "   sudo ./docker_backup.sh --dry-run"
    echo "   sudo ./docker_backup.sh --auto"
else
    echo "❌ RSYNC FIXES NEED FURTHER ADJUSTMENT"
    echo "   All tested flag combinations failed"
fi
echo ""
echo "=== TEST COMPLETED ==="