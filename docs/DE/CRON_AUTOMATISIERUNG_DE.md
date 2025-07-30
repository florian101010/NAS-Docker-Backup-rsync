# Docker Backup Script - Cron Automatisierung

## Inhaltsverzeichnis

- [Übersicht](#übersicht)
- [Grundlagen von Cron](#grundlagen-von-cron)
- [Vorbereitung für Cron](#vorbereitung-für-cron)
- [Cron-Job Konfiguration](#cron-job-konfiguration)
- [Backup-Strategien](#backup-strategien)
- [Logging und Monitoring](#logging-und-monitoring)
- [Sicherheitsaspekte](#sicherheitsaspekte)
- [Troubleshooting](#troubleshooting)
- [Erweiterte Konfigurationen](#erweiterte-konfigurationen)
- [Best Practices](#best-practices)

---

## Übersicht

Die Automatisierung des Docker Backup Scripts mit Cron ermöglicht regelmäßige, unbeaufsichtigte Backups Ihrer Docker-Container und Daten. Dieses Dokument erklärt alle Aspekte der Cron-Integration im Detail.

### Warum Cron-Automatisierung?

- **Zuverlässigkeit**: Backups laufen automatisch, auch wenn Sie nicht da sind
- **Konsistenz**: Regelmäßige Backup-Zyklen ohne menschliche Fehler
- **Flexibilität**: Verschiedene Backup-Strategien für verschiedene Zeiten
- **Sicherheit**: Minimiert das Risiko von Datenverlust durch vergessene Backups

---

## Grundlagen von Cron

### Was ist Cron?

Cron ist ein zeitbasierter Job-Scheduler in Unix-ähnlichen Betriebssystemen. Er führt Befehle zu festgelegten Zeiten automatisch aus.

### Cron-Syntax verstehen

```
* * * * * command
│ │ │ │ │
│ │ │ │ └─── Wochentag (0-7, 0 und 7 = Sonntag)
│ │ │ └───── Monat (1-12)
│ │ └─────── Tag des Monats (1-31)
│ └───────── Stunde (0-23)
└─────────── Minute (0-59)
```

### Cron-Syntax Beispiele

| Cron-Ausdruck | Bedeutung |
|---------------|-----------|
| `0 2 * * *` | Täglich um 2:00 Uhr |
| `30 1 * * 0` | Sonntags um 1:30 Uhr |
| `0 */6 * * *` | Alle 6 Stunden |
| `15 14 1 * *` | Am 1. jeden Monats um 14:15 |
| `0 22 * * 1-5` | Montag bis Freitag um 22:00 |

### Spezielle Cron-Ausdrücke

| Ausdruck | Bedeutung |
|----------|-----------|
| `@reboot` | Bei Systemstart |
| `@yearly` | Einmal pro Jahr (0 0 1 1 *) |
| `@monthly` | Einmal pro Monat (0 0 1 * *) |
| `@weekly` | Einmal pro Woche (0 0 * * 0) |
| `@daily` | Einmal täglich (0 0 * * *) |
| `@hourly` | Einmal stündlich (0 * * * *) |

---

## Vorbereitung für Cron

### 1. Script-Pfade vorbereiten

```bash
# Script an festen Ort kopieren
sudo cp docker_backup.sh /usr/local/bin/docker_backup.sh
sudo chmod +x /usr/local/bin/docker_backup.sh

# Oder im aktuellen Verzeichnis belassen
chmod +x /volume1/docker-nas/docker_backup.sh
```

### 2. Umgebungsvariablen testen

Cron läuft mit minimaler Umgebung. Testen Sie das Script:

```bash
# Cron-ähnliche Umgebung simulieren
env -i HOME="$HOME" PATH="/usr/bin:/bin" /volume1/docker-nas/docker_backup.sh --dry-run
```

### 3. Berechtigungen prüfen

```bash
# Script-Berechtigungen
ls -la /volume1/docker-nas/docker_backup.sh
# Sollte: -rwxr-xr-x oder -rwx------

# Log-Verzeichnis-Berechtigungen
ls -ld /volume1/docker-nas/logs/
# Sollte: drwxr-xr-x oder drwx------

# Backup-Ziel-Berechtigungen
ls -ld /volume2/@home/florian/Backups/
# Sollte: drwxr-xr-x oder drwx------
```

### 4. Sudo-Konfiguration (falls erforderlich)

Für passwordless sudo (empfohlen für Cron):

```bash
# Sudoers-Datei bearbeiten
sudo visudo

# Hinzufügen (ersetzen Sie 'username' mit Ihrem Benutzernamen):
username ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose, /usr/bin/rsync
```

---

## Cron-Job Konfiguration

### Crontab bearbeiten

```bash
# Für aktuellen Benutzer
crontab -e

# Für root (falls erforderlich)
sudo crontab -e

# Crontab anzeigen
crontab -l
```

### Grundlegende Cron-Jobs

#### Tägliches Backup

```bash
# Täglich um 2:00 Uhr - Schnelles Backup
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto --use-stop

# Täglich um 3:00 Uhr - Vollständiges Backup
0 3 * * * /volume1/docker-nas/docker_backup.sh --auto
```

#### Wöchentliches Backup

```bash
# Sonntags um 1:00 Uhr - Vollständiges Backup mit ACL
0 1 * * 0 /volume1/docker-nas/docker_backup.sh --auto --preserve-acl
```

#### Mehrfach-Backup-Strategie

```bash
# Täglich schnelles Backup (Montag-Samstag)
0 2 * * 1-6 /volume1/docker-nas/docker_backup.sh --auto --use-stop --parallel 4

# Sonntags vollständiges Backup
0 1 * * 0 /volume1/docker-nas/docker_backup.sh --auto --preserve-acl --parallel 2
```

---

## Backup-Strategien

### Strategie 1: Einfache tägliche Backups

**Geeignet für**: Kleine bis mittlere Installationen

```bash
# Crontab-Eintrag
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto --use-stop >> /volume1/docker-nas/logs/cron_backup.log 2>&1
```

**Vorteile**:
- Einfach zu verstehen und zu warten
- Konsistente Backup-Zeiten
- Geringer Wartungsaufwand

**Nachteile**:
- Keine Differenzierung zwischen Wochentagen
- Immer gleiche Backup-Tiefe

### Strategie 2: Differenzierte Backup-Zyklen

**Geeignet für**: Mittlere bis große Installationen

```bash
# Montag-Freitag: Schnelle Backups
0 2 * * 1-5 /volume1/docker-nas/docker_backup.sh --auto --use-stop --parallel 4 --buffer-percent 15

# Samstag: Backup mit Verifikation
0 1 * * 6 /volume1/docker-nas/docker_backup.sh --auto --parallel 2 --buffer-percent 25

# Sonntag: Vollständiges Backup mit ACL
0 0 * * 0 /volume1/docker-nas/docker_backup.sh --auto --preserve-acl --parallel 2 --timeout-stop 120
```

**Vorteile**:
- Optimiert für verschiedene Anforderungen
- Wochenende für intensive Backups
- Flexible Ressourcennutzung

### Strategie 3: Hochfrequente Backups

**Geeignet für**: Kritische Produktionsumgebungen

```bash
# Alle 6 Stunden: Schnelle Backups
0 */6 * * * /volume1/docker-nas/docker_backup.sh --auto --use-stop --parallel 6 --no-verify

# Täglich um 2:00: Vollständiges Backup
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto --parallel 4 --buffer-percent 20

# Wöchentlich: Backup mit ACL und Verschlüsselung
0 1 * * 0 /volume1/docker-nas/docker_backup.sh --auto --preserve-acl && /volume1/docker-nas/encrypt_backup.sh
```

**Vorteile**:
- Minimaler Datenverlust bei Ausfällen
- Mehrere Backup-Ebenen
- Hohe Verfügbarkeit

**Nachteile**:
- Höhere Systemlast
- Mehr Speicherplatz erforderlich
- Komplexere Wartung

### Strategie 4: Verschlüsselte Backups

**Geeignet für**: Sicherheitskritische Umgebungen

```bash
# Tägliches verschlüsseltes Backup
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto --parallel 4 && tar -czf - /volume2/@home/florian/Backups/docker-nas-backup-rsync/ | gpg --symmetric --cipher-algo AES256 --passphrase-file /volume1/docker-nas/.backup_password > /volume2/@home/florian/Backups/docker-backup-encrypted_$(date +\%Y\%m\%d_\%H\%M\%S).tar.gz.gpg && rm -rf /volume2/@home/florian/Backups/docker-nas-backup-rsync/

# Wöchentliche Bereinigung alter verschlüsselter Backups
0 3 * * 0 find /volume2/@home/florian/Backups/ -name "docker-backup-encrypted_*.tar.gz.gpg" -mtime +30 -delete
```

---

## Logging und Monitoring

### Logging-Konfiguration

#### Standard-Logging

```bash
# Einfaches Logging in Datei
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto >> /volume1/docker-nas/logs/cron_backup.log 2>&1
```

#### Erweiterte Logging-Optionen

```bash
# Mit Zeitstempel und Rotation
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto >> /volume1/docker-nas/logs/cron_backup_$(date +\%Y\%m).log 2>&1

# System-Logger verwenden
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto 2>&1 | logger -t docker_backup

# Separate Logs für Erfolg und Fehler
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto >> /volume1/docker-nas/logs/cron_backup_success.log 2>> /volume1/docker-nas/logs/cron_backup_error.log
```

### Log-Rotation einrichten

#### Automatische Log-Rotation

```bash
# Cron-Job für Log-Bereinigung (täglich um 4:00)
0 4 * * * find /volume1/docker-nas/logs/ -name "cron_backup*.log" -mtime +30 -delete

# Komprimierung alter Logs
0 4 * * 0 gzip /volume1/docker-nas/logs/cron_backup_$(date -d '1 week ago' +\%Y\%m\%d)*.log 2>/dev/null
```

#### Logrotate konfigurieren

```bash
# /etc/logrotate.d/docker-backup erstellen
sudo tee /etc/logrotate.d/docker-backup << EOF
/volume1/docker-nas/logs/cron_backup*.log {
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

### Monitoring und Benachrichtigungen

#### E-Mail-Benachrichtigungen

```bash
# Bei Fehlern E-Mail senden (erfordert mailutils)
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto || echo "Docker Backup fehlgeschlagen am $(date)" | mail -s "Backup Fehler" admin@example.com
```

#### Webhook-Benachrichtigungen

```bash
# Erfolgs-/Fehler-Webhook
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto && curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" -d '{"text":"Docker Backup erfolgreich"}' || curl -X POST "https://hooks.slack.com/services/YOUR/WEBHOOK/URL" -d '{"text":"Docker Backup fehlgeschlagen"}'
```

#### Status-Datei erstellen

```bash
# Status-Datei für Monitoring
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto && echo "SUCCESS $(date)" > /volume1/docker-nas/logs/last_backup_status || echo "FAILED $(date)" > /volume1/docker-nas/logs/last_backup_status
```

---

## Sicherheitsaspekte

### Cron-Sicherheit

#### Crontab-Berechtigungen

```bash
# Crontab-Dateien prüfen
ls -la /var/spool/cron/crontabs/$(whoami)
# Sollte: -rw------- (600)

# Cron-Logs prüfen
sudo ls -la /var/log/cron*
```

#### Sichere Script-Pfade

```bash
# Absolute Pfade verwenden
0 2 * * * /usr/bin/env bash /volume1/docker-nas/docker_backup.sh --auto

# PATH explizit setzen
0 2 * * * PATH=/usr/local/bin:/usr/bin:/bin /volume1/docker-nas/docker_backup.sh --auto
```

### Backup-Sicherheit

#### PID/Lock-Datei Schutz

Das Script (Version 3.4.9+) verhindert automatisch doppelte Ausführung:

```bash
# Mehrfache Cron-Jobs sind sicher
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto --parallel 4
30 2 * * * /volume1/docker-nas/docker_backup.sh --auto --use-stop
```

#### Sichere Passwort-Verwaltung

```bash
# Passwort-Datei für verschlüsselte Backups
echo "SICHERES_PASSWORT" | sudo tee /volume1/docker-nas/.backup_password
sudo chmod 600 /volume1/docker-nas/.backup_password
sudo chown root:root /volume1/docker-nas/.backup_password
```

---

## Troubleshooting

### Häufige Cron-Probleme

#### Problem: Cron-Job läuft nicht

**Diagnose**:
```bash
# Cron-Service prüfen
sudo systemctl status cron

# Cron-Logs prüfen
sudo tail -f /var/log/cron.log

# Crontab prüfen
crontab -l
```

**Lösungen**:
```bash
# Cron-Service starten
sudo systemctl start cron
sudo systemctl enable cron

# Crontab-Syntax prüfen
crontab -l | crontab -
```

#### Problem: Script läuft nicht in Cron

**Diagnose**:
```bash
# Umgebung testen
env -i HOME="$HOME" PATH="/usr/bin:/bin" /volume1/docker-nas/docker_backup.sh --dry-run

# Berechtigungen prüfen
ls -la /volume1/docker-nas/docker_backup.sh
```

**Lösungen**:
```bash
# Vollständige Pfade verwenden
0 2 * * * /usr/bin/env bash /volume1/docker-nas/docker_backup.sh --auto

# PATH in Crontab setzen
PATH=/usr/local/bin:/usr/bin:/bin
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto
```

#### Problem: Sudo-Passwort erforderlich

**Diagnose**:
```bash
# Sudo-Konfiguration testen
sudo -n docker ps
```

**Lösung**:
```bash
# Passwordless sudo einrichten
sudo visudo
# Hinzufügen: username ALL=(ALL) NOPASSWD: /usr/bin/docker, /usr/bin/docker-compose
```

#### Problem: Logs werden nicht erstellt

**Diagnose**:
```bash
# Log-Verzeichnis prüfen
ls -ld /volume1/docker-nas/logs/

# Schreibberechtigungen testen
touch /volume1/docker-nas/logs/test.log
```

**Lösung**:
```bash
# Log-Verzeichnis erstellen
mkdir -p /volume1/docker-nas/logs/
chmod 755 /volume1/docker-nas/logs/
```

### Debug-Techniken

#### Cron-Job debuggen

```bash
# Debug-Cron-Job erstellen
* * * * * /volume1/docker-nas/docker_backup.sh --dry-run >> /tmp/cron_debug.log 2>&1

# Nach 2-3 Minuten prüfen
cat /tmp/cron_debug.log
```

#### Umgebung vergleichen

```bash
# Interaktive Umgebung
env > /tmp/interactive_env.txt

# Cron-Umgebung
* * * * * env > /tmp/cron_env.txt

# Unterschiede anzeigen
diff /tmp/interactive_env.txt /tmp/cron_env.txt
```

---

## Erweiterte Konfigurationen

### Conditional Backups

#### Backup nur bei Änderungen

```bash
# Script erweitern für Change-Detection
0 2 * * * [ "$(find /volume1/docker-nas/data -newer /volume1/docker-nas/logs/last_backup_marker 2>/dev/null | wc -l)" -gt 0 ] && /volume1/docker-nas/docker_backup.sh --auto && touch /volume1/docker-nas/logs/last_backup_marker
```

#### Backup basierend auf Systemlast

```bash
# Nur bei niedriger Load
0 2 * * * [ "$(uptime | awk '{print $10}' | cut -d',' -f1)" \< "2.0" ] && /volume1/docker-nas/docker_backup.sh --auto
```

### Multi-Destination Backups

```bash
# Backup zu mehreren Zielen
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto && rsync -av /volume2/@home/florian/Backups/docker-nas-backup-rsync/ /mnt/external_backup/docker-nas-backup-$(date +\%Y\%m\%d)/
```

### Backup-Rotation

```bash
# Automatische Backup-Rotation
0 3 * * * find /volume2/@home/florian/Backups/ -name "docker-nas-backup-*" -type d -mtime +7 -exec rm -rf {} \;

# Backup-Archivierung
0 4 * * 0 tar -czf /volume2/@home/florian/Archives/docker-backup-$(date +\%Y\%m\%d).tar.gz /volume2/@home/florian/Backups/docker-nas-backup-rsync/ && rm -rf /volume2/@home/florian/Backups/docker-nas-backup-rsync/
```

---

## Best Practices

### Timing-Best-Practices

1. **Niedrige Systemlast wählen**: Backups in den frühen Morgenstunden (1-4 Uhr)
2. **Wartungsfenster nutzen**: Backups außerhalb der Hauptnutzungszeiten
3. **Staggered Backups**: Verschiedene Services zu verschiedenen Zeiten
4. **Pufferzeiten einplanen**: Genügend Zeit zwischen verschiedenen Backup-Jobs

### Ressourcen-Management

```bash
# CPU-Priorität reduzieren
0 2 * * * nice -n 10 /volume1/docker-nas/docker_backup.sh --auto

# IO-Priorität reduzieren (ionice)
0 2 * * * ionice -c 3 /volume1/docker-nas/docker_backup.sh --auto

# Kombiniert
0 2 * * * nice -n 10 ionice -c 3 /volume1/docker-nas/docker_backup.sh --auto --parallel 2
```

### Monitoring-Best-Practices

1. **Regelmäßige Log-Überprüfung**: Wöchentliche Kontrolle der Backup-Logs
2. **Automatische Alerts**: Bei Backup-Fehlern sofortige Benachrichtigung
3. **Backup-Verifikation**: Regelmäßige Wiederherstellungs-Tests
4. **Speicherplatz-Monitoring**: Überwachung des verfügbaren Speicherplatzes

### Sicherheits-Best-Practices

1. **Minimale Berechtigungen**: Nur notwendige sudo-Rechte vergeben
2. **Sichere Pfade**: Absolute Pfade und sichere PATH-Variable
3. **Log-Sicherheit**: Logs vor unbefugtem Zugriff schützen
4. **Backup-Verschlüsselung**: Sensible Daten verschlüsselt sichern

### Wartungs-Best-Practices

```bash
# Monatliche Crontab-Überprüfung
0 0 1 * * crontab -l > /volume1/docker-nas/logs/crontab_backup_$(date +\%Y\%m).txt

# Quartalsweise Backup-Test
0 2 1 */3 * /volume1/docker-nas/docker_backup.sh --dry-run --verbose >> /volume1/docker-nas/logs/quarterly_test.log 2>&1

# Jährliche Konfiguration-Sicherung
0 1 1 1 * tar -czf /volume1/docker-nas/backups/cron_config_$(date +\%Y).tar.gz /var/spool/cron/crontabs/ /etc/cron.d/ /volume1/docker-nas/
```

---

## Beispiel-Konfigurationen

### Kleine Installation (1-5 Container)

```bash
# Einfache tägliche Backups
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto --use-stop >> /volume1/docker-nas/logs/cron_backup.log 2>&1

# Wöchentliche Log-Bereinigung
0 3 * * 0 find /volume1/docker-nas/logs/ -name "*.log" -mtime +14 -delete
```

### Mittlere Installation (5-15 Container)

```bash
# Differenzierte Backup-Strategie
0 2 * * 1-6 /volume1/docker-nas/docker_backup.sh --auto --use-stop --parallel 2 --buffer-percent 15
0 1 * * 0 /volume1/docker-nas/docker_backup.sh --auto --preserve-acl --parallel 2 --timeout-stop 90

# Monitoring und Bereinigung
0 3 * * * echo "Backup Status: $(tail -1 /volume1/docker-nas/logs/docker_backup_*.log | grep -o 'erfolgreich\|fehlgeschlagen')" | logger -t docker_backup_monitor
0 4 * * 0 find /volume1/docker-nas/logs/ -name "*.log" -mtime +30 -delete
```

### Große Installation (15+ Container)

```bash
# Hochfrequente, optimierte Backups
0 */8 * * * /volume1/docker-nas/docker_backup.sh --auto --use-stop --parallel 6 --no-verify --buffer-percent 10
0 2 * * * /volume1/docker-nas/docker_backup.sh --auto --parallel 4 --buffer-percent 20
0 1 * * 0 /volume1/docker-nas/docker_backup.sh --auto --preserve-acl --parallel 2 --timeout-stop 120

# Erweiterte Überwachung
*/15 * * * * [ -f /volume1/docker-nas/logs/last_backup_status ] && [ "$(find /volume1/docker-nas/logs/last_backup_status -mmin +480)" ] && echo "ALERT: Backup überfällig" | mail -s "Backup Alert" admin@example.com

# Automatische Optimierung
0 5 * * 0 nice -n 15 ionice -c 3 find /volume2/@home/florian/Backups/ -type f -name "*.log" -exec gzip {} \;
```

---

**Version 3.4.9 Kompatibilität**: Alle Beispiele sind für die aktuelle Script-Version optimiert und nutzen die implementierten Sicherheitsfixes für sichere Parallelisierung.