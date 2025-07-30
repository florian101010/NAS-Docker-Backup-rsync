#!/bin/bash
#
# ================================================================
# Docker NAS Backup Script
# Automatic backup of all Docker containers and persistent data
# Date: July 30, 2025 - Version 3.4.9
# GitHub: https://github.com/florian101010/NAS-Docker-Backup-rsync
# ================================================================

# Fail-fast settings for maximum robustness
set -euo pipefail
IFS=$'\n\t'

# Secure PATH for cron environment (append instead of prepend for security)
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin"

# ================================================================
# CONFIGURATION - PLEASE ADAPT TO YOUR SYSTEM!
# ================================================================
#
# ⚠️  IMPORTANT: Adapt these paths to your system!
#
# Docker data directory (container volumes and persistent data)
# Examples: /opt/docker/data, /home/user/docker/data, /srv/docker/data
DATA_DIR="/volume1/docker-nas/data"

# Docker Compose stacks directory (docker-compose.yml files)
# Examples: /opt/docker/stacks, /home/user/docker/compose, /srv/docker/stacks
STACKS_DIR="/volume1/docker-nas/stacks"

# Backup source directory (will be completely backed up)
# Examples: /opt/docker, /home/user/docker, /srv/docker
BACKUP_SOURCE="/volume1/docker-nas"

# Backup destination directory (where the backup will be stored)
# Examples: /backup/docker, /mnt/backup/docker, /media/backup/docker
BACKUP_DEST="/volume2/backups/docker-nas-backup"

# Log directory (for backup logs)
# Examples: /var/log/docker-backup, /opt/docker/logs, /home/user/logs
LOG_DIR="/volume1/docker-nas/logs"

# Log file (automatically generated - usually don't change)
LOG_FILE="$LOG_DIR/docker_backup_$(date +%Y%m%d_%H%M%S).log"
# ================================================================

# Early log initialization (before first log_message calls)
mkdir -p "$LOG_DIR"
: > "$LOG_FILE"

# Secure log file permissions
if [[ $EUID -eq 0 ]]; then
    # As root: Set owner to original user
    if [[ -n "${SUDO_USER:-}" ]]; then
        chown "$SUDO_USER:$SUDO_USER" "$LOG_FILE" 2>/dev/null || true
    fi
fi
chmod 600 "$LOG_FILE" 2>/dev/null || true

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ================================================================
# Flags for automation
AUTO_MODE=false
DRY_RUN=false
SKIP_BACKUP=false
VERIFY_BACKUP=true
USE_DOCKER_STOP=false  # New option: stop instead of down for faster backups
# ACL and Extended Attributes (only for ext4/XFS/Btrfs/ZFS)
# Set to false for FAT32/NTFS/exFAT
PRESERVE_ACL=true     # New option: backup ACLs and extended attributes
COMPOSE_TIMEOUT_STOP=60    # Configurable timeouts
COMPOSE_TIMEOUT_START=120
SPACE_BUFFER_PERCENT=20    # Configurable memory buffer
PARALLEL_JOBS=1            # Parallelization (1 = serial)
# ================================================================

# Arrays for container tracking
declare -a RUNNING_STACKS=()
declare -a FAILED_STACKS=()
declare -a ALL_STACKS=()

# Global exit code variable (avoids collision with $?)
GLOBAL_EXIT_CODE=0

# Sudo optimization: One-time privilege check
SUDO_CMD=""
if [[ $EUID -eq 0 ]]; then
    # Already running as root - no sudo needed
    SUDO_CMD=""
else
    # Running as normal user - sudo required
    SUDO_CMD="sudo"
    # Check sudo permission early
    if ! sudo -n true 2>/dev/null; then
        echo "❌ FEHLER: Sudo-Berechtigung erforderlich"
        echo "Führe das Skript mit sudo aus oder konfiguriere NOPASSWD sudo"
        exit 1
    fi
fi

# Lock file for protection against double execution
LOCK_FILE="/tmp/docker_backup.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo -e "${RED}❌ FEHLER: Backup läuft bereits (PID: $(cat "$LOCK_FILE" 2>/dev/null || echo 'unbekannt'))${NC}"
    exit 1
fi
echo $$ > "$LOCK_FILE"

# ================================================================
# LOGGING AND HELPER FUNCTIONS
# ================================================================

# Function for formatting Docker container status output
format_container_status() {
    local input_line="$1"

    # Parse container status messages and format them
    if [[ "$input_line" =~ ^[[:space:]]*Container[[:space:]]+([^[:space:]]+)[[:space:]]+(.+)$ ]]; then
        local container_name="${BASH_REMATCH[1]}"
        local status="${BASH_REMATCH[2]}"

        # Remove stack suffix for better readability
        local clean_name="${container_name%-nas}"

        case "$status" in
            "Started"|"Running")
                echo -e "    ${GREEN}▶${NC} Container ${CYAN}$clean_name${NC} ${GREEN}gestartet${NC}"
                ;;
            "Stopped"|"Exited")
                echo -e "    ${YELLOW}⏸${NC} Container ${CYAN}$clean_name${NC} ${YELLOW}gestoppt${NC}"
                ;;
            "Removed")
                echo -e "    ${RED}🗑${NC} Container ${CYAN}$clean_name${NC} ${RED}entfernt${NC}"
                ;;
            "Created")
                echo -e "    ${BLUE}📦${NC} Container ${CYAN}$clean_name${NC} ${BLUE}erstellt${NC}"
                ;;
            *)
                echo -e "    ${BLUE}ℹ${NC} Container ${CYAN}$clean_name${NC} ${BLUE}$status${NC}"
                ;;
        esac
        return 0
    fi

    # If it's not a container status message, return the original line
    echo "$input_line"
    return 1
}

