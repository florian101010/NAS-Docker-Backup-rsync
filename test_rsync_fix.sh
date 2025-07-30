#!/bin/bash

echo "=== RSYNC FIX VALIDATION TEST ==="
echo "Testet die neuen rsync-Fixes im docker_backup.sh"
echo ""

# Konfiguration (gleich wie im Hauptscript)
BACKUP_SOURCE="/volume1/docker-nas"
BACKUP_DEST="/tmp/test_backup_$(date +%s)"
LOG_DIR="/volume1/docker-nas/logs"

# Sudo-Erkennung
SUDO_CMD=""
if [[ $EUID -eq 0 ]]; then
    SUDO_CMD=""
else
    SUDO_CMD="sudo"
fi

echo "🔧 Test-Konfiguration:"
echo "   Quelle: $BACKUP_SOURCE"
echo "   Test-Ziel: $BACKUP_DEST"
echo "   Sudo: $SUDO_CMD"
echo ""

# Erstelle Test-Umgebung
echo "1️⃣ Erstelle Test-Umgebung..."
$SUDO_CMD mkdir -p "$BACKUP_DEST"
mkdir -p "$LOG_DIR"

# Test der neuen rsync-Flag-Validierung
echo ""
echo "2️⃣ Teste neue rsync-Flag-Validierung..."

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
echo "   Basis-Flags: $RSYNC_FLAGS"

for flag in "--progress" "--stats" "--info=progress2"; do
    echo -n "   Teste $flag: "
    if test_rsync_flag "$flag"; then
        RSYNC_FLAGS="$RSYNC_FLAGS $flag"
        echo "✅ unterstützt"
    else
        echo "❌ nicht unterstützt"
        if [[ "$flag" == "--info=progress2" ]] && test_rsync_flag "--progress"; then
            RSYNC_FLAGS="$RSYNC_FLAGS --progress"
            echo "   → Fallback: --progress hinzugefügt"
        fi
    fi
done

echo "   Finale Flags: $RSYNC_FLAGS"

# Test der neuen rsync-Ausführung
echo ""
echo "3️⃣ Teste neue rsync-Ausführung..."

execute_rsync_backup() {
    local source="$1"
    local dest="$2"
    local flags="$3"
    
    if [[ ! -d "$source" ]]; then
        echo "   ❌ Quellverzeichnis nicht gefunden: $source"
        return 1
    fi
    
    if ! $SUDO_CMD mkdir -p "$dest" 2>/dev/null; then
        echo "   ❌ Zielverzeichnis konnte nicht erstellt werden: $dest"
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
    
    echo "   Führe aus: ${rsync_cmd[*]}"
    "${rsync_cmd[@]}" >/dev/null 2>&1
    return $?
}

# Test mit verschiedenen Flag-Kombinationen
echo ""
echo "4️⃣ Teste Fallback-Mechanismus..."

test_flags=("$RSYNC_FLAGS" "-a --delete --progress" "-a --delete")
for i in "${!test_flags[@]}"; do
    flags="${test_flags[$i]}"
    echo -n "   Test $((i+1)): $flags → "
    
    if execute_rsync_backup "$BACKUP_SOURCE" "$BACKUP_DEST" "$flags"; then
        echo "✅ erfolgreich"
        WORKING_FLAGS="$flags"
        break
    else
        echo "❌ fehlgeschlagen"
    fi
done

# Cleanup
echo ""
echo "5️⃣ Cleanup..."
$SUDO_CMD rm -rf "$BACKUP_DEST"

# Ergebnis
echo ""
echo "=== TESTERGEBNIS ==="
if [[ -n "$WORKING_FLAGS" ]]; then
    echo "✅ RSYNC-FIXES FUNKTIONIEREN!"
    echo "   Funktionierende Flags: $WORKING_FLAGS"
    echo ""
    echo "Du kannst jetzt das Backup-Script testen:"
    echo "   sudo ./docker_backup.sh --dry-run"
    echo "   sudo ./docker_backup.sh --auto"
else
    echo "❌ RSYNC-FIXES BENÖTIGEN WEITERE ANPASSUNG"
    echo "   Alle getesteten Flag-Kombinationen schlugen fehl"
fi
echo ""
echo "=== TEST ABGESCHLOSSEN ==="