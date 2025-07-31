# Docker NAS Backup Skript - Verwendungsanleitung

## Inhaltsverzeichnis

- [Für wen ist diese Anleitung?](#für-wen-ist-diese-anleitung)
- [Schnellstart (für Eilige)](#schnellstart-für-eilige)
- [Übersicht](#übersicht)
- [Installation](#installation)
- [Verwendung](#verwendung)
- [Konfiguration](#konfiguration)
- [Automatisierung mit Cron](#automatisierung-mit-cron)
- [Logging](#logging)
- [Sicherheitsfeatures](#sicherheitsfeatures)
- [Erweiterte Features](#erweiterte-features)
- [Backup-Verschlüsselung](#backup-verschlüsselung)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Best Practices](#best-practices)

---

## Für wen ist diese Anleitung?

### Anfänger - Neu bei Docker/NAS?
- ✅ Folgen Sie der **Schritt-für-Schritt Anleitung**
- ✅ Nutzen Sie die **Schnellstart-Sektion**
- ✅ Alle Befehle sind erklärt und kopierbar

### Fortgeschrittene - Sie kennen Docker?
- ✅ Springen Sie zu **Konfiguration & Erweiterte Features**
- ✅ Nutzen Sie die **Parameter-Referenz**
- ✅ Anpassung an Ihre Umgebung

### Experten - Sie wollen alles verstehen?
- ✅ Technische Details in **Erweiterte Features**
- ✅ Source-Code Kommentare im Script
- ✅ Performance-Tuning Optionen

---

## Schnellstart (für Eilige)

### 3-Minuten Setup

```bash
# 1. Script ausführbar machen
chmod +x docker_backup.sh

# 2. Erstes Backup (mit Bestätigung)
./docker_backup.sh

# 3. Automatisches Backup einrichten
crontab -e
# Füge hinzu: 0 2 * * * /pfad/zum/docker_backup.sh --auto
```

**Das war's!** Ihr Backup läuft jetzt täglich um 2:00 Uhr.

---

## Übersicht

Das `docker_backup.sh` Skript erstellt konsistente Backups aller Docker-Container und persistenten Daten auf dem UGREEN NAS DXP2800. Es stoppt automatisch alle Container, führt das Backup durch und startet die Container wieder.

### Was macht dieses Script?

**Einfach erklärt:**
Das Script sichert Ihr komplettes Docker-Setup, während die Container sauber gestoppt sind:

1. **Stoppt alle Container** (sauber, nicht brutal)
2. **Kopiert alle Daten** (konsistent, ohne Datenverlust)
3. **Startet alle Container wieder** (automatisch)

### Was wird gesichert:

| Verzeichnis | Inhalt | Wichtigkeit |
|-------------|--------|-------------|
| `/volume1/docker-nas/data/` | Container-Daten (Datenbanken, Dateien) | **KRITISCH** |
| `/volume1/docker-nas/stacks/` | docker-compose.yml Dateien | **WICHTIG** |
| `/volume1/docker-nas/logs/` | Log-Dateien | **NÜTZLICH** |

### Version 3.5.1 - Kritische Sicherheitsfixes

> **Wichtige Sicherheitsupdates implementiert - 30. Juli 2025**

#### Kritische Sicherheitsfixes (Version 3.5.1)
- **🔒 FUNKTIONEN-EXPORT FIX (PRIO 1 - KRITISCH)**: Behebt kompletten Backup-Ausfall bei Parallelisierung
  - `export -f process_docker_output format_container_status` vor allen `xargs`-Blöcken
  - **Problem behoben**: Bei `--parallel N>1` schlugen alle `docker compose`-Pipes fehl
  - **Impact**: Verhindert stillen Backup-Ausfall ohne Fehlermeldung
  - **Status**: ✅ Implementiert in Zeilen 400 & 517
- **🛡️ PID/LOCK-DATEI SCHUTZ (PRIO 2)**: Verhindert doppelte Cron-Ausführung
  - Atomarer Lock mit `flock` für thread-sichere Ausführung
  - Automatisches Lock-File-Cleanup bei normalem und abnormalem Exit
  - **Problem behoben**: Doppelte Backup-Runs bei Cron-Jobs
  - **Status**: ✅ Implementiert in Zeilen 82-89 & 207
- **🔧 LOG-RACE-CONDITIONS FIX (PRIO 2)**: Thread-sichere Log-Ausgabe
  - Export aller kritischen Umgebungsvariablen: `LOG_FILE`, `BACKUP_DEST`, `BACKUP_SOURCE`
  - Direktes Logging statt temporäre Dateien für formatierte Container-Status-Ausgaben
  - **Problem behoben**: Zeilensalat und fehlende formatierte Ausgaben in parallelen Jobs
  - **Status**: ✅ Implementiert mit vollständiger Variable-Export-Strategie
- **🔐 SICHERE TEMP-VERZEICHNISSE**: Race-Condition-freie Temp-Erstellung
  - `mktemp -d` statt `/tmp/rsync_test_$$` für kollisionsfreie Temp-Verzeichnisse
  - **Problem behoben**: Potenzielle Temp-Verzeichnis-Kollisionen bei schnellen Runs
  - **Status**: ✅ Implementiert in Zeile 631

#### Neue Features (Version 3.4.8)
- **🧪 ROBUSTE RSYNC-FLAG-VALIDIERUNG**: Echte Funktionalitätsprüfung statt grep
  - Neue `test_rsync_flag()` Funktion mit echten rsync-Tests
  - Ersetzt unzuverlässige `grep`-basierte Flag-Erkennung
  - Automatischer Fallback von `--info=progress2` zu `--progress`
  - 100% zuverlässige Kompatibilitätsprüfung
- **🔧 VERBESSERTE RSYNC-AUSFÜHRUNG**: Neue `execute_rsync_backup()` Funktion
  - Robuste Pfad-Validierung und automatische Zielverzeichnis-Erstellung
  - Sichere Array-basierte Parameter-Übergabe für alle Flag-Typen
  - Behandelt auch komplexe Flags mit Gleichheitszeichen korrekt
  - Detaillierte Debug-Ausgabe und Fehlerbehandlung
- **🎯 DREISTUFIGER FALLBACK-MECHANISMUS**: Automatische Kompatibilitäts-Anpassung
  - Stufe 1: Optimierte Flags (`-a --delete --progress --stats --info=progress2`)
  - Stufe 2: Minimale Flags (`-a --delete --progress`)
  - Stufe 3: Basis-Flags (`-a --delete`)
  - Garantiert Funktionalität auf allen rsync-Versionen
- **🎨 OPTIMIERTE TERMINAL-AUSGABE**: Verbesserte Lesbarkeit und Benutzerfreundlichkeit
  - Farbige Stack-Namen: `→ Stoppe Stack: paperless-ai` (gelb hervorgehoben)
  - Cyan-farbige Pfeile `→` für bessere Orientierung
  - Grüne ✅ und rote ❌ Status-Indikatoren mit Farben
  - Strukturierte Ausgaben mit blauen Labels
  - Problematische Stacks rot hervorgehoben mit Bullet-Points
- **🧪 NEUE TEST-TOOLS**: Isolierte Validierung und Debugging
  - `test_rsync_fix.sh` für isolierte rsync-Funktionalitätsprüfung
  - Verbesserte Logging mit detaillierter Fehlerdiagnose
  - Automatische Testergebnisse und Empfehlungen

#### ✨ Features aus Version 3.4.6 - KRITISCHE RSYNC-FIXES
- **🔧 ARRAY-BASIERTE RSYNC-AUSFÜHRUNG**: Behebt kritischen Parameter-Übergabe-Bug
- **🎯 DYNAMISCHE FLAG-VALIDIERUNG**: Intelligente rsync-Kompatibilitätsprüfung
- **🔧 STRING-EXPANSION-FIX**: Behebt finalen rsync-Parameter-Bug

#### ✨ Features aus Version 3.4.5 - UGREEN NAS KOMPATIBILITÄT
- **🔧 DOCKER COMPOSE ANSI-FIX**: Entfernung von `--ansi never` für ältere Docker Compose Versionen
- **📡 RSYNC PROGRESS-FIX**: Ersetzt `--info=progress2` durch universelles `--progress`
- **✅ UGREEN NAS DXP2800**: Vollständige Kompatibilität bestätigt

### Version 3.4.4

#### Neue Features (Version 3.4.4)
- **🔒 SUDO_CMD EXPORT**: Expliziter Export für maximale Sub-Shell-Kompatibilität
  - `export SUDO_CMD` vor xargs-Aufrufen für defensive Programmierung
  - Shell-agnostische Robustheit (nicht nur Bash-spezifisch)
  - Verhindert potenzielle Variable-Verfügbarkeitsprobleme in verschiedenen Shell-Umgebungen

#### Features aus Version 3.4.3
- **🔧 SUB-SHELL VARIABLE FIX**: Korrektur der `sudo_cmd_clean` Variable in xargs Sub-Shells
- **⚡ RSYNC PERFORMANCE**: Entfernung der `-h` Option für bessere Log-Performance
- **🛡️ SICHERERER SPEICHER-PUFFER**: Minimum von 10% statt 5% für `--buffer-percent`

#### Features aus Version 3.4.2
- **🔧 NULL-BYTE-DELIMITER FIX**: Kritischer Bugfix für `printf %q` Problem mit Stack-Namen
  - Ersetzt `printf '%q\n'` durch `printf '%s\0'` + `xargs -0` für robuste Sonderzeichen-Behandlung
  - Verhindert "Datei nicht gefunden" Fehler bei Stack-Namen mit Leerzeichen/Sonderzeichen
- **📦 NUMFMT-FALLBACK**: Kompatibilität für BusyBox/Alpine-Systeme ohne `numfmt`
  - Neue `format_bytes()` Funktion mit automatischem Fallback
  - Unterstützt GB/MB/KB-Formatierung auch ohne GNU coreutils
- **🧹 SUDO_CMD-OPTIMIERUNG**: Saubere Kommando-Ausgabe ohne doppelte Leerzeichen
  - Verbesserte `${SUDO_CMD:-}` Syntax statt `echo | xargs` Workaround

#### Features aus Version 3.4.1
- **Finale Micro-Optimierungen**: Alle kosmetischen Details perfektioniert
- **PATH-Sicherheit**: Append statt prepend für sichere Tool-Prioritäten
- **ACL-Tool-Check**: Prüfung auf `setfacl` Verfügbarkeit vor Verwendung
- **Robuste xargs-Behandlung**: Null-Byte-Delimiter für Stack-Namen mit Sonderzeichen
- **SUDO_CMD-Bereinigung**: Eliminiert doppelte Leerzeichen in Sub-Shell-Strings

#### Features aus Version 3.4
- **Vollständige Help-Text Dokumentation**: Alle Flags sind jetzt in `--help` dokumentiert
- **Tatsächliche Speicher-Puffer Verwendung**: `SPACE_BUFFER_PERCENT` wird korrekt verwendet
- **Vollständige Input-Validierung**: Alle numerischen Parameter mit Bereichsprüfung
- **Eliminierte doppelte Exit-Logs**: Cleanup nur bei Fehlern, normaler Exit einmalig
- **Start-Parallelisierung**: Auch Container-Start unterstützt Parallelisierung
- **Korrigierte Parallel-Logik**: Exit-Status-basierte Erkennung statt Container-Zählung
- **Cron-sichere PATH**: Automatischer PATH-Export für Cron-Umgebungen
- **Sichere Log-Berechtigungen**: 600-Berechtigungen und korrekte Besitzer-Zuweisung
- **Race-Condition-freie ACL-Tests**: Eindeutige Dateinamen mit PID + Timestamp

#### Features aus Version 3.3
- **Konfigurierbarer Speicher-Buffer**: `--buffer-percent` Flag für anpassbaren Puffer
- **Parallelisierung**: `--parallel` Flag für schnellere Container-Operationen
- **Verbesserte Farb-Behandlung**: Farben nur bei Terminal-Ausgabe
- **Robuste Input-Validierung**: Alle numerischen Parameter werden validiert
- **Idempotente trap-Deaktivierung**: Sauberer Exit-Handler ohne Duplikate

#### Features aus Version 3.2
- **Frühe Log-Initialisierung**: LOG_FILE wird vor ersten log_message Calls erstellt
- **Vollständige ANSI-Bereinigung**: Alle Docker-Ausgaben sind farbfrei in Log-Dateien
- **Input-Validierung**: Numerische Werte für Timeouts werden validiert
- **ACL-Fallback**: Automatische Deaktivierung bei nicht-unterstützten Dateisystemen
- **Optimiertes Cleanup**: Keine doppelten Abschluss-Logs mehr

#### Features aus Version 3.1
- **Einheitliche Logging-Funktion**: ANSI-bereinigt für Log-Dateien, keine Farbcodes mehr
- **Verbessertes Trap-Handling**: Unterscheidet zwischen normalem Exit und Signal/Fehler
- **Konfigurierbare Timeouts**: `--timeout-stop` und `--timeout-start` Flags
- **ACL/xattr-Unterstützung**: `--preserve-acl` für Synology-Systeme
- **ANSI-freie Docker-Logs**: `--ansi never` für saubere Log-Dateien

#### Features aus Version 3.0
- **Fail-Fast Settings**: `set -euo pipefail` verhindert unbemerkte Fehler
- **Signal-Handling**: Automatischer Container-Neustart bei Skript-Abbruch (CTRL+C, kill)
- **Robuste Stack-Erkennung**: Sichere Array-Behandlung für Stack-Namen mit Sonderzeichen
- **sudo-Optimierung**: Einmalige Privilegien-Prüfung, funktioniert als root oder normaler User
- **Intelligente Docker-Kommandos**: Wählbar zwischen `stop` (schnell) und `down` (vollständig)
- **Globale Exit-Codes**: Keine Kollision mit bash-internen Variablen

#### Features aus Version 2.0
- **Erweiterte Fehlerbehandlung**: Start-Fehler werden jetzt auch in FAILED_STACKS getrackt
- **Dynamische Benutzer-Erkennung**: Backup-Berechtigungen werden automatisch für den aktuellen Benutzer gesetzt
- **Detaillierte rsync Exit-Code Analyse**: Spezifische Fehlermeldungen für verschiedene rsync-Probleme
- **Erweiterte Backup-Verifikation**: Vergleicht sowohl Größe als auch Datei-/Ordneranzahl
- **Sichere Log-Dateien**: Temporäre umask-Anpassung für bessere Log-Sicherheit

## Installation

1. Prüfe Systemvoraussetzungen:
```bash
# Systemvoraussetzungen prüfen
command -v docker >/dev/null 2>&1 || { echo "❌ Docker nicht installiert. Installieren Sie Docker zuerst."; exit 1; }
command -v rsync >/dev/null 2>&1 || { echo "❌ rsync nicht installiert. Installation: sudo apt install rsync"; exit 1; }
command -v flock >/dev/null 2>&1 || { echo "❌ flock nicht installiert (Paket: util-linux)."; exit 1; }
echo "✅ Systemvoraussetzungen erfüllt"
```

2. Lade die Scripts herunter:
```bash
# Scripts direkt herunterladen
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/docker_backup.sh
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/test_rsync_fix.sh

# Optional: Deutsche Version herunterladen
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/docker_backup_de.sh

# Scripts ausführbar machen
chmod +x docker_backup.sh test_rsync_fix.sh
# Falls deutsche Version verwendet wird:
chmod +x docker_backup_de.sh
```

### Verfügbare Sprachversionen

Dieses Projekt bietet Scripts in mehreren Sprachen:

| Sprache | Script-Datei | Beschreibung |
|---------|--------------|--------------|
| **Englisch** | [`docker_backup.sh`](../../docker_backup.sh) | Hauptscript mit englischen Kommentaren und Meldungen |
| **Deutsch** | [`docker_backup_de.sh`](../../docker_backup_de.sh) | Deutsche Version mit deutschen Kommentaren und Meldungen |

**Hinweis**: Beide Versionen haben identische Funktionalität. Wähle basierend auf deiner Sprachpräferenz.

3. Teste die rsync-Fixes (empfohlen):
```bash
# Teste rsync-Kompatibilität vor erstem Backup
sudo ./test_rsync_fix.sh
```

## Verwendung

### Grundlegende Verwendung

```bash
# Interaktives Backup (mit Bestätigung)
./docker_backup.sh

# Vollautomatisches Backup (für Cron-Jobs)
./docker_backup.sh --auto

# Test-Modus (zeigt nur was gemacht würde)
./docker_backup.sh --dry-run

# Deutsche Version verwenden:
./docker_backup_de.sh --auto
./docker_backup_de.sh --dry-run
```

### Verfügbare Optionen

| Option | Beschreibung |
|--------|-------------|
| `--auto` | Automatische Ausführung ohne Bestätigung |
| `--dry-run` | Test-Modus ohne Änderungen |
| `--skip-backup` | Stoppt/startet nur Container (kein Backup) |
| `--no-verify` | Überspringt Backup-Verifikation |
| `--use-stop` | Verwendet `docker compose stop` statt `down` |
| `--preserve-acl` | Bewahrt ACLs und extended attributes (keine Verschlüsselung) |
| `--timeout-stop N` | Timeout für Container-Stop (10-3600s, Standard: 60s) |
| `--timeout-start N` | Timeout für Container-Start (10-3600s, Standard: 120s) |
| `--parallel N` | Parallele Jobs für Container-Ops (1-16, Standard: 1) |
| `--buffer-percent N` | Speicher-Puffer in Prozent (10-100%, Standard: 20%) |
| `--help, -h` | Zeigt Hilfe an |

### Beispiele

```bash
# Vollautomatisches Backup für Cron
./docker_backup.sh --auto

# Test ohne Änderungen
./docker_backup.sh --dry-run

# Nur Container-Neustart (z.B. nach Updates)
./docker_backup.sh --skip-backup --auto

# Backup ohne Verifikation (schneller)
./docker_backup.sh --auto --no-verify

# Schnelles Backup mit 'stop' statt 'down'
./docker_backup.sh --auto --use-stop

# Mit ACL-Bewahrung für UGREEN NAS (falls unterstützt)
./docker_backup.sh --auto --preserve-acl

# Angepasste Timeouts für große Stacks
./docker_backup.sh --auto --timeout-stop 90 --timeout-start 180

# Paralleles Backup mit mehr Speicher-Puffer
./docker_backup.sh --auto --parallel 4 --buffer-percent 30

# Hochperformantes Setup für große Installationen
./docker_backup.sh --auto --use-stop --parallel 8 --timeout-stop 45 --buffer-percent 25

# Vollautomatisches Backup mit allen neuen Features
./docker_backup.sh --auto --preserve-acl --parallel 4 --buffer-percent 15 --timeout-stop 90

# NEU in Version 3.5.1: SICHER mit Parallelisierung (kritische Fixes implementiert)
./docker_backup.sh --auto --parallel 4 --use-stop --buffer-percent 20

# NEU in Version 3.5.1: rsync-Fixes testen
./test_rsync_fix.sh

# Deutsche Version verwenden:
./docker_backup_de.sh --auto --parallel 4 --use-stop
./docker_backup_de.sh --dry-run --preserve-acl
```

### Neue Test-Tools (Version 3.5.1)

```bash
# Teste rsync-Fixes isoliert (empfohlen vor erstem Backup)
./test_rsync_fix.sh

# Erwartete Ausgabe:
# === RSYNC FIX VALIDATION TEST ===
# ✅ RSYNC-FIXES FUNKTIONIEREN!
# Funktionierende Flags: -a --delete --progress --stats --info=progress2
# === TEST ABGESCHLOSSEN ===
```

## Funktionsweise

### Schritt 1: Container stoppen
- Automatische Erkennung aller Docker-Stacks in `/volume1/docker-nas/stacks/`
- **Wählbares Shutdown**: `docker compose down` (Standard) oder `docker compose stop` (mit `--use-stop`)
- **Erweiterte Container-Status-Formatierung**: Farbige Symbole für Container-Aktionen
  - ▶ Container gestartet (grün)
  - ⏸ Container gestoppt (gelb)
  - 🗑 Container entfernt (rot)
  - 📦 Container erstellt (blau)
- Robuste Array-Behandlung für Stack-Namen mit Sonderzeichen
- Tracking welche Container liefen

### Schritt 2: Backup erstellen
- Konsistentes Backup mit `rsync`
- Quelle: `/volume1/docker-nas/`
- Ziel: `/volume2/backups/docker-nas_backups/`
- Inkrementelles Backup mit `--delete` Option

### Schritt 3: Container starten
- Alle Stacks werden mit `docker compose up -d` gestartet
- **Signal-Handler**: Automatische Wiederherstellung auch bei Skript-Abbruch (CTRL+C)
- Automatische Wiederherstellung auch bei Backup-Fehlern

## Konfiguration

Die wichtigsten Pfade können im Skript angepasst werden:

```bash
DATA_DIR="/pfad/zu/ihren/docker/daten"
STACKS_DIR="/pfad/zu/ihren/docker/stacks"
BACKUP_SOURCE="/pfad/zu/ihrem/docker"
BACKUP_DEST="/pfad/zu/ihrem/backup/ziel"
LOG_DIR="/pfad/zu/ihren/logs"
```

## Automatisierung mit Cron

Für regelmäßige Backups kannst du einen Cron-Job einrichten:

```bash
# Crontab bearbeiten
crontab -e

# Beispiel: Täglich um 2:00 Uhr (schnell mit --use-stop)
0 2 * * * /pfad/zum/docker_backup.sh --auto --use-stop >> /pfad/zu/logs/cron_backup.log 2>&1

# Beispiel: Wöchentlich sonntags um 3:00 Uhr (vollständig mit down)
0 3 * * 0 /pfad/zum/docker_backup.sh --auto >> /pfad/zu/logs/cron_backup.log 2>&1

# NEU Version 3.5.1: SICHERE Parallelisierung für Cron (kritische Fixes implementiert)
0 2 * * * /pfad/zum/docker_backup.sh --auto --parallel 4 --use-stop --buffer-percent 20 >> /pfad/zu/logs/cron_backup.log 2>&1

# Beispiel: Als root ausführen (automatische Erkennung)
0 2 * * * /pfad/zum/docker_backup.sh --auto --use-stop

# Beispiel: Mit ACL-Bewahrung für NAS (falls unterstützt)
0 2 * * * /pfad/zum/docker_backup.sh --auto --preserve-acl --timeout-stop 90

# Beispiel: Hochperformantes Setup für große Installationen (Version 3.5.1+)
0 2 * * * /pfad/zum/docker_backup.sh --auto --parallel 6 --use-stop --buffer-percent 25

# Beispiel: Tägliches Backup mit sicherer Parallelisierung (Version 3.5.1+)
0 2 * * * /pfad/zum/docker_backup.sh --auto --preserve-acl --parallel 4 --buffer-percent 15 2>&1 | logger -t docker_backup

# Beispiel: Wöchentliches vollständiges Backup (Sonntags um 1:00)
0 1 * * 0 /pfad/zum/docker_backup.sh --auto --preserve-acl --parallel 2 --timeout-stop 120 2>&1 | logger -t docker_backup_weekly

# Deutsche Version verwenden:
0 2 * * * /pfad/zum/docker_backup_de.sh --auto --parallel 4 --use-stop >> /pfad/zu/logs/cron_backup.log 2>&1
0 1 * * 0 /pfad/zum/docker_backup_de.sh --auto --preserve-acl --parallel 2 2>&1 | logger -t docker_backup_weekly
```

## Logging

Alle Aktionen werden protokolliert:
- Log-Dateien: `/pfad/zu/ihren/logs/docker_backup_YYYYMMDD_HHMMSS.log`
- Detaillierte Informationen über jeden Schritt
- Fehlerbehandlung und Warnungen

## Sicherheitsfeatures

### Umgebungsvalidierung
- Prüft Docker-Verfügbarkeit
- Validiert kritische Verzeichnisse
- Überprüft Speicherplatz
- **Intelligente sudo-Behandlung**: Funktioniert als root oder normaler User

### Fehlerbehandlung
- **Fail-Fast**: Skript bricht bei unbehandelten Fehlern sofort ab
- **Intelligentes Signal-Handler**: Unterscheidet zwischen normalem Exit und Abbruch
- **Konfigurierbare Timeouts**: Anpassbare Container-Stop/Start-Zeiten
- **Vollständige Input-Validierung**: Alle Parameter mit Bereichsprüfung (Version 3.4)
- Container werden immer neu gestartet (auch bei Backup-Fehlern)
- **ANSI-bereinigte Logs**: Keine Farbcodes in Log-Dateien
- **Bulletproof Parallelisierung**: Start + Stop unterstützen 1-16 parallele Jobs (Version 3.4)
- **Cron-sichere Ausführung**: Optimierte PATH-Reihenfolge für Cron-Umgebungen (Version 3.4.1)
- **Sichere Log-Dateien**: 600-Berechtigungen und korrekte Besitzer-Zuweisung (Version 3.4)
- **ACL-Tool-Kompatibilität**: Automatische Prüfung auf `setfacl` Verfügbarkeit (Version 3.4.1)
- **Robuste Stack-Namen**: NULL-Byte-Delimiter für sichere Sonderzeichen-Behandlung (Version 3.4.2)
- **BusyBox-Kompatibilität**: Automatischer numfmt-Fallback für schlanke Systeme (Version 3.4.2)
- Detaillierte Fehlerprotokollierung
- Robuste Exit-Codes für Automatisierung

### Backup-Verifikation
- Größenvergleich zwischen Quelle und Backup
- **Datei-/Ordneranzahl-Vergleich** für strukturelle Integrität
- **ACL/xattr-Unterstützung** für UGREEN NAS (optional, falls Dateisystem unterstützt)
- **Konfigurierbarer Speicher-Puffer**: Anpassbar von 10-100% für sichere Backups (Version 3.4.3)
- **Race-Condition-freie ACL-Tests**: Eindeutige Dateinamen (Version 3.4)
- **Intelligente ACL-Erkennung**: Prüfung auf Tool-Verfügbarkeit vor Verwendung (Version 3.4.1)
- **Universelle Byte-Formatierung**: Automatischer Fallback ohne numfmt-Abhängigkeit (Version 3.4.2)
- **Optimierte Parallelisierung**: Korrigierte Variable-Behandlung in Sub-Shells (Version 3.4.3)
- **Performance-optimierte Logs**: Entfernte human-readable Formatierung für bessere Geschwindigkeit (Version 3.4.3)
- **Shell-agnostische Robustheit**: Expliziter SUDO_CMD Export für maximale Kompatibilität (Version 3.4.4)
- Warnung bei Abweichungen > 5%
- Optional deaktivierbar mit `--no-verify`

## Best Practices

1. **🚨 UPGRADE AUF VERSION 3.5.1** - Kritische Sicherheitsfixes für Parallelisierung
2. **Teste zuerst mit --dry-run**
3. **Überwache die ersten Läufe** manuell
4. **Prüfe regelmäßig die Logs**
5. **Teste die Backup-Wiederherstellung** gelegentlich
6. **Halte genügend freien Speicherplatz** vor (mindestens 120% der Quellgröße)
7. **🔒 Verwende Parallelisierung sicher** - Nur mit Version 3.5.1 oder höher

### 🚨 KRITISCHE SICHERHEITSWARNUNG
**Versionen vor 3.5.1 haben kritische Bugs bei `--parallel N>1`:**
- ❌ **Stiller Backup-Ausfall** ohne Fehlermeldung
- ❌ **Doppelte Cron-Ausführung** möglich
- ❌ **Log-Race-Conditions** bei parallelen Jobs

**➜ SOFORT auf Version 3.5.1 upgraden für sichere Parallelisierung!**

## Troubleshooting

### Container starten nicht
```bash
# Prüfe Container-Status
docker ps -a

# Prüfe Logs eines spezifischen Containers
docker logs <container_name>

# Manueller Start eines Stacks
cd /volume1/docker-nas/stacks/<stack_name>
sudo docker compose up -d
```

### Backup-Fehler
```bash
# Prüfe Speicherplatz
df -h /volume2

# Prüfe Berechtigungen
ls -la /volume2/backups/

# Manuelles Backup testen
sudo rsync -avh --dry-run /volume1/docker-nas/ /volume2/backups/docker-nas_backups/
```

### Log-Analyse
```bash
# Neueste Log-Datei anzeigen
tail -f /volume1/docker-nas/logs/docker_backup_*.log

# Fehler in Logs suchen
grep -i error /volume1/docker-nas/logs/docker_backup_*.log
```

## Integration mit bestehenden Backup-Tools

Das Skript kann mit den vorhandenen Backup-Tools kombiniert werden:

```bash
# Nach dem lokalen Backup, Remote-Backup durchführen
./docker_backup.sh --auto && ./do_backup.sh --auto
```

## Wartung

### Log-Rotation
```bash
# Alte Logs löschen (älter als 30 Tage)
find /volume1/docker-nas/logs/ -name "docker_backup_*.log" -mtime +30 -delete
```

### Backup-Bereinigung
```bash
# Alte Backups manuell prüfen und löschen
ls -la /volume2/backups/docker-nas_backups/
```

---

## Erweiterte Features

### Performance-Optimierung

#### Parallelisierung nutzen (Version 3.5.1+):
```bash
# Für kleine Systeme (2-4 Container):
./docker_backup.sh --parallel 2

# Für mittlere Systeme (5-10 Container):
./docker_backup.sh --parallel 4

# Für große Systeme (10+ Container):
./docker_backup.sh --parallel 8
```

#### Schnelle Backups:
```bash
# Schnellster Modus (für tägliche Backups):
./docker_backup.sh --auto --use-stop --parallel 4 --no-verify

# Ausgewogener Modus (empfohlen):
./docker_backup.sh --auto --parallel 2 --buffer-percent 15
```

### Erweiterte Konfiguration

#### Timeouts anpassen:
```bash
# Für langsame Container (Datenbanken):
./docker_backup.sh --timeout-stop 180 --timeout-start 300

# Für schnelle Container:
./docker_backup.sh --timeout-stop 30 --timeout-start 60
```

#### Speicher-Management:
```bash
# Konservativer Modus (mehr Speicher-Puffer):
./docker_backup.sh --buffer-percent 30

# Aggressiver Modus (weniger Puffer):
./docker_backup.sh --buffer-percent 10
```

---

## Backup-Verschlüsselung

### Grundlagen der Backup-Verschlüsselung

Das Script erstellt unverschlüsselte Backups. Für Verschlüsselung verwenden Sie externe GPG-Pipelines **nach** Backup-Abschluss wie unten gezeigt.

### Verschlüsseltes Backup erstellen

#### Schritt 1: Normales Backup durchführen
```bash
# Erst normales Backup erstellen
./docker_backup.sh --auto
```

#### Schritt 2: Backup verschlüsseln
```bash
# Verschlüsseltes Backup erstellen (mit Passwort-Abfrage)
tar -czf - /volume2/@home/florian/Backups/docker-nas-backup-rsync/ | \
gpg --symmetric --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 \
--s2k-digest-algo SHA512 --s2k-count 65011712 --force-mdc \
> /volume2/@home/florian/Backups/docker-backup-encrypted_$(date +%Y%m%d_%H%M%S).tar.gz.gpg
```

#### Schritt 3: Unverschlüsseltes Backup löschen (optional)
```bash
# Nur wenn verschlüsseltes Backup erfolgreich erstellt wurde
rm -rf /volume2/@home/florian/Backups/docker-nas-backup-rsync/
```

### Verschlüsseltes Backup wiederherstellen

#### Schritt 1: Container stoppen
```bash
./docker_backup.sh --skip-backup --auto  # Stoppt nur Container
```

#### Schritt 2: Backup entschlüsseln und wiederherstellen
```bash
# Entschlüsseln und direkt wiederherstellen
gpg --decrypt /volume2/@home/florian/Backups/docker-backup-encrypted_YYYYMMDD_HHMMSS.tar.gz.gpg | \
tar -xzf - -C /

# Oder erst entschlüsseln, dann wiederherstellen
gpg --decrypt /volume2/@home/florian/Backups/docker-backup-encrypted_YYYYMMDD_HHMMSS.tar.gz.gpg \
> /tmp/backup_decrypted.tar.gz
tar -xzf /tmp/backup_decrypted.tar.gz -C /
rm /tmp/backup_decrypted.tar.gz
```

#### Schritt 3: Container starten
```bash
./docker_backup.sh --skip-backup --auto  # Startet nur Container
```

### Automatisierte verschlüsselte Backups

#### Passwort-Datei sicher erstellen:
```bash
# Passwort-Datei mit sicheren Berechtigungen
echo "IHR_SEHR_SICHERES_PASSWORT" | sudo tee /volume1/docker-nas/.backup_password
sudo chmod 600 /volume1/docker-nas/.backup_password
sudo chown root:root /volume1/docker-nas/.backup_password
```

#### Cron-Job für verschlüsselte Backups:
```bash
# Crontab bearbeiten
sudo crontab -e

# Tägliches verschlüsseltes Backup um 2:00 Uhr
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto && \
tar -czf - /volume2/@home/florian/Backups/docker-nas-backup-rsync/ | \
gpg --symmetric --cipher-algo AES256 --passphrase-file /volume1/docker-nas/.backup_password \
> /volume2/@home/florian/Backups/docker-backup-encrypted_$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz.gpg && \
rm -rf /volume2/@home/florian/Backups/docker-nas-backup-rsync/
```

### Sicherheits-Best-Practices für Verschlüsselung

1. **Starke Passwörter verwenden** (mindestens 20 Zeichen, gemischt)
2. **Passwort-Datei sicher speichern** (600 Berechtigungen, root-owned)
3. **Verschlüsselte Backups testen** (regelmäßige Wiederherstellungs-Tests)
4. **Alte verschlüsselte Backups rotieren** (automatische Bereinigung)
5. **Passwort-Backup** (sicher an anderem Ort aufbewahren)

---

## FAQ

### Allgemeine Fragen

#### Wie lange dauert ein Backup?
Das hängt von der Datenmenge ab:
- Erstes Backup: 1-5 Minuten pro GB
- Folge-Backups: 10-30 Sekunden (nur Änderungen)
- Beispiel: 10 GB → Erstes Mal 20 Min, danach 30 Sek

#### Kann ich das Script während eines laufenden Backups abbrechen?
Ja! Das Script hat einen Signal-Handler:
- CTRL+C → Container werden automatisch gestartet
- Kill-Signal → Cleanup wird ausgeführt
- Niemals einfach Terminal schließen!

#### Was passiert wenn ein Container nicht startet?
Das Script:
- ✅ Protokolliert den Fehler
- ✅ Versucht andere Container zu starten
- ✅ Gibt detaillierte Fehlermeldung aus
- ✅ Exit-Code zeigt Problem an

#### Kann ich einzelne Container vom Backup ausschließen?
Ja, mehrere Möglichkeiten:
1. Stack-Verzeichnis temporär umbenennen
2. docker-compose.yml temporär umbenennen
3. Script anpassen (für Experten)

### Technische Fragen

#### Warum werden Container gestoppt? Geht das nicht ohne?
Container-Stop ist notwendig für:
- ✅ **Konsistenz**: Keine laufenden Schreibvorgänge
- ✅ **Integrität**: Datenbanken sind konsistent
- ✅ **Vollständigkeit**: Alle Dateien sind verfügbar
- ❌ Live-Backup wäre inkonsistent und unzuverlässig

#### Was ist der Unterschied zwischen 'stop' und 'down'?
- `docker compose stop`: Stoppt Container, behält Netzwerke
- `docker compose down`: Stoppt Container, entfernt Netzwerke
- **Empfehlung**: `down` für vollständige Bereinigung (Standard)
- **Alternative**: `--use-stop` für schnelleren Neustart

#### Wie funktioniert die Parallelisierung?
Das Script kann mehrere Container gleichzeitig stoppen/starten:
- `--parallel 1`: Seriell (Standard, sicher)
- `--parallel 4`: 4 Container gleichzeitig (schneller)
- **Vorteil**: Deutlich schneller bei vielen Containern
- **Nachteil**: Höhere Systemlast

#### Was macht rsync genau?
rsync erstellt inkrementelle Backups:
- **Erste Ausführung**: Kopiert alles
- **Folge-Ausführungen**: Nur Änderungen
- `--delete`: Entfernt Dateien die in Quelle gelöscht wurden
- **Ergebnis**: Backup ist exakte Kopie der Quelle

### Anpassungs-Fragen

#### Kann ich das Script für andere Verzeichnisse nutzen?
Ja! Einfach die Pfade im Script ändern:
```bash
# Für beliebige Docker-Installation:
DATA_DIR="/ihr/pfad/data"
STACKS_DIR="/ihr/pfad/stacks"
BACKUP_SOURCE="/ihr/pfad"
BACKUP_DEST="/backup/ziel"
```

#### Funktioniert das Script auf Synology/QNAP?
Ja! Mit Pfad-Anpassungen:
- **Synology**: `/volume1/docker/` → `/volume1/docker/`
- **QNAP**: `/share/Container/` → `/share/Container/`
- **Wichtig**: Docker muss installiert sein

#### Kann ich mehrere Backup-Ziele haben?
Ja, mehrere Möglichkeiten:
1. Script mehrfach mit verschiedenen Zielen ausführen
2. Nach Backup mit rsync zu weiteren Zielen kopieren
3. Script erweitern (für Experten)

### Notfall-Fragen

#### Backup ist fehlgeschlagen, was nun?
Schritt-für-Schritt Diagnose:

1. **Log-Datei prüfen:**
   ```bash
   tail -50 /volume1/docker-nas/logs/docker_backup_*.log
   ```

2. **Häufige Fehler:**
   - `Docker ist nicht verfügbar` → `sudo systemctl start docker`
   - `Nicht genügend Speicherplatz` → Backup-Ziel prüfen
   - `Permission denied` → Berechtigungen prüfen

3. **Container manuell starten:**
   ```bash
   find /volume1/docker-nas/stacks -name "docker-compose.yml" -execdir docker compose up -d \;
   ```

#### Welche Version habe ich?
Version im Script prüfen:
```bash
head -10 docker_backup.sh | grep "Version"
# Sollte zeigen: Version 3.5.1
```

#### Muss ich von älteren Versionen auf 3.5.1 upgraden?
**JA, DRINGEND EMPFOHLEN!**
- **Kritischer Fix**: Funktionen-Export für Parallelisierung
- **Behebt**: Stillen Backup-Ausfall ohne Fehlermeldung
- **Sicherheit**: PID/Lock-Datei Schutz gegen doppelte Ausführung

---

### Version 3.5.1 - Sicherheitsfixes

**Implementierte Sicherheitsfixes (30. Juli 2025):**
- Funktionen-Export Fix: Implementiert (Zeilen 400 & 517)
- PID/Lock-Datei Schutz: Implementiert (Zeilen 82-89 & 207)
- Log-Race-Conditions: Behoben mit Variable-Export
- Sichere Temp-Verzeichnisse: mktemp -d implementiert

**Behobene Probleme in Version 3.5.1:**
- Funktionen-Export für Sub-Shells → Verhindert stillen Backup-Ausfall
- Atomarer Lock-Schutz → Keine doppelten Cron-Runs mehr
- Thread-sichere Log-Ausgabe → Formatierte Container-Status in parallelen Jobs
- Race-Condition-freie Temp-Verzeichnisse → Kollisionssichere Erstellung
- Vollständige Umgebungs-Variable-Verfügbarkeit → Robuste Sub-Shell-Ausführung
- Automatisches Lock-File-Cleanup → Saubere Ressourcen-Verwaltung

### Upgrade-Empfehlung
**Von Versionen vor 3.5.1 upgraden:**
- Kritisch: Verhindert stillen Backup-Ausfall bei Parallelisierung
- Kritisch: Behebt doppelte Cron-Ausführung
- Wichtig: Thread-sichere Log-Ausgabe
- Wichtig: Race-Condition-freie Temp-Verzeichnisse

Version 3.5.1 ist die erste vollständig sichere Version für `--parallel N>1`.