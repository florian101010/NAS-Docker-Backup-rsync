# 🚀 Docker Backup Script - Quickstart Guide

> **In 5 Minuten zum ersten Backup!**
> Version 3.5.1 "Production Ready"
> **✅ GETESTET UND BESTÄTIGT FUNKTIONAL - 30. Juli 2025**

---

## ⚡ Sofort loslegen

### 📋 **Was du brauchst:**
- ✅ Linux-System mit Docker, rsync, flock
- ✅ Docker-Container laufen bereits
- ✅ 5 Minuten Zeit

### 🎯 **4 Schritte zum Backup (NEU mit rsync-Test):**

#### **Schritt 1: Scripts herunterladen und vorbereiten**
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

# Hilfe anzeigen (optional)
./docker_backup.sh --help
# Oder für deutsche Version:
./docker_backup_de.sh --help
```

### 🌍 **Verfügbare Sprachversionen:**

| Sprache | Script | Kommentare & Meldungen |
|---------|--------|------------------------|
| **🇺🇸 Englisch** | `docker_backup.sh` | Englische Kommentare und Benutzermeldungen |
| **🇩🇪 Deutsch** | `docker_backup_de.sh` | Deutsche Kommentare und Benutzermeldungen |

**💡 Beide Versionen haben identische Funktionalität - wähle deine bevorzugte Sprache!**

#### **Schritt 2: rsync-Fixes testen (NEU!)**
```bash
# Teste die neuen rsync-Fixes isoliert
sudo ./test_rsync_fix.sh

# Erwartete Ausgabe:
# ✅ RSYNC-FIXES FUNKTIONIEREN!
```

#### **Schritt 3: Erstes Test-Backup**
```bash
# Trockenlauf (zeigt nur was passieren würde)
sudo ./docker_backup.sh --dry-run

# Echtes Backup mit Bestätigung
sudo ./docker_backup.sh

# Oder mit deutscher Version:
sudo ./docker_backup_de.sh --dry-run
sudo ./docker_backup_de.sh
```

#### **Schritt 4: Automatisierung einrichten**
```bash
# Cron-Job für tägliches Backup um 2:00 Uhr
sudo crontab -e

# Diese Zeile hinzufügen:
0 2 * * * /path/to/docker_backup.sh --auto
```

**🎉 Fertig! Dein Backup läuft jetzt automatisch.**

---

## 🔧 Schnelle Anpassungen

### 📁 **Pfade anpassen (falls nötig)**

Öffne `docker_backup.sh` (oder `docker_backup_de.sh` für deutsche Version) und ändere diese Zeilen:

```bash
# Zeile 19-24 im Script:
DATA_DIR="/path/to/your/docker/data"         # Deine Container-Daten
STACKS_DIR="/path/to/your/docker/stacks"     # Deine docker-compose Dateien
BACKUP_SOURCE="/path/to/your/docker"         # Was gesichert wird
BACKUP_DEST="/path/to/your/backup/destination"  # Wohin gesichert wird
```

### 🎛️ **Häufige Anpassungen:**

| System | Typische Pfade |
|--------|----------------|
| **UGREEN NAS** | `/volume1/docker-nas/` → `/volume2/backups/` |
| **Synology** | `/volume1/docker/` → `/volume2/backup/` |
| **QNAP** | `/share/Container/` → `/share/Backup/` |
| **Ubuntu** | `/opt/docker/` → `/backup/docker/` |

---

## ⚡ Wichtige Befehle

### 🧪 **Neue Test-Befehle (Version 3.5.1):**
```bash
# rsync-Fixes testen (NEU!)
sudo ./test_rsync_fix.sh

# Erwartete Ausgabe:
# ✅ RSYNC-FIXES FUNKTIONIEREN!
```

### 🎯 **Grundbefehle:**
```bash
# Interaktives Backup (mit Bestätigung)
sudo ./docker_backup.sh

# Automatisches Backup (ohne Nachfrage)
sudo ./docker_backup.sh --auto

# Test-Modus (keine Änderungen)
sudo ./docker_backup.sh --dry-run

# Nur Container neu starten
sudo ./docker_backup.sh --skip-backup --auto

# Deutsche Version Beispiele:
sudo ./docker_backup_de.sh --auto
sudo ./docker_backup_de.sh --dry-run
```

### 🚀 **Performance-Befehle:**
```bash
# Schnelles Backup (stop statt down)
./docker_backup.sh --auto --use-stop

# Paralleles Backup (4 Container gleichzeitig)
./docker_backup.sh --auto --parallel 4

# Mit ACL-Bewahrung (Dateiberechtigungen, keine Verschlüsselung)
./docker_backup.sh --auto --preserve-acl

