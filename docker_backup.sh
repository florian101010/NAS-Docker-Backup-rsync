#!/bin/bash
#
# ================================================================
# Docker NAS Backup Skript
# Automatisches Backup aller Docker-Container und persistenten Daten
# Stand: 30. Juli 2025 - Version 3.4.9
# GitHub: https://github.com/florian101010/NAS-Docker-Backup-rsync
# ================================================================

# Fail-Fast Settings für maximale Robustheit
set -euo pipefail
IFS=$'\n\t'

# Sichere PATH für Cron-Umgebung (append statt prepend für Sicherheit)
export PATH="$PATH:/usr/local/bin:/usr/bin:/bin"

# ================================================================
# KONFIGURATION - BITTE AN IHR SYSTEM ANPASSEN!
# ================================================================
#
# ⚠️  WICHTIG: Passen Sie diese Pfade an Ihr System an!
#
# Docker-Datenverzeichnis (Container-Volumes und persistente Daten)
# Beispiele: /opt/docker/data, /home/user/docker/data, /srv/docker/data
DATA_DIR="/volume1/docker-nas/data"

# Docker-Compose-Stacks Verzeichnis (docker-compose.yml Dateien)
# Beispiele: /opt/docker/stacks, /home/user/docker/compose, /srv/docker/stacks
STACKS_DIR="/volume1/docker-nas/stacks"

# Backup-Quellverzeichnis (wird komplett gesichert)
# Beispiele: /opt/docker, /home/user/docker, /srv/docker
BACKUP_SOURCE="/volume1/docker-nas"

# Backup-Zielverzeichnis (wohin das Backup gespeichert wird)
# Beispiele: /backup/docker, /mnt/backup/docker, /media/backup/docker
BACKUP_DEST="/volume2/backups/docker-nas-backup"

# Log-Verzeichnis (für Backup-Protokolle)
# Beispiele: /var/log/docker-backup, /opt/docker/logs, /home/user/logs
LOG_DIR="/volume1/docker-nas/logs"

# Log-Datei (automatisch generiert - normalerweise nicht ändern)
LOG_FILE="$LOG_DIR/docker_backup_$(date +%Y%m%d_%H%M%S).log"
# ================================================================

# Frühe Log-Initialisierung (vor ersten log_message Calls)
mkdir -p "$LOG_DIR"
: > "$LOG_FILE"

# Sichere Log-Datei Berechtigungen
if [[ $EUID -eq 0 ]]; then
    # Als root: Setze Besitzer auf den ursprünglichen User
    if [[ -n "${SUDO_USER:-}" ]]; then
        chown "$SUDO_USER:$SUDO_USER" "$LOG_FILE" 2>/dev/null || true
    fi
fi
chmod 600 "$LOG_FILE" 2>/dev/null || true

# Farben für Ausgabe
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ================================================================
# Flags für Automatisierung
AUTO_MODE=false
DRY_RUN=false
SKIP_BACKUP=false
VERIFY_BACKUP=true
USE_DOCKER_STOP=false  # Neue Option: stop statt down für schnellere Backups
PRESERVE_ACL=true     # neue option: acls und extended attributes sichern
COMPOSE_TIMEOUT_STOP=60    # Konfigurierbare Timeouts
COMPOSE_TIMEOUT_START=120
SPACE_BUFFER_PERCENT=20    # Konfigurierbarer Speicher-Puffer
PARALLEL_JOBS=1            # Parallelisierung (1 = seriell)
# ================================================================

# Arrays für Container-Tracking
declare -a RUNNING_STACKS=()
declare -a FAILED_STACKS=()
declare -a ALL_STACKS=()

# Globale Exit-Code Variable (vermeidet Kollision mit $?)
GLOBAL_EXIT_CODE=0

# Sudo-Optimierung: Einmalige Privilegien-Prüfung
SUDO_CMD=""
if [[ $EUID -eq 0 ]]; then
    # Bereits als root - kein sudo nötig
    SUDO_CMD=""
else
    # Als normaler User - sudo erforderlich
    SUDO_CMD="sudo"
    # Prüfe sudo-Berechtigung früh
    if ! sudo -n true 2>/dev/null; then
        echo "❌ FEHLER: Sudo-Berechtigung erforderlich"
        echo "Führe das Skript mit sudo aus oder konfiguriere NOPASSWD sudo"
        exit 1
    fi
fi