# Function for processing Docker Compose output with container status formatting
process_docker_output() {
    local show_container_status="${1:-true}"

    while IFS= read -r line; do
        # Remove ANSI codes for log file
        local clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')

        # Write to log file
        echo "$clean_line" >> "$LOG_FILE"

        # Format container status for terminal output
        if [[ "$show_container_status" == "true" ]] && format_container_status "$line" >/dev/null 2>&1; then
            format_container_status "$line"
        else
            # Show other Docker outputs muted
            if [[ "$line" =~ ^[[:space:]]*Pulling|^[[:space:]]*Waiting|^[[:space:]]*Digest: ]]; then
                # Suppress pull/download messages for clean output
                continue
            elif [[ "$line" =~ ^[[:space:]]*Network|^[[:space:]]*Volume ]]; then
                # Show network/volume messages muted
                echo -e "    ${BLUE}ℹ${NC} $line"
            else
                # Show other messages normally
                echo "$line"
            fi
        fi
    done
}

# Helper function for byte formatting (numfmt fallback for BusyBox/Alpine)
format_bytes() {
    local bytes=$1
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec "$bytes"
    else
        # Simple fallback for systems without numfmt
        if [[ $bytes -gt 1073741824 ]]; then
            echo "$((bytes / 1073741824))GB"
        elif [[ $bytes -gt 1048576 ]]; then
            echo "$((bytes / 1048576))MB"
        elif [[ $bytes -gt 1024 ]]; then
            echo "$((bytes / 1024))KB"
        else
            echo "${bytes}B"
        fi
    fi
}

# Unified logging function (ANSI-cleaned for log files)
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] $message"

    # Output to stderr with colors only for terminal
    if [[ -t 2 ]]; then
        echo "$log_entry" >&2
    else
        # No colors when not terminal
        echo "$log_entry" | sed 's/\x1b\[[0-9;]*m//g' >&2
    fi

    # Log file without ANSI codes (if LOG_FILE is set)
    if [[ -n "${LOG_FILE:-}" && -f "$LOG_FILE" ]]; then
        # Remove ANSI escape sequences for log file
        echo "$log_entry" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
    fi
}