# Ohne Verifikation (schneller)
./docker_backup.sh --auto --no-verify
```

---

## 📊 Was passiert beim Backup?

### 🔄 **Der Ablauf:**
1. **Container stoppen** (sauber, nicht brutal)
2. **Daten kopieren** (nur Änderungen)
3. **Container starten** (automatisch)

### ⏱️ **Zeitaufwand:**
- **Erstes Backup**: 1-5 Minuten (je nach Datenmenge)
- **Folge-Backups**: 10-30 Sekunden (nur Änderungen)
- **Container-Ausfall**: 30-60 Sekunden

### 💾 **Speicherplatz:**
- **Benötigt**: ~100% der Quellgröße
- **Empfohlen**: 120% für Puffer
- **Backup-Typ**: Inkrementelle Synchronisation (nur Änderungen, keine Snapshot-Historie)

---

## 🆘 Schnelle Problemlösung

### ❌ **"Docker ist nicht verfügbar"**
```bash
# Docker starten
sudo systemctl start docker
```

### ❌ **"Sudo-Berechtigung erforderlich"**
```bash
# User zur docker-Gruppe hinzufügen
sudo usermod -aG docker $USER
# Neu anmelden!
```

### ❌ **"Verzeichnis nicht gefunden"**
```bash
# Deine Docker-Verzeichnisse finden
find /volume* -name "docker-compose.yml" 2>/dev/null
# Pfade im Script anpassen
```

### ❌ **"Nicht genügend Speicherplatz"**
```bash
# Speicherplatz prüfen
df -h
# Weniger Puffer verwenden
./docker_backup.sh --buffer-percent 10
```

---

## 📝 Logs & Monitoring

### 📍 **Log-Dateien finden:**
```bash
# Standard Log-Verzeichnis
ls -la /volume1/docker-nas/logs/

# Neueste Logs anzeigen
tail -f /volume1/docker-nas/logs/docker_backup_*.log
```

### ✅ **Erfolg prüfen:**
```bash
# Letzte erfolgreiche Backups
grep "erfolgreich abgeschlossen" /volume1/docker-nas/logs/docker_backup_*.log | tail -3
```

### ❌ **Fehler finden:**
```bash
# Fehler in Logs suchen
grep "ERROR" /volume1/docker-nas/logs/docker_backup_*.log
```

---

## 🎯 Empfohlene Setups

### 🏠 **Heimnutzer (einfach):**
```bash
# Tägliches Backup um 2:00 Uhr
0 2 * * * /pfad/zum/docker_backup.sh --auto
# Oder mit deutscher Version:
0 2 * * * /pfad/zum/docker_backup_de.sh --auto
```

### 🏢 **Kleine Unternehmen (robust):**
```bash
# Backup mit Parallelisierung und ACL-Unterstützung
0 2 * * * /pfad/zum/docker_backup.sh --auto --parallel 4 --preserve-acl --buffer-percent 25
```

### ⚡ **Große Installation (performance):**
```bash
# Schnelles tägliches Backup
0 2 * * 1-6 /pfad/zum/docker_backup.sh --auto --use-stop --parallel 8
# Vollständiges wöchentliches Backup mit ACL-Unterstützung
0 1 * * 0 /pfad/zum/docker_backup.sh --auto --parallel 4 --preserve-acl
```

---

## 🔒 Verschlüsselte Backups (Optional)

### **Einfache Verschlüsselung:**
```bash
# 1. Normales Backup erstellen
sudo ./docker_backup.sh --auto

# 2. Backup verschlüsseln (mit Passwort-Abfrage)
tar -czf - /volume2/@home/florian/Backups/docker-nas-backup-rsync/ | gpg --symmetric --cipher-algo AES256 > /volume2/@home/florian/Backups/docker-backup-encrypted_$(date +%Y%m%d_%H%M%S).tar.gz.gpg

# 3. Unverschlüsseltes Backup löschen
rm -rf /volume2/@home/florian/Backups/docker-nas-backup-rsync/
```

### **Verschlüsseltes Backup wiederherstellen:**
```bash
# 1. Container stoppen
sudo ./docker_backup.sh --skip-backup

# 2. Entschlüsseln und wiederherstellen
gpg --decrypt /volume2/@home/florian/Backups/docker-backup-encrypted_YYYYMMDD_HHMMSS.tar.gz.gpg | tar -xzf - -C /

# 3. Container starten
sudo ./docker_backup.sh --skip-backup
```

**💡 Tipp:** Für detaillierte Verschlüsselungs-Anleitung siehe [README.md](README.md)

---

## � Weitere Hilfe

- 📖 **Vollständige Anleitung**: [`README.md`](README.md)
- 🔧 **Technische Details**: [`docker_backup_usage.md`](docker_backup_usage.md)
- ❓ **Bei Problemen**: Siehe FAQ in README.md

---

## ✅ Checkliste Version 3.5.1

- [ ] Scripts ausführbar gemacht (`chmod +x docker_backup.sh test_rsync_fix.sh`)
- [ ] **NEU:** rsync-Fixes getestet (`sudo ./test_rsync_fix.sh`)
- [ ] Pfade im Script geprüft/angepasst
- [ ] Erstes Test-Backup durchgeführt (`sudo ./docker_backup.sh --dry-run`)
- [ ] Echtes Backup getestet (`sudo ./docker_backup.sh`)
- [ ] Cron-Job eingerichtet
- [ ] Log-Verzeichnis geprüft
- [ ] Backup-Ziel hat genügend Speicherplatz

**🎉 Alles erledigt? Perfekt! Dein Docker-Backup läuft jetzt automatisch.**

### **🏆 Version 3.5.1 Highlights:**
- ✅ **Robuste rsync-Flag-Validierung** → Echte Tests statt grep
- ✅ **Verbesserte Array-basierte Ausführung** → Sichere Parameter-Übergabe
- ✅ **Dreistufiger Fallback-Mechanismus** → Automatische Kompatibilität
- ✅ **UGREEN NAS DXP2800** → 100% getestet und funktional
- ✅ **Neue Test-Tools** → `test_rsync_fix.sh` für Validierung

---

> **💡 Tipp**: Führe alle 2-3 Monate einen Wiederherstellungs-Test durch, um sicherzustellen, dass deine Backups funktionieren!