# Lock-Datei für Schutz gegen doppelte Ausführung
LOCK_FILE="/tmp/docker_backup.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo -e "${RED}❌ FEHLER: Backup läuft bereits (PID: $(cat "$LOCK_FILE" 2>/dev/null || echo 'unbekannt'))${NC}"
    exit 1
fi
echo $$ > "$LOCK_FILE"

# ================================================================
# LOGGING UND HILFSFUNKTIONEN
# ================================================================

# Funktion zur Formatierung von Docker-Container-Status-Ausgaben
format_container_status() {
    local input_line="$1"

    # Parse Container-Status-Meldungen und formatiere sie
    if [[ "$input_line" =~ ^[[:space:]]*Container[[:space:]]+([^[:space:]]+)[[:space:]]+(.+)$ ]]; then
        local container_name="${BASH_REMATCH[1]}"
        local status="${BASH_REMATCH[2]}"

        # Entferne Stack-Suffix für bessere Lesbarkeit
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

    # Wenn es keine Container-Status-Meldung ist, gib die ursprüngliche Zeile zurück
    echo "$input_line"
    return 1
}

# Funktion zur Verarbeitung von Docker-Compose-Ausgaben mit Container-Status-Formatierung
process_docker_output() {
    local show_container_status="${1:-true}"

    while IFS= read -r line; do
        # Entferne ANSI-Codes für Log-Datei
        local clean_line=$(echo "$line" | sed 's/\x1b\[[0-9;]*m//g')

        # Schreibe in Log-Datei
        echo "$clean_line" >> "$LOG_FILE"

        # Formatiere Container-Status für Terminal-Ausgabe
        if [[ "$show_container_status" == "true" ]] && format_container_status "$line" >/dev/null 2>&1; then
            format_container_status "$line"
        else
            # Zeige andere Docker-Ausgaben gedämpft an
            if [[ "$line" =~ ^[[:space:]]*Pulling|^[[:space:]]*Waiting|^[[:space:]]*Digest: ]]; then
                # Unterdrücke Pull/Download-Meldungen für saubere Ausgabe
                continue
            elif [[ "$line" =~ ^[[:space:]]*Network|^[[:space:]]*Volume ]]; then
                # Zeige Netzwerk/Volume-Meldungen gedämpft
                echo -e "    ${BLUE}ℹ${NC} $line"
            else
                # Andere Meldungen normal anzeigen
                echo "$line"
            fi
        fi
    done
}

# Hilfsfunktion für Byte-Formatierung (numfmt Fallback für BusyBox/Alpine)
format_bytes() {
    local bytes=$1
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec "$bytes"
    else
        # Einfacher Fallback für Systeme ohne numfmt
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

# Einheitliche Logging-Funktion (ANSI-bereinigt für Log-Dateien)
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] $message"

    # Ausgabe auf stderr mit Farben nur bei Terminal
    if [[ -t 2 ]]; then
        echo "$log_entry" >&2
    else
        # Keine Farben wenn nicht Terminal
        echo "$log_entry" | sed 's/\x1b\[[0-9;]*m//g' >&2
    fi

    # Log-Datei ohne ANSI-Codes (falls LOG_FILE gesetzt)
    if [[ -n "${LOG_FILE:-}" && -f "$LOG_FILE" ]]; then
        # Entferne ANSI-Escape-Sequenzen für Log-Datei
        echo "$log_entry" | sed 's/\x1b\[[0-9;]*m//g' >> "$LOG_FILE"
    fi
}