# Cleanup function for signal handling
cleanup() {
    local exit_code=$?

    # Clean up lock file (cosmetic, as flock releases automatically)
    rm -f "$LOCK_FILE" 2>/dev/null || true

    # Distinguish between normal exit and signal/error
    if [[ $exit_code -eq 0 ]]; then
        # Normal exit - no cleanup needed, will be logged at end of script
        return
    else
        log_message "WARN" "Cleanup ausgeführt (Signal/Exit: $exit_code)"

        # Try to restart containers if they were stopped
        if [[ ${#RUNNING_STACKS[@]} -gt 0 ]]; then
            log_message "INFO" "Starte gestoppte Container nach Cleanup..."
            start_all_docker_stacks || true  # Ignore errors in cleanup
        fi

        log_message "INFO" "=== DOCKER NAS BACKUP CLEANUP BEENDET ==="
        exit $exit_code
    fi
}

# Register signal handler
trap cleanup INT TERM EXIT

# Function for help text
show_help() {
    echo -e "${CYAN}=== DOCKER NAS BACKUP SKRIPT ===${NC}"
    echo "Stoppt alle Docker-Container, erstellt ein konsistentes Backup und startet Container neu"
    echo ""
    echo -e "${YELLOW}VERWENDUNG:${NC}"
    echo "  $0 [OPTIONEN]"
    echo ""
    echo -e "${YELLOW}OPTIONEN:${NC}"
    echo "  --auto              Automatische Ausführung ohne Bestätigung"
    echo "  --dry-run           Zeigt nur was gemacht würde (keine Änderungen)"
    echo "  --skip-backup       Stoppt/startet nur Container (kein Backup)"
    echo "  --no-verify         Überspringt Backup-Verifikation"
    echo "  --use-stop          Verwendet 'docker compose stop' statt 'down'"
    echo "  --preserve-acl      Sichert ACLs und extended attributes"
    echo "  --timeout-stop N    Timeout für Container-Stop (Standard: ${COMPOSE_TIMEOUT_STOP}s)"
    echo "  --timeout-start N   Timeout für Container-Start (Standard: ${COMPOSE_TIMEOUT_START}s)"
    echo "  --parallel N        Parallele Jobs für Container-Ops (Standard: ${PARALLEL_JOBS})"
    echo "  --buffer-percent N  Speicher-Puffer in Prozent (Standard: ${SPACE_BUFFER_PERCENT}%)"
    echo "  --help, -h          Zeigt diese Hilfe an"
    echo ""
    echo -e "${YELLOW}BEISPIELE:${NC}"
    echo "  $0                           # Interaktives Backup"
    echo "  $0 --auto                    # Vollautomatisches Backup"
    echo "  $0 --dry-run                 # Test-Modus ohne Änderungen"
    echo "  $0 --skip-backup             # Nur Container-Neustart"
    echo ""
    echo -e "${YELLOW}PFADE:${NC}"
    echo "  Quelle: $BACKUP_SOURCE"
    echo "  Ziel: $BACKUP_DEST"
    echo "  Logs: $LOG_DIR/"
    echo ""
}

# Function for environment validation
validate_environment() {
    log_message "INFO" "Validiere Backup-Umgebung..."

    # Check if Docker is running
    if ! $SUDO_CMD docker info >/dev/null 2>&1; then
        log_message "ERROR" "Docker ist nicht verfügbar oder läuft nicht"
        echo -e "${RED}❌ FEHLER: Docker ist nicht verfügbar oder läuft nicht${NC}"
        return 1
    fi

    # Check critical directories
    local critical_dirs=("$DATA_DIR" "$STACKS_DIR")
    for dir in "${critical_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_message "ERROR" "Kritisches Verzeichnis nicht gefunden: $dir"
            echo -e "${RED}❌ FEHLER: Verzeichnis nicht gefunden: $dir${NC}"
            return 1
        fi
    done

    # Check backup destination (create if necessary)
    if [[ ! -d "$BACKUP_DEST" ]]; then
        log_message "INFO" "Erstelle Backup-Zielverzeichnis: $BACKUP_DEST"
        if ! $SUDO_CMD mkdir -p "$BACKUP_DEST" 2>/dev/null; then
            log_message "ERROR" "Backup-Zielverzeichnis konnte nicht erstellt werden: $BACKUP_DEST"
            echo -e "${RED}❌ FEHLER: Backup-Zielverzeichnis konnte nicht erstellt werden${NC}"
            return 1
        fi
        # Set correct permissions (dynamically determined)
        local current_user=$(whoami)
        local current_group=$(id -gn)
        $SUDO_CMD chown -R "$current_user:$current_group" "$BACKUP_DEST"
        $SUDO_CMD chmod -R 775 "$BACKUP_DEST"
        log_message "INFO" "Backup-Verzeichnis Berechtigungen gesetzt: $current_user:$current_group"
    fi

    # Check available disk space
    local source_size=$($SUDO_CMD du -sb "$BACKUP_SOURCE" 2>/dev/null | cut -f1)
    local dest_avail=$(df -B1 "$BACKUP_DEST" 2>/dev/null | awk 'NR==2 {print $4}')

    if [[ -n "$source_size" && -n "$dest_avail" ]]; then
        # Use configurable memory buffer
        local buffer_multiplier=$((100 + SPACE_BUFFER_PERCENT))
        local required_space=$((source_size * buffer_multiplier / 100))
        if [[ $dest_avail -lt $required_space ]]; then
            log_message "WARN" "Möglicherweise nicht genügend Speicherplatz. Benötigt: $(format_bytes $required_space), Verfügbar: $(format_bytes $dest_avail)"
            echo -e "${YELLOW}⚠️ WARNUNG: Möglicherweise nicht genügend Speicherplatz${NC}"
        fi
    fi

    log_message "INFO" "Umgebungsvalidierung erfolgreich"
    echo -e "${GREEN}✅ Umgebung validiert${NC}"
    return 0
}

# Function for confirmation
confirm_action() {
    if [[ "$AUTO_MODE" == true ]]; then
        return 0
    fi

    echo -e "${YELLOW}⚠️ WARNUNG:${NC} Diese Operation wird:"
    echo "  → Alle Docker Container stoppen"
    echo "  → Backup des gesamten docker-nas Verzeichnisses erstellen"
    echo "  → Container anschließend wieder starten"
    echo ""
    echo "Geschätzte Ausfallzeit: 2-5 Minuten"
    echo ""
    read -p "Möchten Sie fortfahren? (j/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[JjYy]$ ]]; then
        echo -e "${RED}Abgebrochen.${NC}"
        exit 0
    fi
}

# ================================================================
# DOCKER CONTAINER MANAGEMENT
# ================================================================

# Function to collect all Docker stacks (robust array handling)
discover_docker_stacks() {
    log_message "INFO" "Erkenne Docker-Stacks in $STACKS_DIR..."

    # Clear global array
    ALL_STACKS=()

    # Robust stack detection with null-byte separation
    while IFS= read -r -d '' stack_dir; do
        if [[ -f "${stack_dir}/docker-compose.yml" ]]; then
            local stack_name=$(basename "$stack_dir")
            ALL_STACKS+=("$stack_name")
        fi
    done < <(find "$STACKS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

    log_message "INFO" "Gefundene Stacks: ${#ALL_STACKS[@]} (${ALL_STACKS[*]})"
}

# Function to stop all Docker stacks
stop_all_docker_stacks() {
    log_message "INFO" "Stoppe alle Docker-Stacks..."
    echo -e "${YELLOW}SCHRITT 1: Stoppe alle Docker-Container...${NC}"

    # Use global array instead of function return
    discover_docker_stacks
    local stopped_count=0
    local failed_count=0

    if [[ ${#ALL_STACKS[@]} -eq 0 ]]; then
        log_message "WARN" "Keine Docker-Stacks gefunden in $STACKS_DIR"
        echo -e "${YELLOW}⚠️ Keine Docker-Stacks gefunden${NC}"
        return 0
    fi

    echo -e "${BLUE}Gefundene Stacks: ${YELLOW}${#ALL_STACKS[@]}${NC}"

    # Determine Docker command based on flag
    local docker_cmd="down"
    if [[ "$USE_DOCKER_STOP" == true ]]; then
        docker_cmd="stop"
        echo "(Modus: docker compose stop - schnellerer Neustart)"
        log_message "INFO" "Verwende 'docker compose stop' für schnelleren Neustart"
    else
        echo "(Modus: docker compose down - vollständige Bereinigung)"
        log_message "INFO" "Verwende 'docker compose down' für vollständige Bereinigung"
    fi

    # Parallelization or serial
    if [[ $PARALLEL_JOBS -gt 1 ]]; then
        echo "(Parallelisierung: $PARALLEL_JOBS Jobs)"
        log_message "INFO" "Verwende parallele Verarbeitung mit $PARALLEL_JOBS Jobs"

        # Create temporary files for exit status tracking
        local temp_dir=$(mktemp -d)

        # Export SUDO_CMD, variables and functions for sub-shells (defensive programming)
        export SUDO_CMD LOG_FILE BACKUP_DEST BACKUP_SOURCE
        export -f process_docker_output format_container_status

        # Parallel stopping with xargs (robust handling of stack names with special characters)
        printf '%s\0' "${ALL_STACKS[@]}" | xargs -0 -r -P "$PARALLEL_JOBS" -I {} bash -c "
            stack_dir='$STACKS_DIR/{}'
            if [[ -f \"\$stack_dir/docker-compose.yml\" ]]; then
                running_containers=\$(cd \"\$stack_dir\" && $SUDO_CMD docker compose ps -q 2>/dev/null | wc -l)
                if [[ \$running_containers -gt 0 ]]; then
                    echo \"  → Stoppe Stack (parallel): {}\"
                    # LOG_FILE is now exported - direct logging with flock for thread safety
                    if timeout '$COMPOSE_TIMEOUT_STOP' bash -c \"cd '\$stack_dir' && $SUDO_CMD docker compose $docker_cmd\" 2>&1 | process_docker_output; then
                        echo \"    ${GREEN}✅ Stack ${YELLOW}{} ${GREEN}gestoppt${NC}\"
                        touch '$temp_dir/{}.success'
                    else
                        echo \"    ${RED}❌ Fehler beim Stoppen: ${YELLOW}{}${NC}\"
                        touch '$temp_dir/{}.failed'
                    fi
                fi
            fi
        "

        # Collect results (logs are written directly)
        for stack_name in "${ALL_STACKS[@]}"; do
            if [[ -f "$temp_dir/$stack_name.success" ]]; then
                RUNNING_STACKS+=("$stack_name")
                ((stopped_count++))
            elif [[ -f "$temp_dir/$stack_name.failed" ]]; then
                FAILED_STACKS+=("$stack_name")
                ((failed_count++))
            fi
        done

        # Cleanup
        rm -rf "$temp_dir"
    else
        # Serial processing (as before)
        for stack_name in "${ALL_STACKS[@]}"; do
            local stack_dir="$STACKS_DIR/$stack_name"

            if [[ "$DRY_RUN" == true ]]; then
                echo "  → [DRY-RUN] Würde Stack stoppen: $stack_name ($docker_cmd)"
                log_message "INFO" "[DRY-RUN] Würde Stack stoppen: $stack_name ($docker_cmd)"
                continue
            fi

            echo -e "  ${CYAN}→${NC} Stoppe Stack: ${YELLOW}$stack_name${NC}"
            log_message "INFO" "Stoppe Stack: $stack_name ($docker_cmd)"

            # Check if containers are running
            local running_containers=$(cd "$stack_dir" && $SUDO_CMD docker compose ps -q 2>/dev/null | wc -l)

            if [[ $running_containers -gt 0 ]]; then
                RUNNING_STACKS+=("$stack_name")

                # Stop stack with configurable timeout and formatted output
                if timeout "$COMPOSE_TIMEOUT_STOP" bash -c "cd '$stack_dir' && $SUDO_CMD docker compose $docker_cmd" 2>&1 | process_docker_output; then
                    ((stopped_count++))
                    log_message "INFO" "Stack erfolgreich gestoppt: $stack_name"
                    echo -e "    ${GREEN}✅ Stack ${YELLOW}$stack_name${NC} ${GREEN}erfolgreich gestoppt${NC}"
                else
                    ((failed_count++))
                    FAILED_STACKS+=("$stack_name")
                    log_message "ERROR" "Fehler beim Stoppen von Stack: $stack_name"
                    echo -e "    ${RED}❌ Fehler beim Stoppen von ${YELLOW}$stack_name${NC}"
                fi
            else
                log_message "INFO" "Stack bereits gestoppt: $stack_name"
                echo -e "    ${BLUE}ℹ️${NC} Stack bereits gestoppt: ${YELLOW}$stack_name${NC}"
            fi
        done
    fi

    echo ""
    if [[ $failed_count -gt 0 ]]; then
        log_message "WARN" "Gestoppt: $stopped_count, Fehler: $failed_count"
        echo -e "${YELLOW}⚠️ $stopped_count Stacks gestoppt, $failed_count Fehler${NC}"
        return 1
    else
        log_message "INFO" "Alle Stacks erfolgreich gestoppt: $stopped_count"
        echo -e "${GREEN}✅ Alle $stopped_count Stacks erfolgreich gestoppt${NC}"
        return 0
    fi
}

# Function to start all Docker stacks
start_all_docker_stacks() {
    log_message "INFO" "Starte alle Docker-Stacks..."
    echo -e "${YELLOW}SCHRITT 3: Starte alle Docker-Container...${NC}"

    local started_count=0
    local failed_count=0

    # Use already discovered stacks or discover new ones if empty
    if [[ ${#ALL_STACKS[@]} -eq 0 ]]; then
        discover_docker_stacks
    fi

    if [[ ${#ALL_STACKS[@]} -eq 0 ]]; then
        log_message "WARN" "Keine Docker-Stacks zum Starten gefunden"
        echo -e "${YELLOW}⚠️ Keine Docker-Stacks zum Starten gefunden${NC}"
        return 0
    fi

    # Parallelization or serial (also implemented for start)
    if [[ $PARALLEL_JOBS -gt 1 ]]; then
        echo "(Parallelisierung: $PARALLEL_JOBS Jobs)"
        log_message "INFO" "Verwende parallele Verarbeitung mit $PARALLEL_JOBS Jobs"

        # Create temporary files for exit status tracking
        local temp_dir=$(mktemp -d)

        # Export SUDO_CMD, variables and functions for sub-shells (defensive programming)
        export SUDO_CMD LOG_FILE BACKUP_DEST BACKUP_SOURCE
        export -f process_docker_output format_container_status

        # Parallel starting with xargs (robust handling of stack names with special characters)
        printf '%s\0' "${ALL_STACKS[@]}" | xargs -0 -r -P "$PARALLEL_JOBS" -I {} bash -c "
            stack_dir='$STACKS_DIR/{}'
            if [[ -f \"\$stack_dir/docker-compose.yml\" ]]; then
                echo \"  → Starte Stack (parallel): {}\"
                # LOG_FILE is now exported - direct logging with flock for thread safety
                if timeout '$COMPOSE_TIMEOUT_START' bash -c \"cd '\$stack_dir' && $SUDO_CMD docker compose up -d\" 2>&1 | process_docker_output; then
                    echo \"    ${GREEN}✅ Stack ${GREEN}{} ${GREEN}gestartet${NC}\"
                    touch '$temp_dir/{}.success'
                else
                    echo \"    ${RED}❌ Fehler beim Starten: ${GREEN}{}${NC}\"
                    touch '$temp_dir/{}.failed'
                fi
            fi
        "

        # Collect results (logs are written directly)
        for stack_name in "${ALL_STACKS[@]}"; do
            if [[ -f "$temp_dir/$stack_name.success" ]]; then
                ((started_count++))
            elif [[ -f "$temp_dir/$stack_name.failed" ]]; then
                FAILED_STACKS+=("$stack_name")
                ((failed_count++))
            fi
        done

        # Cleanup
        rm -rf "$temp_dir"
    else
        # Serial processing
        for stack_name in "${ALL_STACKS[@]}"; do
            local stack_dir="$STACKS_DIR/$stack_name"

            if [[ "$DRY_RUN" == true ]]; then
                echo "  → [DRY-RUN] Würde Stack starten: $stack_name"
                log_message "INFO" "[DRY-RUN] Würde Stack starten: $stack_name"
                continue
            fi

            echo -e "  ${CYAN}→${NC} Starte Stack: ${GREEN}$stack_name${NC}"
            log_message "INFO" "Starte Stack: $stack_name"

            # Start stack with configurable timeout and formatted output
            if timeout "$COMPOSE_TIMEOUT_START" bash -c "cd '$stack_dir' && $SUDO_CMD docker compose up -d" 2>&1 | process_docker_output; then
                ((started_count++))
                log_message "INFO" "Stack erfolgreich gestartet: $stack_name"
                echo -e "    ${GREEN}✅ Stack ${GREEN}$stack_name${NC} ${GREEN}erfolgreich gestartet${NC}"
            else
                ((failed_count++))
                FAILED_STACKS+=("$stack_name")  # FIX: Also track start errors
                log_message "ERROR" "Fehler beim Starten von Stack: $stack_name"
                echo -e "    ${RED}❌ Fehler beim Starten von ${GREEN}$stack_name${NC}"
            fi

            # Short pause between starts
            sleep 2
        done
    fi

    echo ""
    if [[ $failed_count -gt 0 ]]; then
        log_message "WARN" "Gestartet: $started_count, Fehler: $failed_count"
        echo -e "${YELLOW}⚠️ $started_count Stacks gestartet, $failed_count Fehler${NC}"
        return 1
    else
        log_message "INFO" "Alle Stacks erfolgreich gestartet: $started_count"
        echo -e "${GREEN}✅ Alle $started_count Stacks erfolgreich gestartet${NC}"
        return 0
    fi
}

# ================================================================
# BACKUP FUNCTIONS
# ================================================================

# Function for the actual backup
perform_backup() {
    if [[ "$SKIP_BACKUP" == true ]]; then
        echo -e "${BLUE}ℹ️ Backup übersprungen (--skip-backup)${NC}"
        log_message "INFO" "Backup übersprungen (--skip-backup)"
        return 0
    fi

    log_message "INFO" "Starte Backup-Prozess..."
    echo -e "${YELLOW}SCHRITT 2: Erstelle konsistentes Backup...${NC}"

    if [[ "$DRY_RUN" == true ]]; then
        echo "[DRY-RUN] Würde Backup erstellen:"
        echo "  Quelle: $BACKUP_SOURCE"
        echo "  Ziel: $BACKUP_DEST"
        log_message "INFO" "[DRY-RUN] Backup-Simulation"
        return 0
    fi

    # Backup timestamp
    local backup_start=$(date +%s)
    local backup_timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo -e "${BLUE}Quelle:${NC} $BACKUP_SOURCE"
    echo -e "${BLUE}Ziel:${NC} $BACKUP_DEST"
    echo -e "${BLUE}Gestartet:${NC} $backup_timestamp"
    echo ""

    # rsync options for consistent backup (UGREEN NAS compatible - minimal options)
    local rsync_opts="-a --delete"

    # Robust rsync flag validation for UGREEN NAS compatibility
    RSYNC_FLAGS="-a --delete"

    # Test flags with real rsync call (safer than grep)
    test_rsync_flag() {
        local flag="$1"
        local test_dir=$(mktemp -d)
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

    # Test and add supported flags
    for flag in "--progress" "--stats" "--info=progress2"; do
        if test_rsync_flag "$flag"; then
            RSYNC_FLAGS="$RSYNC_FLAGS $flag"
            log_message "INFO" "rsync Flag hinzugefügt: $flag"
        else
            log_message "WARN" "rsync Flag nicht unterstützt: $flag"
            # Fallback for --info=progress2
            if [[ "$flag" == "--info=progress2" ]] && test_rsync_flag "--progress"; then
                RSYNC_FLAGS="$RSYNC_FLAGS --progress"
                log_message "INFO" "Fallback: --progress statt --info=progress2"
            fi
        fi
    done

    # Use the validated flags (without quotes for correct expansion)
    rsync_opts=$RSYNC_FLAGS

    # Extended options for ACLs and extended attributes (with fallback)
    if [[ "$PRESERVE_ACL" == true ]]; then
        # First check if ACL tools are available (prevents "command not found" logs)
        if command -v setfacl >/dev/null 2>&1; then
            # Test ACL support at destination (with random suffix against race conditions)
            local acl_test_file="$BACKUP_DEST/.acl_test_$$_$(date +%s)"
            if $SUDO_CMD touch "$acl_test_file" 2>/dev/null && $SUDO_CMD setfacl -m u:$(whoami):rw "$acl_test_file" 2>/dev/null; then
                rsync_opts="$rsync_opts -AX"
                log_message "INFO" "ACLs und extended attributes werden gesichert"
                echo "🔒 Sichere ACLs und extended attributes..."
                $SUDO_CMD rm -f "$acl_test_file" 2>/dev/null
            else
                log_message "WARN" "ACL-Unterstützung nicht verfügbar am Ziel - deaktiviert"
                echo "⚠️ ACL-Unterstützung nicht verfügbar am Ziel - wird übersprungen"
                $SUDO_CMD rm -f "$acl_test_file" 2>/dev/null
            fi
        else
            log_message "WARN" "ACL-Tools (setfacl) nicht installiert - ACL-Unterstützung deaktiviert"
            echo "⚠️ ACL-Tools nicht verfügbar - wird übersprungen"
        fi
    fi

    log_message "INFO" "Starte rsync: $BACKUP_SOURCE -> $BACKUP_DEST"

    # Robust rsync execution with improved array handling
    execute_rsync_backup() {
        local source="$1"
        local dest="$2"
        local flags="$3"

        # Validate paths
        if [[ ! -d "$source" ]]; then
            log_message "ERROR" "Quellverzeichnis nicht gefunden: $source"
            return 1
        fi

        # Create destination directory if necessary
        if ! $SUDO_CMD mkdir -p "$dest" 2>/dev/null; then
            log_message "ERROR" "Zielverzeichnis konnte nicht erstellt werden: $dest"
            return 1
        fi

        # Create rsync command array
        local rsync_cmd=()

        # Add sudo if necessary
        if [[ -n "$SUDO_CMD" ]]; then
            rsync_cmd+=("$SUDO_CMD")
        fi

        # Add rsync
        rsync_cmd+=("rsync")

        # Secure flag expansion (also handles flags with equals signs)
        local IFS=' '
        local flags_array=($flags)
        for flag in "${flags_array[@]}"; do
            if [[ -n "$flag" ]]; then
                rsync_cmd+=("$flag")
            fi
        done

        # Add paths (normalize trailing slashes)
        rsync_cmd+=("${source%/}/" "${dest%/}/")

        # Debug output
        log_message "INFO" "Führe rsync aus: ${rsync_cmd[*]}"

        # Execute command
        "${rsync_cmd[@]}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tee -a "$LOG_FILE"
        return $?
    }

    # Execute backup with fallback mechanism
    local rsync_exit_code
    local backup_success=false
    local original_flags="$rsync_opts"

    # Attempt 1: With optimized flags
    log_message "INFO" "Versuche Backup mit optimierten Flags: $rsync_opts"
    if execute_rsync_backup "$BACKUP_SOURCE" "$BACKUP_DEST" "$rsync_opts"; then
        rsync_exit_code=0
        backup_success=true
        log_message "INFO" "Backup mit optimierten Flags erfolgreich"
    else
        rsync_exit_code=$?
        log_message "WARN" "Backup mit optimierten Flags fehlgeschlagen (Exit: $rsync_exit_code), versuche Fallback..."

        # Attempt 2: Minimal safe flags
        rsync_opts="-a --delete --progress"
        log_message "INFO" "Fallback: Verwende minimale Flags: $rsync_opts"

        if execute_rsync_backup "$BACKUP_SOURCE" "$BACKUP_DEST" "$rsync_opts"; then
            rsync_exit_code=0
            backup_success=true
            log_message "INFO" "Backup mit minimalen Flags erfolgreich"
        else
            rsync_exit_code=$?
            log_message "WARN" "Auch minimale Flags fehlgeschlagen (Exit: $rsync_exit_code), versuche Basis-Fallback..."

            # Attempt 3: Absolutely minimal flags
            rsync_opts="-a --delete"
            log_message "INFO" "Basis-Fallback: Verwende nur: $rsync_opts"

            if execute_rsync_backup "$BACKUP_SOURCE" "$BACKUP_DEST" "$rsync_opts"; then
                rsync_exit_code=0
                backup_success=true
                log_message "INFO" "Backup mit Basis-Flags erfolgreich"
            else
                rsync_exit_code=$?
                log_message "ERROR" "Alle rsync-Fallback-Versuche fehlgeschlagen (Exit: $rsync_exit_code)"
                backup_success=false
            fi
        fi
    fi

    if [[ $backup_success == true && $rsync_exit_code -eq 0 ]]; then
        local backup_end=$(date +%s)
        local backup_duration=$((backup_end - backup_start))

        log_message "INFO" "Backup erfolgreich abgeschlossen in ${backup_duration}s"
        echo ""
        echo -e "${GREEN}✅ Backup erfolgreich abgeschlossen${NC}"
        echo -e "${BLUE}Dauer:${NC} ${GREEN}${backup_duration} Sekunden${NC}"

        # Backup verification
        if [[ "$VERIFY_BACKUP" == true ]]; then
            verify_backup
        fi

        return 0
    else
        # Detailed rsync exit code analysis
        case $rsync_exit_code in
            1)
                log_message "ERROR" "Backup fehlgeschlagen: Syntax oder Verwendungsfehler (Exit Code: $rsync_exit_code)"
                ;;
            2)
                log_message "ERROR" "Backup fehlgeschlagen: Protokollinkompatibilität (Exit Code: $rsync_exit_code)"
                ;;
            3)
                log_message "ERROR" "Backup fehlgeschlagen: Fehler bei Dateiauswahl (Exit Code: $rsync_exit_code)"
                ;;
            5)
                log_message "ERROR" "Backup fehlgeschlagen: Fehler beim Starten des Client-Server-Protokolls (Exit Code: $rsync_exit_code)"
                ;;
            10)
                log_message "ERROR" "Backup fehlgeschlagen: Fehler in Socket I/O (Exit Code: $rsync_exit_code)"
                ;;
            11)
                log_message "ERROR" "Backup fehlgeschlagen: Fehler in Datei I/O (Exit Code: $rsync_exit_code)"
                ;;
            12)
                log_message "ERROR" "Backup fehlgeschlagen: Fehler im rsync-Protokoll-Datenstream (Exit Code: $rsync_exit_code)"
                ;;
            13)
                log_message "ERROR" "Backup fehlgeschlagen: Fehler bei Diagnose (Exit Code: $rsync_exit_code)"
                ;;
            14)
                log_message "ERROR" "Backup fehlgeschlagen: Fehler in IPC-Code (Exit Code: $rsync_exit_code)"
                ;;
            20)
                log_message "ERROR" "Backup fehlgeschlagen: Signal empfangen (Exit Code: $rsync_exit_code)"
                ;;
            21)
                log_message "ERROR" "Backup fehlgeschlagen: Einige Dateien konnten nicht übertragen werden (Exit Code: $rsync_exit_code)"
                ;;
            22)
                log_message "ERROR" "Backup fehlgeschlagen: Teilweise Übertragung aufgrund von Fehlern (Exit Code: $rsync_exit_code)"
                ;;
            23)
                log_message "ERROR" "Backup fehlgeschlagen: Teilweise Übertragung aufgrund von verschwundenen Quelldateien (Exit Code: $rsync_exit_code)"
                ;;
            24)
                log_message "ERROR" "Backup fehlgeschlagen: Teilweise Übertragung aufgrund von verschwundenen Zieldateien (Exit Code: $rsync_exit_code)"
                ;;
            25)
                log_message "ERROR" "Backup fehlgeschlagen: Maximale Anzahl gelöschter Dateien erreicht (Exit Code: $rsync_exit_code)"
                ;;
            30)
                log_message "ERROR" "Backup fehlgeschlagen: Timeout bei Datenübertragung (Exit Code: $rsync_exit_code)"
                ;;
            35)
                log_message "ERROR" "Backup fehlgeschlagen: Timeout beim Warten auf Daemon-Antwort (Exit Code: $rsync_exit_code)"
                ;;
            *)
                log_message "ERROR" "Backup fehlgeschlagen: Unbekannter Fehler (Exit Code: $rsync_exit_code)"
                ;;
        esac
        echo -e "${RED}❌ Backup fehlgeschlagen (Exit Code: $rsync_exit_code)${NC}"
        return 1
    fi
}

# Function for backup verification
verify_backup() {
    log_message "INFO" "Starte Backup-Verifikation..."
    echo -e "${BLUE}🔍 Verifiziere Backup...${NC}"

    # Check if backup directory exists
    if [[ ! -d "$BACKUP_DEST" ]]; then
        log_message "ERROR" "Backup-Verzeichnis nicht gefunden: $BACKUP_DEST"
        echo -e "${RED}❌ Backup-Verzeichnis nicht gefunden${NC}"
        return 1
    fi

    # Extended backup verification
    echo -e "${BLUE}🔍 Vergleiche Verzeichnisgrößen und Dateianzahl...${NC}"

    # Compare directory sizes
    local source_size=$($SUDO_CMD du -sb "$BACKUP_SOURCE" 2>/dev/null | cut -f1)
    local backup_size=$($SUDO_CMD du -sb "$BACKUP_DEST" 2>/dev/null | cut -f1)

    # Compare file and directory counts
    local source_files=$($SUDO_CMD find "$BACKUP_SOURCE" -type f 2>/dev/null | wc -l)
    local source_dirs=$($SUDO_CMD find "$BACKUP_SOURCE" -type d 2>/dev/null | wc -l)
    local backup_files=$($SUDO_CMD find "$BACKUP_DEST" -type f 2>/dev/null | wc -l)
    local backup_dirs=$($SUDO_CMD find "$BACKUP_DEST" -type d 2>/dev/null | wc -l)

    local verification_success=true

    if [[ -n "$source_size" && -n "$backup_size" ]]; then
        local size_diff=$((source_size - backup_size))
        local size_diff_abs=${size_diff#-}  # Absolute value
        local size_diff_percent=$((size_diff_abs * 100 / source_size))

        echo -e "${BLUE}Quellgröße:${NC} ${CYAN}$(format_bytes $source_size)${NC}"
        echo -e "${BLUE}Backup-Größe:${NC} ${CYAN}$(format_bytes $backup_size)${NC}"

        if [[ $size_diff_percent -ge 5 ]]; then
            log_message "WARN" "Backup-Verifikation: Größenabweichung ${size_diff_percent}%"
            echo -e "${YELLOW}⚠️ Größenabweichung: ${size_diff_percent}%${NC}"
            verification_success=false
        fi
    else
        log_message "WARN" "Backup-Verifikation: Größenvergleich nicht möglich"
        echo -e "${YELLOW}⚠️ Größenvergleich nicht möglich${NC}"
        verification_success=false
    fi

    # File count verification
    echo -e "${BLUE}Quelldateien:${NC} ${CYAN}$source_files${NC}, ${BLUE}Quellordner:${NC} ${CYAN}$source_dirs${NC}"
    echo -e "${BLUE}Backup-Dateien:${NC} ${CYAN}$backup_files${NC}, ${BLUE}Backup-Ordner:${NC} ${CYAN}$backup_dirs${NC}"

    local file_diff=$((source_files - backup_files))
    local dir_diff=$((source_dirs - backup_dirs))

    if [[ $file_diff -ne 0 || $dir_diff -ne 0 ]]; then
        log_message "WARN" "Backup-Verifikation: Dateianzahl-Abweichung (Dateien: $file_diff, Ordner: $dir_diff)"
        echo -e "${YELLOW}⚠️ Dateianzahl-Abweichung: Dateien: $file_diff, Ordner: $dir_diff${NC}"
        verification_success=false
    fi

    if [[ "$verification_success" == true ]]; then
        log_message "INFO" "Backup-Verifikation erfolgreich"
        echo -e "${GREEN}✅ Backup-Verifikation erfolgreich${NC}"
        return 0
    else
        log_message "WARN" "Backup-Verifikation mit Warnungen abgeschlossen"
        echo -e "${YELLOW}⚠️ Backup-Verifikation mit Warnungen abgeschlossen${NC}"
        return 1
    fi
}

# ================================================================
# MAIN PROGRAM
# ================================================================

# Validation function for numeric parameters
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

# Process parameters
while [[ $# -gt 0 ]]; do
    case $1 in
        --auto)
            AUTO_MODE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --skip-backup)
            SKIP_BACKUP=true
            shift
            ;;
        --no-verify)
            VERIFY_BACKUP=false
            shift
            ;;
        --use-stop)
            USE_DOCKER_STOP=true
            shift
            ;;
        --preserve-acl)
            PRESERVE_ACL=true
            shift
            ;;
        --timeout-stop)
            validate_numeric "$2" "--timeout-stop" 10 3600
            COMPOSE_TIMEOUT_STOP="$2"
            shift 2
            ;;
        --timeout-start)
            validate_numeric "$2" "--timeout-start" 10 3600
            COMPOSE_TIMEOUT_START="$2"
            shift 2
            ;;
        --parallel)
            validate_numeric "$2" "--parallel" 1 16
            PARALLEL_JOBS="$2"
            shift 2
            ;;
        --buffer-percent)
            validate_numeric "$2" "--buffer-percent" 10 100
            SPACE_BUFFER_PERCENT="$2"
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unbekannte Option: $1${NC}"
            echo "Verwenden Sie --help für Hilfe."
            exit 1
            ;;
    esac
