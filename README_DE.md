# 🐳 NAS Docker Backup Script

[![Version](https://img.shields.io/badge/version-3.4.9-blue.svg)](https://github.com/florian101010/NAS-Docker-Backup-rsync/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-orange.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](https://www.kernel.org/)
[![Downloads](https://img.shields.io/github/downloads/florian101010/NAS-Docker-Backup-rsync/total.svg)](https://github.com/florian101010/NAS-Docker-Backup-rsync/releases)
[![Stars](https://img.shields.io/github/stars/florian101010/NAS-Docker-Backup-rsync.svg)](https://github.com/florian101010/NAS-Docker-Backup-rsync/stargazers)

> **Die ultimative Docker-Backup-Lösung für NAS-Systeme** - Null Datenverlust, minimale Ausfallzeit, maximale Zuverlässigkeit.

**🎯 Perfekt für:** Home Labs • Kleine Unternehmen • Produktionsumgebungen • Jedes Docker-Setup auf NAS-Geräten

**🏆 Warum dieses Script wählen:** Herkömmliche Backup-Methoden **beschädigen Docker-Daten**, wenn Container laufen. Dieses Script löst das Problem durch intelligente Verwaltung Ihres gesamten Docker-Ökosystems - automatische Container-Erkennung, sanftes Stoppen für Datenkonsistenz, umfassende Backups von allem (Stacks, Volumes, Netzwerke, Konfigurationen) und nahtloser Service-Neustart.

**✅ Getestet & Optimiert für:** UGREEN NAS • kompatibel mit Synology • QNAP • Custom Linux NAS • Ubuntu • Debian

## 🚀 Hauptfunktionen

### 🐳 **Intelligente Docker-Verwaltung**
- **🔍 Automatische Container-Erkennung**: Findet alle Docker Compose Stacks und Container automatisch
- **⏸️ Sanftes Container-Herunterfahren**: Stoppt Container sicher, um Datenkorruption während des Backups zu verhindern
- **🔄 Intelligenter Neustart**: Startet alle Services nach Backup-Abschluss automatisch neu
- **📦 Vollständiges Stack-Backup**: Sichert Docker Compose Dateien, Volumes, Netzwerke und persistente Daten
- **🔧 Flexible Stopp-Modi**: Wählen Sie zwischen `docker compose stop` (schnell) oder `down` (vollständige Bereinigung)

### 🚀 **Performance & Zuverlässigkeit**
- **⚡ Parallele Verarbeitung**: Konfigurierbare parallele Container-Operationen (1-16 Jobs) für schnellere Backups
- **🛡️ Produktionssicher**: Thread-sichere Operationen mit atomarem Lock-Schutz
- **🎯 Intelligente Wiederherstellung**: Automatischer Container-Neustart auch bei Backup-Fehlern mit Signal-Behandlung
- **📊 Echtzeit-Überwachung**: Live Container-Status-Verfolgung mit farbcodierten Fortschrittsanzeigen

### 💾 **Erweiterte Backup-Funktionen**
- **🔄 Inkrementelle Backups**: rsync-basiert mit intelligenter Flag-Validierung und mehrstufigem Fallback
- **🔐 Backup-Verschlüsselung**: GPG-basierte Verschlüsselungsunterstützung für sichere Backup-Speicherung
- **✅ Backup-Verifizierung**: Automatische Überprüfung der Backup-Integrität und Vollständigkeit
- **📈 Umfassendes Logging**: Detaillierte Logs mit ANSI-freier Ausgabe und race-condition-freiem parallelem Logging

### ⚙️ **Enterprise-Grade Konfiguration**
- **🎛️ Hochgradig Konfigurierbar**: Umfangreiche Kommandozeilen-Optionen für Timeouts, Puffer und Verhalten
- **🕒 Flexible Zeitplanung**: Perfekt für Cron-Automatisierung mit verschiedenen Timing-Optionen
- **🔒 Sicherheitsfeatures**: Fail-Fast-Design, Input-Validierung und sichere Berechtigungsbehandlung
- **🌐 NAS-Optimiert**: Getestet auf UGREEN (DXP2800) - (TBC) kompatibel mit Synology, QNAP und benutzerdefinierten Linux-NAS-Systemen

## 📋 Anforderungen

- **OS**: Linux (getestet auf Ubuntu, Debian, UGREEN NAS DXP2800)
- **Shell**: Bash 4.0+
- **Tools**: Docker, docker-compose, rsync, flock
- **Berechtigungen**: sudo-Zugriff oder Root-Ausführung

## ⚡ Schnellstart (5 Minuten)

### 1️⃣ Ein-Zeilen-Installation
```bash
# Download und Setup (copy-paste bereit)
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/docker_backup.sh && \
chmod +x docker_backup.sh && \
echo "✅ Installation abgeschlossen! Pfade im Script bearbeiten, dann ausführen: ./docker_backup.sh --dry-run"
```

### 2️⃣ Ihre Pfade Konfigurieren
Bearbeiten Sie diese 5 Zeilen in [`docker_backup.sh`](docker_backup.sh) (Zeilen 25-37):
```bash
DATA_DIR="/volume1/docker-nas/data"          # Ihr Docker-Datenverzeichnis
STACKS_DIR="/volume1/docker-nas/stacks"      # Ihre Docker Compose Dateien
BACKUP_SOURCE="/volume1/docker-nas"          # Quellverzeichnis für Backup
BACKUP_DEST="/volume2/backups/docker-backup" # Wo Backups gespeichert werden
LOG_DIR="/volume1/docker-nas/logs"           # Log-Datei-Speicherort
```

### 3️⃣ Testen & Ausführen
```bash
# Zuerst testen (sicher - keine Änderungen)
./docker_backup.sh --dry-run

# Interaktives Backup ausführen
./docker_backup.sh

# Automatisiertes Backup (für Cron)
./docker_backup.sh --auto
```

## 🌍 Sprachunterstützung

| Sprache | Script-Datei | Status |
|---------|--------------|--------|
| **🇺🇸 Englisch** | [`docker_backup.sh`](docker_backup.sh) | ✅ Hauptversion |
| **🇩🇪 Deutsch** | [`docker_backup_de.sh`](docker_backup_de.sh) | ✅ Vollständig übersetzt |

## 📊 Verwendungsbeispiele

```bash
# 🧪 Test-Modus (sicher - zeigt was passieren würde)
./docker_backup.sh --dry-run

# 🎯 Interaktives Backup mit Bestätigung
./docker_backup.sh

# 🤖 Automatisiertes Backup (perfekt für Cron)
./docker_backup.sh --auto

# ⚡ Hochleistungs-paralleles Backup
./docker_backup.sh --auto --parallel 4 --use-stop

# 🔒 Sicheres Backup mit Verschlüsselung
./docker_backup.sh --auto --preserve-acl
```

## 📖 Detaillierte Konfiguration

**💡 Profi-Tipps:**
- Immer zuerst mit `--dry-run` testen
- Stellen Sie sicher, dass das Backup-Ziel 2x Quellgröße verfügbar hat
- Verwenden Sie `--parallel 4` für schnellere Backups auf leistungsstarken Systemen
- Richten Sie Cron für automatisierte tägliche Backups ein

### Kommandozeilen-Optionen

| Option | Beschreibung | Standard |
|--------|--------------|----------|
| `--auto` | Automatisierte Ausführung ohne Bestätigung | Interaktiv |
| `--dry-run` | Test-Modus ohne Änderungen | Deaktiviert |
| `--parallel N` | Parallele Container-Operationen (1-16) | 1 |
| `--use-stop` | Verwende `stop` anstatt `down` | `down` |
| `--timeout-stop N` | Container-Stopp-Timeout (10-3600s) | 60s |
| `--timeout-start N` | Container-Start-Timeout (10-3600s) | 120s |
| `--buffer-percent N` | Speicher-Puffer-Prozentsatz (10-100%) | 20% |
| `--preserve-acl` | ACLs und erweiterte Attribute bewahren | Aktiviert |
| `--skip-backup` | Nur Container neu starten | Deaktiviert |
| `--no-verify` | Backup-Verifizierung überspringen | Deaktiviert |

## 🔄 Automatisierung mit Cron

### Sichere parallele Cron-Beispiele (v3.4.9+)

```bash
# Tägliches schnelles Backup mit Parallelisierung
0 2 * * * /pfad/zu/docker_backup.sh --auto --parallel 4 --use-stop

# Wöchentliches vollständiges Backup
0 1 * * 0 /pfad/zu/docker_backup.sh --auto --parallel 2 --preserve-acl

# Hochleistungs-Setup für große Installationen
0 2 * * * /pfad/zu/docker_backup.sh --auto --parallel 6 --buffer-percent 25
```

## 🛡️ Sicherheitsfeatures

### Fail-Safe Design
- **Fail-Fast**: `set -euo pipefail` verhindert unbemerkte Fehler
- **Signal-Behandlung**: Automatische Container-Wiederherstellung bei Unterbrechung (CTRL+C, kill)
- **Input-Validierung**: Alle Parameter mit Bereichsprüfung validiert
- **Atomare Operationen**: Lock-geschützte Ausführung verhindert Race-Conditions

### Backup-Verifizierung
- Verzeichnisgrößen-Vergleich mit konfigurierbarer Toleranz
- Datei- und Verzeichnisanzahl-Verifizierung
- ACL- und erweiterte Attribute-Unterstützung (wenn verfügbar)
- Detaillierte Fehlerberichterstattung mit spezifischer rsync-Exit-Code-Analyse
- GPG-Verschlüsselungsunterstützung für sichere Backup-Speicherung

## 📊 Überwachung & Logging

### Log-Dateien
- Speicherort: `/pfad/zu/ihren/logs/docker_backup_YYYYMMDD_HHMMSS.log`
- ANSI-freie Ausgabe für saubere Log-Dateien
- Detaillierter Container-Status mit farbcodierter Terminal-Ausgabe
- Thread-sicheres Logging für parallele Operationen

### Container-Status-Indikatoren
- ▶ Container gestartet (grün)
- ⏸ Container gestoppt (gelb)
- 🗑 Container entfernt (rot)
- 📦 Container erstellt (blau)

## 🔧 Fehlerbehebung

### Häufige Probleme

**Container starten nicht:**
```bash
# Container-Status prüfen
docker ps -a

# Spezifische Container-Logs prüfen
docker logs <container_name>

# Manueller Stack-Neustart
cd /pfad/zu/ihren/stacks/<stack_name>
sudo docker compose up -d
```

**Backup-Fehler:**
```bash
# Verfügbaren Speicherplatz prüfen
df -h /pfad/zu/backup/ziel

# rsync manuell testen
sudo rsync -av --dry-run /pfad/zu/quelle/ /pfad/zu/ziel/
```

**Berechtigungsprobleme:**
```bash
# Backup-Ziel-Berechtigungen prüfen
ls -la /pfad/zu/backup/ziel

# Berechtigungen korrigieren falls nötig
sudo chown -R $(whoami):$(id -gn) /pfad/zu/backup/ziel
```

## 🔐 Backup-Verschlüsselung

Das Script unterstützt Backup-Verschlüsselung für sichere Speicherung sensibler Daten.

### Schnelle Verschlüsselungs-Einrichtung

```bash
# 1. Normales Backup erstellen
./docker_backup.sh --auto

# 2. Backup mit GPG verschlüsseln
tar -czf - /pfad/zu/backup/ | \
gpg --symmetric --cipher-algo AES256 \
> backup_encrypted_$(date +%Y%m%d_%H%M%S).tar.gz.gpg

# 3. Sichere Passwort-Speicherung für Automatisierung
echo "IHR_SICHERES_PASSWORT" | sudo tee /pfad/zu/.backup_password
sudo chmod 600 /pfad/zu/.backup_password
```

### Automatisierte verschlüsselte Backups

```bash
# Cron-Job für tägliche verschlüsselte Backups
0 2 * * * /pfad/zu/docker_backup.sh --auto && \
tar -czf - /pfad/zu/backup/ | \
gpg --symmetric --cipher-algo AES256 --passphrase-file /pfad/zu/.backup_password \
> /pfad/zu/backup_encrypted_$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz.gpg
```

### Verschlüsselte Backups wiederherstellen

```bash
# Entschlüsseln und wiederherstellen
gpg --decrypt backup_encrypted_YYYYMMDD_HHMMSS.tar.gz.gpg | tar -xzf - -C /
```

**📖 Für detaillierte Verschlüsselungsdokumentation siehe [Backup-Verschlüsselungsanleitung](docs/DE/ANLEITUNG_DE.md#backup-verschlüsselung)**

## 🤝 Mitwirken

Wir begrüßen Beiträge! Bitte siehe [CONTRIBUTING.md](CONTRIBUTING.md) für Richtlinien.

### Entwicklungsumgebung einrichten
```bash
git clone https://github.com/florian101010/NAS-Docker-Backup-rsync.git
cd NAS-Docker-Backup-rsync
chmod +x docker_backup.sh test_rsync_fix.sh
```

## 📄 Lizenz

Dieses Projekt ist unter der MIT-Lizenz lizenziert - siehe [LICENSE](LICENSE) Datei für Details.

## 🎯 Anwendungsfälle & Erfolgsgeschichten

**Perfekt für diese Szenarien:**
- 🏠 **Home Labs**: Schützen Sie Ihre selbst gehosteten Services (Plex, Nextcloud, etc.)
- 🏢 **Kleine Unternehmen**: Sichern Sie kritische Docker-Anwendungen sicher
- 🔧 **Entwicklung**: Konsistente Backups von Entwicklungsumgebungen
- 📊 **Produktion**: Enterprise-Grade-Backup für Produktions-Docker-Stacks

## 🙏 Danksagungen

- ✅ **Getestet & Optimiert**: UGREEN NAS DXP2800
- 🌟 **Open Source**: MIT-lizenziert für maximale Flexibilität

## 📈 Versionshistorie

Siehe [CHANGELOG.md](CHANGELOG.md) für detaillierte Release-Notizen.

## 📚 Dokumentation

### Schnellstart
- 🚀 **[Schnellstart-Anleitung (Deutsch)](QUICKSTART_DE.md)** - In 5 Minuten zum ersten Backup
- 🚀 **[Quick Start Guide (English)](QUICKSTART.md)** - Get up and running in 5 minutes

### Detaillierte Anleitungen
- 🇩🇪 **[Deutsche Anleitung](docs/DE/ANLEITUNG_DE.md)** - Vollständige Anleitung auf Deutsch
- 🇺🇸 **[English Manual](docs/EN/MANUAL_EN.md)** - Complete user guide in English

### Automatisierung
- 🇩🇪 **[Cron Automatisierung (DE)](docs/DE/CRON_AUTOMATISIERUNG_DE.md)** - Automatisierte Backups einrichten
- 🇺🇸 **[Cron Automation (EN)](docs/EN/CRON_AUTOMATION_EN.md)** - Setting up automated backups

### Entwicklung
- 🛠️ **[Contributing Guide](CONTRIBUTING.md)** - Wie Sie zu diesem Projekt beitragen können
- 🔒 **[Security Policy](SECURITY.md)** - Sicherheitsrichtlinien und Meldungen

---

## 📸 Screenshots

### Backup-Prozess in Aktion

<img width="2764" height="2950" alt="100_screenshot" src="https://github.com/user-attachments/assets/ab6a50bc-f63f-40e1-b66e-3ea3bd81e997" />
<img width="2764" height="2950" alt="300_screenshot" src="https://github.com/user-attachments/assets/93045756-e1f7-4011-8d6d-81f6103d4263" />
<img width="2764" height="2950" alt="200_screenshot" src="https://github.com/user-attachments/assets/35878374-269e-4404-a005-921dca27d8b8" />