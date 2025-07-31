# 🐳 NAS Docker Backup Script

<div align="center">

## 🌍 Choose Your Language / Sprache wählen

[![English](https://img.shields.io/badge/🇺🇸_English-blue?style=for-the-badge)](README.md)
[![Deutsch](https://img.shields.io/badge/🇩🇪_Deutsch-red?style=for-the-badge)](#deutsche-version)

---

</div>

## Deutsche Version

[![Version](https://img.shields.io/badge/version-3.5.7-blue.svg)](https://github.com/florian101010/NAS-Docker-Backup-rsync/releases)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-4.0%2B-orange.svg)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)](https://www.kernel.org/)
[![Downloads](https://img.shields.io/github/downloads/florian101010/NAS-Docker-Backup-rsync/total.svg)](https://github.com/florian101010/NAS-Docker-Backup-rsync/releases)
[![Stars](https://img.shields.io/github/stars/florian101010/NAS-Docker-Backup-rsync.svg)](https://github.com/florian101010/NAS-Docker-Backup-rsync/stargazers)

> **Automatisches Docker Backup-Script für NAS-Systeme** - stoppt Container automatisch & sicher, sichert Daten mit rsync und startet die Container wieder

**🎯 Perfekt für:** Home Labs • Kleine Unternehmen • Produktionsumgebungen • Jedes Docker-Setup auf NAS-Geräten

**🏆 Warum dieses Script wählen:** Herkömmliche Backup-Methoden **beschädigen Docker-Daten**, wenn Container laufen. Dieses Script löst das Problem durch intelligente Verwaltung Ihres gesamten Docker-Ökosystems - automatische Container-Erkennung, sanftes Stoppen für Datenkonsistenz, umfassende Backups von allem (Stacks, Volumes, persistente Daten) und nahtloser Service-Neustart (Netzwerke werden bei `down` von Compose neu erstellt; bei `--use-stop` bleiben Netzwerke erhalten).

**✅ Entwickelt für Kompatibilität:** Funktioniert perfekt auf UGREEN NAS und ist für hohe Kompatibilität mit Synology, QNAP, eigenen Linux-NAS-Setups, Ubuntu und Debian ausgelegt.
---

## Inhaltsverzeichnis

- [🚀 Hauptfunktionen](#-hauptfunktionen)
- [⚠️ Wichtiger Haftungsausschluss](#️-wichtiger-haftungsausschluss)
- [📋 Anforderungen](#-anforderungen)
- [⚡ Schnellstart (5 Minuten)](#-schnellstart-5-minuten)
- [🌍 Sprachunterstützung](#-sprachunterstützung)
- [📊 Verwendungsbeispiele](#-verwendungsbeispiele)
- [📖 Detaillierte Konfiguration](#-detaillierte-konfiguration)
- [🔄 Automatisierung mit Cron](#-automatisierung-mit-cron)
- [🛡️ Sicherheitsfeatures](#️-sicherheitsfeatures)
- [📊 Überwachung & Logging](#-überwachung--logging)
- [🔧 Fehlerbehebung](#-fehlerbehebung)
- [🔐 Backup-Verschlüsselung](#-backup-verschlüsselung)
- [🤝 Mitwirken](#-mitwirken)
- [📄 Lizenz](#-lizenz)
- [🎯 Anwendungsfälle](#-anwendungsfälle)
- [🙏 Danksagungen](#-danksagungen)
- [📈 Versionshistorie](#-versionshistorie)
- [📚 Dokumentation](#-dokumentation)
- [📸 Screenshots](#-screenshots)

---

## � Hauptfunktionen

### 🐳 **Intelligente Docker-Verwaltung**
- **🔍 Automatische Container-Erkennung**: Findet alle Docker Compose Stacks und Container automatisch
- **⏸️ Sanftes Container-Herunterfahren**: Stoppt Container sicher, um Datenkorruption während des Backups zu verhindern
- **🔄 Intelligenter Neustart**: Startet alle Services nach Backup-Abschluss automatisch neu
- **📦 Vollständiges Stack-Backup**: Sichert Docker Compose Dateien, Volumes und persistente Daten (Netzwerke werden bei `down` von Compose neu erstellt; bei `--use-stop` bleiben Netzwerke erhalten)
- **🔧 Flexible Stopp-Modi**: Wählen Sie zwischen `docker compose stop` (schnell) oder `down` (vollständige Bereinigung)

### 🚀 **Performance & Zuverlässigkeit**
- **⚡ Parallele Verarbeitung**: Konfigurierbare parallele Container-Operationen (1-16 Jobs) für schnellere Backups
- **🛡️ Produktionssicher**: Thread-sichere Operationen mit atomarem Lock-Schutz
- **🎯 Intelligente Wiederherstellung**: Automatischer Container-Neustart auch bei Backup-Fehlern mit Signal-Behandlung
- **📊 Echtzeit-Überwachung**: Live Container-Status-Verfolgung mit farbcodierten Fortschrittsanzeigen

### 💾 **Erweiterte Backup-Funktionen**
- **🔄 rsync-basierte Synchronisation**: Standard-rsync-Verhalten mit intelligenter Flag-Validierung und mehrstufigem Fallback
- **🔐 Externe Verschlüsselung**: Das Skript erstellt unverschlüsselte Backups. Verschlüsselung erfolgt über externe GPG-Pipelines nach Backup-Abschluss (Beispiele enthalten)
- **✅ Backup-Verifizierung**: Automatische Überprüfung der Backup-Integrität und Vollständigkeit
- **📈 Umfassendes Logging**: Detaillierte Logs mit ANSI-freier Ausgabe und race-condition-freiem parallelem Logging

### ⚙️ **Enterprise-Grade Konfiguration**
- **🎛️ Hochgradig Konfigurierbar**: Umfangreiche Kommandozeilen-Optionen für Timeouts, Puffer und Verhalten
- **🕒 Flexible Zeitplanung**: Perfekt für Cron-Automatisierung mit verschiedenen Timing-Optionen
- **🔒 Sicherheitsfeatures**: Fail-Fast-Design, Input-Validierung und sichere Berechtigungsbehandlung
- **🌐 NAS-Optimiert**: Ausführlich auf UGREEN NAS (DXP2800) getestet. Entwickelt für hohe Kompatibilität mit Synology, QNAP und anderen benutzerdefinierten Linux-NAS-Systemen.

## ⚠️ Wichtiger Haftungsausschluss

**Dieses Script wird "wie es ist" ohne jegliche Gewährleistung bereitgestellt.** Testen Sie immer gründlich in einer sicheren Umgebung und führen Sie unabhängige Backups durch, bevor Sie es produktiv einsetzen. Die Autoren übernehmen keine Verantwortung für Datenverlust, Systemschäden oder Serviceunterbrechungen, die durch die Nutzung dieses Scripts entstehen können.

## 📋 Anforderungen

- **OS**: Linux (getestet auf Ubuntu, Debian, UGREEN NAS DXP2800)
- **Shell**: Bash 4.0+
- **Tools**: Docker Compose v2 (`docker compose`), rsync, flock
- **Berechtigungen**: sudo-Zugriff oder Root-Ausführung

## ⚡ Schnellstart (5 Minuten)

### 1️⃣ Ein-Zeilen-Installation mit Systemprüfung

**🇩🇪 Deutsche Version:**
```bash
# Systemvoraussetzungen prüfen
command -v docker >/dev/null 2>&1 || { echo "❌ Docker nicht installiert. Installieren Sie Docker zuerst."; exit 1; }
command -v rsync >/dev/null 2>&1 || { echo "❌ rsync nicht installiert. Installation: sudo apt install rsync"; exit 1; }
command -v flock >/dev/null 2>&1 || { echo "❌ flock nicht installiert (verhindert doppelte Backups). Installation: sudo apt install util-linux"; exit 1; }
echo "✅ Systemvoraussetzungen erfüllt"

# Download und Installation
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/docker_backup_de.sh && \
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/test_rsync_fix_de.sh && \
chmod +x docker_backup_de.sh test_rsync_fix_de.sh && \
echo "✅ Installation abgeschlossen! Weiter: Kompatibilität testen mit ./test_rsync_fix_de.sh, dann Pfade im Script konfigurieren."
```

**🇺🇸 English Version:**
```bash
# Check system requirements first
command -v docker >/dev/null 2>&1 || { echo "❌ Docker not installed. Install Docker first."; exit 1; }
command -v rsync >/dev/null 2>&1 || { echo "❌ rsync not installed. Install: sudo apt install rsync"; exit 1; }
command -v flock >/dev/null 2>&1 || { echo "❌ flock not installed (prevents overlapping backups). Install: sudo apt install util-linux"; exit 1; }
echo "✅ System requirements met"

# Download and install
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/docker_backup.sh && \
wget https://raw.githubusercontent.com/florian101010/NAS-Docker-Backup-rsync/main/test_rsync_fix.sh && \
chmod +x docker_backup.sh test_rsync_fix.sh && \
echo "✅ Installation complete! Next: Test compatibility with ./test_rsync_fix.sh, then configure your paths in the script."
```

### 2️⃣ Ihre Pfade Konfigurieren
Öffnen Sie `docker_backup_de.sh` mit einem Texteditor (z. B. `nano`) und passen Sie die folgenden Pfade an Ihre Systemkonfiguration an.

**⚠️ Wichtig:** Führen Sie nach dem Speichern Ihrer Änderungen immer einen Testlauf mit `./docker_backup_de.sh --dry-run` durch, um sicherzustellen, dass Ihre Konfiguration gültig ist.

```bash
# Beispielkonfiguration:
DATA_DIR="/volume1/docker-nas/data"          # Ihr Docker-Datenverzeichnis
STACKS_DIR="/volume1/docker-nas/stacks"      # Ihre Docker Compose Dateien
BACKUP_SOURCE="/volume1/docker-nas"          # Quellverzeichnis für Backup
BACKUP_DEST="/volume2/backups/docker-nas-backup" # Wo Backups gespeichert werden
LOG_DIR="/volume1/docker-nas/logs"           # Log-Datei-Speicherort
```

### 3️⃣ Testen & Ausführen
```bash
# Zuerst testen (sicher - keine Änderungen)
./docker_backup_de.sh --dry-run

# Interaktives Backup ausführen
./docker_backup_de.sh

# Automatisiertes Backup (für Cron)
./docker_backup_de.sh --auto
```

### 4️⃣ Nächste Schritte Checkliste
Nach der Installation folgen Sie diesen Schritten in der Reihenfolge:

**✅ Sofortige Einrichtung (Erforderlich):**
1. **Kompatibilität testen**: `./test_rsync_fix_de.sh`
2. **Pfade konfigurieren**: Script mit Ihren NAS-Pfaden bearbeiten
3. **Konfiguration testen**: `./docker_backup_de.sh --dry-run`
4. **Erstes Backup**: `./docker_backup_de.sh` (interaktiv)

**⚙️ Produktions-Setup (Empfohlen):**

5. **Automatisierung einrichten**: Zu Cron für tägliche Backups hinzufügen
6. **Wiederherstellung testen**: Überprüfen Sie, dass Sie aus Backup wiederherstellen können
7. **Logs überwachen**: Backup-Logs regelmäßig prüfen

**🔒 Sicherheits-Setup (Optional):**

8. **ACLs bewahren**: `--preserve-acl` für Dateiberechtigungen verwenden (keine Verschlüsselung)
9. **Backup-Speicherort sichern**: Stellen Sie sicher, dass Backup-Ziel korrekte Berechtigungen hat

## 🌍 Sprachunterstützung

| Sprache | Script-Datei | Status |
|---------|--------------|--------|
| **🇺🇸 Englisch** | [`docker_backup.sh`](docker_backup.sh) | ✅ Hauptversion |
| **🇩🇪 Deutsch** | [`docker_backup_de.sh`](docker_backup_de.sh) | ✅ Vollständig übersetzt |

## 📊 Verwendungsbeispiele

```bash
# 🧪 Test-Modus (sicher - zeigt was passieren würde)
./docker_backup_de.sh --dry-run

# 🎯 Interaktives Backup mit Bestätigung
./docker_backup_de.sh

# 🤖 Automatisiertes Backup (perfekt für Cron)
./docker_backup_de.sh --auto

# ⚡ Hochleistungs-paralleles Backup
./docker_backup_de.sh --auto --parallel 4 --use-stop

# 📋 Backup mit ACL-Bewahrung (keine Verschlüsselung)
./docker_backup_de.sh --auto --preserve-acl
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
| `--preserve-acl` | ACLs und erweiterte Attribute bewahren (keine Verschlüsselung) | Aktiviert |
| `--skip-backup` | Nur Container neu starten | Deaktiviert |
| `--no-verify` | Backup-Verifizierung überspringen | Verifizierung ist **AN** per Standard |

## 🔄 Automatisierung mit Cron

### Sichere parallele Cron-Beispiele (v3.5.1+)

```bash
# Tägliches schnelles Backup mit Parallelisierung
0 2 * * * /pfad/zu/docker_backup_de.sh --auto --parallel 4 --use-stop

# Wöchentliches vollständiges Backup
0 1 * * 0 /pfad/zu/docker_backup_de.sh --auto --parallel 2 --preserve-acl

# Hochleistungs-Setup für große Installationen
0 2 * * * /pfad/zu/docker_backup_de.sh --auto --parallel 6 --buffer-percent 25
```

## 🛡️ Sicherheitsfeatures

### Fail-Safe Design
- **Fail-Fast**: `set -euo pipefail` verhindert unbemerkte Fehler
- **Signal-Behandlung**: Automatische Container-Wiederherstellung bei Unterbrechung (CTRL+C, kill)
- **Input-Validierung**: Alle Parameter mit Bereichsprüfung validiert
- **Atomare Operationen**: Lock-geschützte Ausführung verhindert Race-Conditions

### Erforderliche Dependencies
- **`flock`**: Sorgt für exklusive Ausführung (keine Überschneidungen) und thread-sicheres Logging bei parallelisierten Operationen

### Backup-Verifizierung
- Verzeichnisgrößen-Vergleich mit konfigurierbarer Toleranz
- Datei- und Verzeichnisanzahl-Verifizierung
- ACL- und erweiterte Attribute-Unterstützung (wenn verfügbar)
- Detaillierte Fehlerberichterstattung mit spezifischer rsync-Exit-Code-Analyse
- Externe Verschlüsselung via GPG-Pipelines nach Backup-Abschluss (nicht im Skript integriert)

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

**Fehlende Dependencies:**
```bash
# flock nicht gefunden Fehler
sudo apt install util-linux  # Ubuntu/Debian
sudo yum install util-linux  # CentOS/RHEL

```

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

### Dependency-Validierung

**Schnelle Smoke-Tests:**
```bash
# Validiere flock funktioniert (Mutex-Simulation)
LOCK=/tmp/test.lock; exec 9>"$LOCK"; flock -n 9 && echo "✅ flock OK"
```

## 🔐 Backup-Verschlüsselung

Das Script erstellt unverschlüsselte Backups. Für Verschlüsselung verwenden Sie externe GPG-Pipelines **nach** Backup-Abschluss wie unten gezeigt.

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

## 🎯 Anwendungsfälle

**Perfekt für diese Szenarien:**
- 🏠 **Home Labs**: Schützen Sie Ihre selbst gehosteten Services (Plex, Nextcloud, etc.)
- 🏢 **Kleine Unternehmen**: Sichern Sie kritische Docker-Anwendungen sicher
- 🔧 **Entwicklung**: Konsistente Backups von Entwicklungsumgebungen

## 🙏 Danksagungen

- 🛠️ **Basiert auf rsync**: Angetrieben vom robusten [rsync-Projekt](https://rsync.samba.org/) für zuverlässige Dateisynchronisation
- 🐳 **Docker-Integration**: Nutzt das [Docker](https://www.docker.com/) und [Docker Compose](https://docs.docker.com/compose/) Ökosystem
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

<img width="1672" height="2886" alt="Screenshot, der die Initialisierung des Skripts und den Stopp-Prozess der Container zeigt" src="https://github.com/user-attachments/assets/c93101ed-8cf3-4d9a-bdf1-2f8d916adf4f" />
<img width="1672" height="2886" alt="Screenshot, der den rsync-Backup-Prozess und die Verifizierungsschritte zeigt" src="https://github.com/user-attachments/assets/c41afa70-a1cb-4983-b88c-d6f3bf144232" />
<img width="1672" height="2886" alt="Screenshot, der den Start-Prozess der Container und den abschließenden Zusammenfassungsbericht zeigt" src="https://github.com/user-attachments/assets/0357fff5-9466-4f83-b2a4-85f452d290a9" />