done

# Initialize logging with secure permissions
umask 077  # Temporarily restrictive permissions for log files
mkdir -p "$LOG_DIR"
umask 022  # Back to standard umask

log_message "INFO" "=== DOCKER NAS BACKUP GESTARTET ==="
log_message "INFO" "Optionen: AUTO_MODE=$AUTO_MODE, DRY_RUN=$DRY_RUN, SKIP_BACKUP=$SKIP_BACKUP, VERIFY_BACKUP=$VERIFY_BACKUP"
log_message "INFO" "Erweiterte Optionen: USE_DOCKER_STOP=$USE_DOCKER_STOP, PRESERVE_ACL=$PRESERVE_ACL"
log_message "INFO" "Timeouts: STOP=${COMPOSE_TIMEOUT_STOP}s, START=${COMPOSE_TIMEOUT_START}s"

echo -e "${CYAN}=== DOCKER NAS BACKUP SKRIPT ===${NC}"
echo "Automatisches Backup aller Docker-Container und persistenten Daten"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}🔍 DRY-RUN MODUS: Keine Änderungen werden vorgenommen${NC}"
fi

echo -e "${BLUE}📝 Log-Datei: $LOG_FILE${NC}"
echo ""

# Environment validation
echo -e "${YELLOW}SCHRITT 0: Validiere Umgebung...${NC}"
if ! validate_environment; then
    log_message "ERROR" "Umgebungsvalidierung fehlgeschlagen - Abbruch"
    exit 1