# Cleanup-Funktion für Signal-Handling
cleanup() {
    local exit_code=$?

    # Lock-Datei aufräumen (kosmetisch, da flock automatisch freigibt)
    rm -f "$LOCK_FILE" 2>/dev/null || true

    # Unterscheide zwischen normalem Exit und Signal/Fehler
    if [[ $exit_code -eq 0 ]]; then
        # Normaler Exit - kein Cleanup nötig, wird am Ende des Skripts geloggt
        return
    else
        log_message "WARN" "Cleanup ausgeführt (Signal/Exit: $exit_code)"

        # Versuche Container wieder zu starten falls sie gestoppt wurden
        if [[ ${#RUNNING_STACKS[@]} -gt 0 ]]; then
            log_message "INFO" "Starte gestoppte Container nach Cleanup..."
            start_all_docker_stacks || true  # Ignoriere Fehler im Cleanup
        fi

        log_message "INFO" "=== DOCKER NAS BACKUP CLEANUP BEENDET ==="
        exit $exit_code
    fi
}

# Signal-Handler registrieren
trap cleanup INT TERM EXIT

# Funktion für Hilfe-Text
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

# Funktion zur Validierung der Umgebung
validate_environment() {
    log_message "INFO" "Validiere Backup-Umgebung..."

    # Prüfe ob Docker läuft
    if ! $SUDO_CMD docker info >/dev/null 2>&1; then
        log_message "ERROR" "Docker ist nicht verfügbar oder läuft nicht"
        echo -e "${RED}❌ FEHLER: Docker ist nicht verfügbar oder läuft nicht${NC}"
        return 1
    fi

    # Prüfe kritische Verzeichnisse
    local critical_dirs=("$DATA_DIR" "$STACKS_DIR")
    for dir in "${critical_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            log_message "ERROR" "Kritisches Verzeichnis nicht gefunden: $dir"
            echo -e "${RED}❌ FEHLER: Verzeichnis nicht gefunden: $dir${NC}"
            return 1
        fi
    done

    # Prüfe Backup-Ziel (erstelle falls nötig)
    if [[ ! -d "$BACKUP_DEST" ]]; then
        log_message "INFO" "Erstelle Backup-Zielverzeichnis: $BACKUP_DEST"
        if ! $SUDO_CMD mkdir -p "$BACKUP_DEST" 2>/dev/null; then
            log_message "ERROR" "Backup-Zielverzeichnis konnte nicht erstellt werden: $BACKUP_DEST"
            echo -e "${RED}❌ FEHLER: Backup-Zielverzeichnis konnte nicht erstellt werden${NC}"
            return 1
        fi
        # Setze korrekte Berechtigungen (dynamisch ermittelt)
        local current_user=$(whoami)
        local current_group=$(id -gn)
        $SUDO_CMD chown -R "$current_user:$current_group" "$BACKUP_DEST"
        $SUDO_CMD chmod -R 775 "$BACKUP_DEST"
        log_message "INFO" "Backup-Verzeichnis Berechtigungen gesetzt: $current_user:$current_group"
    fi

    # Prüfe verfügbaren Speicherplatz
    local source_size=$($SUDO_CMD du -sb "$BACKUP_SOURCE" 2>/dev/null | cut -f1)
    local dest_avail=$(df -B1 "$BACKUP_DEST" 2>/dev/null | awk 'NR==2 {print $4}')

    if [[ -n "$source_size" && -n "$dest_avail" ]]; then
        # Verwende konfigurierbaren Speicher-Puffer
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

# Funktion für Bestätigung
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

# Funktion zum Sammeln aller Docker-Stacks (robuste Array-Behandlung)
discover_docker_stacks() {
    log_message "INFO" "Erkenne Docker-Stacks in $STACKS_DIR..."

    # Leere globales Array
    ALL_STACKS=()

    # Robuste Stack-Erkennung mit Null-Byte-Trennung
    while IFS= read -r -d '' stack_dir; do
        if [[ -f "${stack_dir}/docker-compose.yml" ]]; then
            local stack_name=$(basename "$stack_dir")
            ALL_STACKS+=("$stack_name")
        fi
    done < <(find "$STACKS_DIR" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)

    log_message "INFO" "Gefundene Stacks: ${#ALL_STACKS[@]} (${ALL_STACKS[*]})"
}

# Funktion zum Stoppen aller Docker-Stacks
stop_all_docker_stacks() {
    log_message "INFO" "Stoppe alle Docker-Stacks..."
    echo -e "${YELLOW}SCHRITT 1: Stoppe alle Docker-Container...${NC}"

    # Verwende globales Array statt Funktionsrückgabe
    discover_docker_stacks
    local stopped_count=0
    local failed_count=0

    if [[ ${#ALL_STACKS[@]} -eq 0 ]]; then
        log_message "WARN" "Keine Docker-Stacks gefunden in $STACKS_DIR"
        echo -e "${YELLOW}⚠️ Keine Docker-Stacks gefunden${NC}"
        return 0
    fi

    echo -e "${BLUE}Gefundene Stacks: ${YELLOW}${#ALL_STACKS[@]}${NC}"

    # Bestimme Docker-Kommando basierend auf Flag
    local docker_cmd="down"
    if [[ "$USE_DOCKER_STOP" == true ]]; then
        docker_cmd="stop"
        echo "(Modus: docker compose stop - schnellerer Neustart)"
        log_message "INFO" "Verwende 'docker compose stop' für schnelleren Neustart"
    else
        echo "(Modus: docker compose down - vollständige Bereinigung)"
        log_message "INFO" "Verwende 'docker compose down' für vollständige Bereinigung"
    fi

    # Parallelisierung oder seriell
    if [[ $PARALLEL_JOBS -gt 1 ]]; then
        echo "(Parallelisierung: $PARALLEL_JOBS Jobs)"
        log_message "INFO" "Verwende parallele Verarbeitung mit $PARALLEL_JOBS Jobs"

        # Erstelle temporäre Dateien für Exit-Status-Tracking
        local temp_dir=$(mktemp -d)

        # Exportiere SUDO_CMD, Variablen und Funktionen für Sub-Shells (defensive Programmierung)
        export SUDO_CMD LOG_FILE BACKUP_DEST BACKUP_SOURCE
        export -f process_docker_output format_container_status

        # Paralleles Stoppen mit xargs (robuste Behandlung von Stack-Namen mit Sonderzeichen)
        printf '%s\0' "${ALL_STACKS[@]}" | xargs -0 -r -P "$PARALLEL_JOBS" -I {} bash -c "
            stack_dir='$STACKS_DIR/{}'
            if [[ -f \"\$stack_dir/docker-compose.yml\" ]]; then
                running_containers=\$(cd \"\$stack_dir\" && $SUDO_CMD docker compose ps -q 2>/dev/null | wc -l)
                if [[ \$running_containers -gt 0 ]]; then
                    echo \"  → Stoppe Stack (parallel): {}\"
                    # LOG_FILE ist jetzt exportiert - direktes Logging mit flock für Thread-Sicherheit
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

        # Sammle Ergebnisse (Logs werden direkt geschrieben)
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
        # Serielle Verarbeitung (wie bisher)
        for stack_name in "${ALL_STACKS[@]}"; do
            local stack_dir="$STACKS_DIR/$stack_name"

            if [[ "$DRY_RUN" == true ]]; then
                echo "  → [DRY-RUN] Würde Stack stoppen: $stack_name ($docker_cmd)"
                log_message "INFO" "[DRY-RUN] Würde Stack stoppen: $stack_name ($docker_cmd)"
                continue
            fi

            echo -e "  ${CYAN}→${NC} Stoppe Stack: ${YELLOW}$stack_name${NC}"
            log_message "INFO" "Stoppe Stack: $stack_name ($docker_cmd)"

            # Prüfe ob Container laufen
            local running_containers=$(cd "$stack_dir" && $SUDO_CMD docker compose ps -q 2>/dev/null | wc -l)

            if [[ $running_containers -gt 0 ]]; then
                RUNNING_STACKS+=("$stack_name")

                # Stoppe Stack mit konfigurierbarem Timeout und formatierter Ausgabe
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

# Funktion zum Starten aller Docker-Stacks
start_all_docker_stacks() {
    log_message "INFO" "Starte alle Docker-Stacks..."
    echo -e "${YELLOW}SCHRITT 3: Starte alle Docker-Container...${NC}"

    local started_count=0
    local failed_count=0

    # Verwende bereits entdeckte Stacks oder entdecke neu falls leer
    if [[ ${#ALL_STACKS[@]} -eq 0 ]]; then
        discover_docker_stacks
    fi

    if [[ ${#ALL_STACKS[@]} -eq 0 ]]; then
        log_message "WARN" "Keine Docker-Stacks zum Starten gefunden"
        echo -e "${YELLOW}⚠️ Keine Docker-Stacks zum Starten gefunden${NC}"
        return 0
    fi

    # Parallelisierung oder seriell (auch für Start implementiert)
    if [[ $PARALLEL_JOBS -gt 1 ]]; then
        echo "(Parallelisierung: $PARALLEL_JOBS Jobs)"
        log_message "INFO" "Verwende parallele Verarbeitung mit $PARALLEL_JOBS Jobs"

        # Erstelle temporäre Dateien für Exit-Status-Tracking
        local temp_dir=$(mktemp -d)

        # Exportiere SUDO_CMD, Variablen und Funktionen für Sub-Shells (defensive Programmierung)
        export SUDO_CMD LOG_FILE BACKUP_DEST BACKUP_SOURCE
        export -f process_docker_output format_container_status

        # Paralleles Starten mit xargs (robuste Behandlung von Stack-Namen mit Sonderzeichen)
        printf '%s\0' "${ALL_STACKS[@]}" | xargs -0 -r -P "$PARALLEL_JOBS" -I {} bash -c "
            stack_dir='$STACKS_DIR/{}'
            if [[ -f \"\$stack_dir/docker-compose.yml\" ]]; then
                echo \"  → Starte Stack (parallel): {}\"
                # LOG_FILE ist jetzt exportiert - direktes Logging mit flock für Thread-Sicherheit
                if timeout '$COMPOSE_TIMEOUT_START' bash -c \"cd '\$stack_dir' && $SUDO_CMD docker compose up -d\" 2>&1 | process_docker_output; then
                    echo \"    ${GREEN}✅ Stack ${GREEN}{} ${GREEN}gestartet${NC}\"
                    touch '$temp_dir/{}.success'
                else
                    echo \"    ${RED}❌ Fehler beim Starten: ${GREEN}{}${NC}\"
                    touch '$temp_dir/{}.failed'
                fi
            fi
        "

        # Sammle Ergebnisse (Logs werden direkt geschrieben)
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
        # Serielle Verarbeitung
        for stack_name in "${ALL_STACKS[@]}"; do
            local stack_dir="$STACKS_DIR/$stack_name"

            if [[ "$DRY_RUN" == true ]]; then
                echo "  → [DRY-RUN] Würde Stack starten: $stack_name"
                log_message "INFO" "[DRY-RUN] Würde Stack starten: $stack_name"
                continue
            fi

            echo -e "  ${CYAN}→${NC} Starte Stack: ${GREEN}$stack_name${NC}"
            log_message "INFO" "Starte Stack: $stack_name"

            # Starte Stack mit konfigurierbarem Timeout und formatierter Ausgabe
            if timeout "$COMPOSE_TIMEOUT_START" bash -c "cd '$stack_dir' && $SUDO_CMD docker compose up -d" 2>&1 | process_docker_output; then
                ((started_count++))
                log_message "INFO" "Stack erfolgreich gestartet: $stack_name"
                echo -e "    ${GREEN}✅ Stack ${GREEN}$stack_name${NC} ${GREEN}erfolgreich gestartet${NC}"
            else
                ((failed_count++))
                FAILED_STACKS+=("$stack_name")  # FIX: Auch Start-Fehler tracken
                log_message "ERROR" "Fehler beim Starten von Stack: $stack_name"
                echo -e "    ${RED}❌ Fehler beim Starten von ${GREEN}$stack_name${NC}"
            fi

            # Kurze Pause zwischen Starts
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
# BACKUP FUNKTIONEN
# ================================================================

# Funktion für das eigentliche Backup
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

    # Backup-Zeitstempel
    local backup_start=$(date +%s)
    local backup_timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo -e "${BLUE}Quelle:${NC} $BACKUP_SOURCE"
    echo -e "${BLUE}Ziel:${NC} $BACKUP_DEST"
    echo -e "${BLUE}Gestartet:${NC} $backup_timestamp"
    echo ""

    # rsync-Optionen für konsistentes Backup (UGREEN NAS kompatibel - minimale Optionen)
    local rsync_opts="-a --delete"

    # Robuste rsync-Flag-Validierung für UGREEN NAS Kompatibilität
    RSYNC_FLAGS="-a --delete"

    # Teste Flags mit echtem rsync-Aufruf (sicherer als grep)
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

    # Teste und füge unterstützte Flags hinzu
    for flag in "--progress" "--stats" "--info=progress2"; do
        if test_rsync_flag "$flag"; then
            RSYNC_FLAGS="$RSYNC_FLAGS $flag"
            log_message "INFO" "rsync Flag hinzugefügt: $flag"
        else
            log_message "WARN" "rsync Flag nicht unterstützt: $flag"
            # Fallback für --info=progress2
            if [[ "$flag" == "--info=progress2" ]] && test_rsync_flag "--progress"; then
                RSYNC_FLAGS="$RSYNC_FLAGS --progress"
                log_message "INFO" "Fallback: --progress statt --info=progress2"
            fi
        fi
    done

    # Verwende die validierten Flags (ohne Anführungszeichen für korrekte Expansion)
    rsync_opts=$RSYNC_FLAGS

    # Erweiterte Optionen für ACLs und extended attributes (mit Fallback)
    if [[ "$PRESERVE_ACL" == true ]]; then
        # Prüfe erst ob ACL-Tools verfügbar sind (verhindert "command not found" Logs)
        if command -v setfacl >/dev/null 2>&1; then
            # Teste ACL-Unterstützung am Ziel (mit zufälligem Suffix gegen Race-Conditions)
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

    # Robuste rsync-Ausführung mit verbesserter Array-Behandlung
    execute_rsync_backup() {
        local source="$1"
        local dest="$2"
        local flags="$3"

        # Validiere Pfade
        if [[ ! -d "$source" ]]; then
            log_message "ERROR" "Quellverzeichnis nicht gefunden: $source"
            return 1
        fi

        # Erstelle Zielverzeichnis falls nötig
        if ! $SUDO_CMD mkdir -p "$dest" 2>/dev/null; then
            log_message "ERROR" "Zielverzeichnis konnte nicht erstellt werden: $dest"
            return 1
        fi

        # Erstelle rsync-Kommando-Array
        local rsync_cmd=()

        # Füge sudo hinzu falls nötig
        if [[ -n "$SUDO_CMD" ]]; then
            rsync_cmd+=("$SUDO_CMD")
        fi

        # Füge rsync hinzu
        rsync_cmd+=("rsync")

        # Sichere Flag-Expansion (behandelt auch Flags mit Gleichheitszeichen)
        local IFS=' '
        local flags_array=($flags)
        for flag in "${flags_array[@]}"; do
            if [[ -n "$flag" ]]; then
                rsync_cmd+=("$flag")
            fi
        done

        # Füge Pfade hinzu (normalisiere Trailing Slashes)
        rsync_cmd+=("${source%/}/" "${dest%/}/")

        # Debug-Ausgabe
        log_message "INFO" "Führe rsync aus: ${rsync_cmd[*]}"

        # Führe Kommando aus
        "${rsync_cmd[@]}" 2>&1 | sed 's/\x1b\[[0-9;]*m//g' | tee -a "$LOG_FILE"
        return $?
    }

    # Führe Backup durch mit Fallback-Mechanismus
    local rsync_exit_code
    local backup_success=false
    local original_flags="$rsync_opts"

    # Versuch 1: Mit optimierten Flags
    log_message "INFO" "Versuche Backup mit optimierten Flags: $rsync_opts"
    if execute_rsync_backup "$BACKUP_SOURCE" "$BACKUP_DEST" "$rsync_opts"; then
        rsync_exit_code=0
        backup_success=true
        log_message "INFO" "Backup mit optimierten Flags erfolgreich"
    else
        rsync_exit_code=$?
        log_message "WARN" "Backup mit optimierten Flags fehlgeschlagen (Exit: $rsync_exit_code), versuche Fallback..."

        # Versuch 2: Minimale sichere Flags
        rsync_opts="-a --delete --progress"
        log_message "INFO" "Fallback: Verwende minimale Flags: $rsync_opts"

        if execute_rsync_backup "$BACKUP_SOURCE" "$BACKUP_DEST" "$rsync_opts"; then
            rsync_exit_code=0
            backup_success=true
            log_message "INFO" "Backup mit minimalen Flags erfolgreich"
        else
            rsync_exit_code=$?
            log_message "WARN" "Auch minimale Flags fehlgeschlagen (Exit: $rsync_exit_code), versuche Basis-Fallback..."

            # Versuch 3: Absolut minimale Flags
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

        # Backup-Verifikation
        if [[ "$VERIFY_BACKUP" == true ]]; then
            verify_backup
        fi

        return 0
    else
        # Detaillierte rsync Exit-Code Analyse
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

# Funktion zur Backup-Verifikation
verify_backup() {
    log_message "INFO" "Starte Backup-Verifikation..."
    echo -e "${BLUE}🔍 Verifiziere Backup...${NC}"

    # Prüfe ob Backup-Verzeichnis existiert
    if [[ ! -d "$BACKUP_DEST" ]]; then
        log_message "ERROR" "Backup-Verzeichnis nicht gefunden: $BACKUP_DEST"
        echo -e "${RED}❌ Backup-Verzeichnis nicht gefunden${NC}"
        return 1
    fi

    # Erweiterte Backup-Verifikation
    echo -e "${BLUE}🔍 Vergleiche Verzeichnisgrößen und Dateianzahl...${NC}"

    # Vergleiche Verzeichnisgrößen
    local source_size=$($SUDO_CMD du -sb "$BACKUP_SOURCE" 2>/dev/null | cut -f1)
    local backup_size=$($SUDO_CMD du -sb "$BACKUP_DEST" 2>/dev/null | cut -f1)

    # Vergleiche Datei- und Ordneranzahl
    local source_files=$($SUDO_CMD find "$BACKUP_SOURCE" -type f 2>/dev/null | wc -l)
    local source_dirs=$($SUDO_CMD find "$BACKUP_SOURCE" -type d 2>/dev/null | wc -l)
    local backup_files=$($SUDO_CMD find "$BACKUP_DEST" -type f 2>/dev/null | wc -l)
    local backup_dirs=$($SUDO_CMD find "$BACKUP_DEST" -type d 2>/dev/null | wc -l)

    local verification_success=true

    if [[ -n "$source_size" && -n "$backup_size" ]]; then
        local size_diff=$((source_size - backup_size))
        local size_diff_abs=${size_diff#-}  # Absolutwert
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

    # Dateianzahl-Verifikation
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
# HAUPTPROGRAMM
# ================================================================

# Validierungsfunktion für numerische Parameter
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

# Parameter verarbeiten
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

# Initialisiere Logging mit sicheren Berechtigungen
umask 077  # Temporär restriktive Berechtigungen für Log-Dateien
mkdir -p "$LOG_DIR"
umask 022  # Zurück zu Standard-umask

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

# Umgebungsvalidierung
echo -e "${YELLOW}SCHRITT 0: Validiere Umgebung...${NC}"
if ! validate_environment; then
    log_message "ERROR" "Umgebungsvalidierung fehlgeschlagen - Abbruch"
    exit 1
fi
echo ""

# Bestätigung einholen
confirm_action

# Backup-Prozess starten
BACKUP_SUCCESS=true
CONTAINER_STOP_SUCCESS=true
CONTAINER_START_SUCCESS=true

# Schritt 1: Container stoppen
if ! stop_all_docker_stacks; then
    CONTAINER_STOP_SUCCESS=false
    log_message "WARN" "Nicht alle Container konnten gestoppt werden"
fi

# Schritt 2: Backup durchführen
if ! perform_backup; then
    BACKUP_SUCCESS=false
    log_message "ERROR" "Backup fehlgeschlagen"
fi

# Schritt 3: Container starten (immer versuchen, auch bei Backup-Fehlern)
if ! start_all_docker_stacks; then
    CONTAINER_START_SUCCESS=false
    log_message "ERROR" "Nicht alle Container konnten gestartet werden"
fi

echo ""

# ================================================================
# ABSCHLUSSBERICHT
# ================================================================

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}🔍 DRY-RUN ABGESCHLOSSEN!${NC}"
    log_message "INFO" "DRY-RUN abgeschlossen - keine Änderungen vorgenommen"
    echo "Keine Änderungen wurden vorgenommen. Führen Sie das Skript ohne --dry-run aus, um das Backup durchzuführen."
else
    # Bestimme Gesamtstatus
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

    # Statusübersicht
    echo ""
    echo -e "${CYAN}=== STATUSÜBERSICHT ===${NC}"
    echo -e "${BLUE}Container stoppen:${NC} $([ "$CONTAINER_STOP_SUCCESS" == true ] && echo -e "${GREEN}✅ Erfolgreich${NC}" || echo -e "${RED}❌ Fehler${NC}")"
    if [[ "$SKIP_BACKUP" == false ]]; then
        echo -e "${BLUE}Backup erstellen:${NC} $([ "$BACKUP_SUCCESS" == true ] && echo -e "${GREEN}✅ Erfolgreich${NC}" || echo -e "${RED}❌ Fehler${NC}")"
    fi
    echo -e "${BLUE}Container starten:${NC} $([ "$CONTAINER_START_SUCCESS" == true ] && echo -e "${GREEN}✅ Erfolgreich${NC}" || echo -e "${RED}❌ Fehler${NC}")"

    # Container-Änderungen Zusammenfassung
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

# Deaktiviere EXIT trap vor normalem Exit (idempotent)
trap - EXIT

# Einmaliger Abschluss-Log (nur hier, nicht doppelt)
log_message "INFO" "=== DOCKER NAS BACKUP BEENDET ==="
exit $GLOBAL_EXIT_CODE