fi
echo ""

# Get confirmation
confirm_action

# Start backup process
BACKUP_SUCCESS=true
CONTAINER_STOP_SUCCESS=true
CONTAINER_START_SUCCESS=true

# Step 1: Stop containers
if ! stop_all_docker_stacks; then
    CONTAINER_STOP_SUCCESS=false
    log_message "WARN" "Nicht alle Container konnten gestoppt werden"
fi

# Step 2: Perform backup
if ! perform_backup; then
    BACKUP_SUCCESS=false
    log_message "ERROR" "Backup fehlgeschlagen"
fi

# Step 3: Start containers (always try, even on backup errors)
if ! start_all_docker_stacks; then
    CONTAINER_START_SUCCESS=false
    log_message "ERROR" "Nicht alle Container konnten gestartet werden"
fi

echo ""

# ================================================================
# FINAL REPORT
# ================================================================

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}🔍 DRY-RUN ABGESCHLOSSEN!${NC}"
    log_message "INFO" "DRY-RUN abgeschlossen - keine Änderungen vorgenommen"
    echo "Keine Änderungen wurden vorgenommen. Führen Sie das Skript ohne --dry-run aus, um das Backup durchzuführen."
else
    # Determine overall status
    if [[ "$BACKUP_SUCCESS" == true && "$CONTAINER_STOP_SUCCESS" == true && "$CONTAINER_START_SUCCESS" == true ]]; then
        echo -e "${GREEN}🎉 BACKUP ERFOLGREICH ABGESCHLOSSEN!${NC}"
        log_message "INFO" "Backup erfolgreich abgeschlossen"
        GLOBAL_EXIT_CODE=0
    elif [[ "$BACKUP_SUCCESS" == true ]]; then
        echo -e "${YELLOW}⚠️ BACKUP ABGESCHLOSSEN MIT WARNUNGEN${NC}"
        log_message "WARN" "Backup abgeschlossen mit Container-Problemen"
        GLOBAL_EXIT_CODE=1
    else
        echo -e "${RED}❌ BACKUP FEHLGESCHLAGEN${NC}"
        log_message "ERROR" "Backup fehlgeschlagen"
        GLOBAL_EXIT_CODE=2
    fi

    # Status overview
    echo ""
    echo -e "${CYAN}=== STATUSÜBERSICHT ===${NC}"
    echo -e "${BLUE}Container stoppen:${NC} $([ "$CONTAINER_STOP_SUCCESS" == true ] && echo -e "${GREEN}✅ Erfolgreich${NC}" || echo -e "${RED}❌ Fehler${NC}")"
    if [[ "$SKIP_BACKUP" == false ]]; then
        echo -e "${BLUE}Backup erstellen:${NC} $([ "$BACKUP_SUCCESS" == true ] && echo -e "${GREEN}✅ Erfolgreich${NC}" || echo -e "${RED}❌ Fehler${NC}")"
    fi
    echo -e "${BLUE}Container starten:${NC} $([ "$CONTAINER_START_SUCCESS" == true ] && echo -e "${GREEN}✅ Erfolgreich${NC}" || echo -e "${RED}❌ Fehler${NC}")"

    # Container changes summary
    if [[ ${#RUNNING_STACKS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${CYAN}=== CONTAINER-ÄNDERUNGEN ===${NC}"
        echo -e "${BLUE}Verarbeitete Stacks (${#RUNNING_STACKS[@]}):${NC}"
        for stack in "${RUNNING_STACKS[@]}"; do
            echo -e "  ${GREEN}✓${NC} ${CYAN}$stack${NC}"
        done
    fi

    if [[ ${#FAILED_STACKS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Problematische Stacks (${#FAILED_STACKS[@]}):${NC}"
        for stack in "${FAILED_STACKS[@]}"; do
            echo -e "  ${RED}•${NC} ${YELLOW}$stack${NC}"
        done
    fi
fi

echo ""
echo -e "${CYAN}Nächste Schritte:${NC}"
echo -e "  ${CYAN}1.${NC} Prüfe deine Services im Browser"
echo -e "  ${CYAN}2.${NC} Überwache die Container: ${YELLOW}docker ps${NC}"
echo -e "  ${CYAN}3.${NC} Log-Datei: ${BLUE}$LOG_FILE${NC}"
if [[ "$SKIP_BACKUP" == false && "$BACKUP_SUCCESS" == true ]]; then
    echo -e "  ${CYAN}4.${NC} Backup-Verzeichnis: ${BLUE}$BACKUP_DEST${NC}"
fi

# Deactivate EXIT trap before normal exit (idempotent)
trap - EXIT

# Single completion log (only here, not duplicate)
log_message "INFO" "=== DOCKER NAS BACKUP BEENDET ==="
exit $GLOBAL_EXIT_CODE