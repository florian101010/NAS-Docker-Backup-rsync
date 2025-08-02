# create_tar_archive_acl_for_duplicati.sh

Eigenständiges Skript zum Erstellen eines unverschlüsselten TAR-Archivs aus dem rsync-Backup-Verzeichnis. Es bewahrt Berechtigungen, Besitzer/Gruppen und ACLs, optional auch Extended Attributes (xattrs). Die resultierende Datei dient als Quelle für ein verschlüsseltes Offsite-Backup (z. B. rclone oder Duplicati).

- Skriptdatei: [`create_tar_archive_acl_for_duplicati.sh`](../../create_tar_archive_acl_for_duplicati.sh)
- Empfohlene Ausführung: als root (sudo), um alle Metadaten vollständig lesen/archivieren zu können.
- Standardverhalten: Eine feste Zieldatei (z. B. docker-backup-latest-for-duplicati.tar) wird atomar überschrieben.

NEU: Strukturierte, moderne Terminal-Ausgabe
- Einheitliche Präfixe: INFO, WARN, ERROR, DONE, SUMMARY
- Konsistente Schlüssel:Wert-Zeilen für gute Lesbarkeit und einfache Maschinen-Analyse
- Immer vorhandener SUMMARY-Block am Ende (SUCCESS/FAILURE) inkl. Dauer, Quelle/Ziel, Größe, Optionen, Verify-Status, Exit-Code

Beispielausgabe (verkürzt)
INFO  Start       : 2025-08-02 12:00:01 +0200
INFO  Source      : /volume2/@home/florian/Backups/docker-nas-backup-rsync
INFO  Output      : /volume2/backups/docker-nas-backup-duplicati-tar/docker-backup-latest-for-duplicati.tar
INFO  Preserve    : permissions, ownership, ACLs
INFO  Options     : verify=yes, xattrs=no, one_file_system=no, progress=pv
INFO  AtomicWrite : enabled (.part -> mv)
INFO  Tar Tool    : tar 1.34 (acls=yes, xattrs=yes)
INFO  Progress    : starting archive...
...pv/dots...
INFO  Verify      : tar -tf (reading index)...
DONE  Archive OK  : /volume2/backups/docker-nas-backup-duplicati-tar/docker-backup-latest-for-duplicati.tar
INFO  PostProcess : owner=1000:10, mode=0640
SUMMARY
  Status    : SUCCESS
  Start     : 2025-08-02 12:00:01 +0200
  End       : 2025-08-02 12:09:05 +0200
  Duration  : 00:09:04
  Source    : /volume2/@home/florian/Backups/docker-nas-backup-rsync
  Output    : /volume2/backups/docker-nas-backup-duplicati-tar/docker-backup-latest-for-duplicati.tar
  Size      : 6.11G
  Verify    : passed
  Options   : --acls --numeric-owner [xattrs disabled] [one-file-system disabled]
  Progress  : pv
  ExitCode  : 0

## Hauptfunktionen

1) Konsistentes TAR-Archiv mit Berechtigungen und ACLs
   - GNU tar mit `--acls` und `--numeric-owner` bewahrt Rechte/ACLs vollständig.
   - Numerische UID/GID für konsistente Restores.

2) Optional: Extended Attributes (xattrs)
   - `--xattrs` aktiviert `--xattrs --xattrs-include='*'` (falls tar das unterstützt).
   - NAS-Relevanz: SMB-DOS-Attribute, macOS `com.apple.*`, Security-Labels.
   - Standard AUS (kleinere Archive, weniger Warnungen).

3) Fortschritt
   - pv bevorzugt; Install-Hinweise wenn pv fehlt; Fallback auf DOT-Checkpoints.
   - `--no-progress` für stille Läufe (z. B. Cron).

4) Atomisches Schreiben
   - Erst `.part`, optional verifizieren, dann atomar nach finalem Namen verschieben.

5) Verifikation
   - Standard AN: `tar -tf` testet Archiv-Lesbarkeit.

6) Eigentümer/Modus
   - Setzt Owner:Group und Modus (Standard: `1000:10`, `0640`).

7) Dateisystemgrenze optional
   - `--one-file-system` verhindert Crossing von Mounts.

## Sicherheit und Voraussetzungen

- root empfohlen; GNU tar mit ACL-Unterstützung erforderlich.
- `pv` optional (bester Fortschritt); Quelle darf nicht leer sein.
- Bei fehlendem pv: deutliche Hints mit Install-Commands, DOT-Fallback.

## Pfade und Standardwerte

- Quellverzeichnis:
  - Standard: `/volume2/@home/florian/Backups/docker-nas-backup-rsync`
- Zielverzeichnis:
  - Standard: `/volume2/backups/docker-nas-backup-duplicati-tar`
- Ausgabedatei:
  - Fest: `docker-backup-latest-for-duplicati.tar`
- Owner:Group:
  - Standard: `1000:10`
- Modus:
  - Standard: `0640`

OUT_PATH wird nach CLI-Parsing aus `DEST_DIR` und `OUT_NAME` berechnet (Overrides greifen sicher).

## CLI-Optionen

Siehe Parsing in [`bash.usage()`](../../create_tar_archive_acl_for_duplicati.sh:54) und Logik in [`bash.main()`](../../create_tar_archive_acl_for_duplicati.sh:1).

- `--source DIR` / `--dest DIR` / `--filename NAME.tar`
- `--owner UID:GID` / `--mode MODE`
- `--verify` / `--no-verify`
- `--one-file-system`
- `--xattrs` (falls tar `--xattrs` unterstützt)
- `--no-progress`
- `--quiet`
- `-h`, `--help`

## Beispiele

1) Standard
```bash
sudo bash create_tar_archive_acl_for_duplicati.sh
```

2) Mit xattrs
```bash
sudo bash create_tar_archive_acl_for_duplicati.sh --xattrs
```

3) Ohne Progress
```bash
sudo bash create_tar_archive_acl_for_duplicati.sh --no-progress
```

4) Single-FS
```bash
sudo bash create_tar_archive_acl_for_duplicati.sh --one-file-system
```

5) Angepasste Pfade/Owner/Modus
```bash
sudo bash create_tar_archive_acl_for_duplicati.sh \
  --dest /volume2/backups/docker-nas-backup-duplicati-tar \
  --filename docker-backup-latest-for-duplicati.tar \
  --owner 1000:10 \
  --mode 0640
```

## Ablauf im Detail

- Preflight: Quelle vorhanden/nicht leer, tar mit `--acls`, Progress-Mechanik ermittelt.
- TAR-Optionen: `--acls --numeric-owner -cpf -` (+ optional `--one-file-system`, `--xattrs`).
- Schreiben: nach `.part`, optional `tar -tf`, dann atomar `mv`.
- Post: `chown`/`chmod`; strukturierter SUMMARY-Block am Ende.
- Fehlerfall: Sofortige ERROR/Hints und SUMMARY mit Status=FAILURE, Phase und ExitCode.

## Wiederherstellung

- ACLs:
```bash
sudo tar --acls -xpf docker-backup-latest-for-duplicati.tar -C /restore/target
```
- ACLs + xattrs:
```bash
sudo tar --acls --xattrs -xpf docker-backup-latest-for-duplicati.tar -C /restore/target
```

## FAQ

- `--numeric-owner`?
  - Sichert numerische UID/GID für konsistente Restores.

- xattrs nötig?
  - Nur bei Bedarf spezieller Metadaten (SMB/macOS/Security).

- `.part` + atomar?
  - Verhindert, dass Konsumenten halbfertige Dateien verarbeiten.

- pv fehlt?
  - Skript gibt Install-Hints aus und nutzt DOT-Fallback.

## Relevante Code-Stellen

- Parsing/Hilfe: [`bash.usage()`](../../create_tar_archive_acl_for_duplicati.sh:54)
- Fortschritt + Erstellung: [`bash.main()`](../../create_tar_archive_acl_for_duplicati.sh:203)
- xattrs-Option/Validierung: [`bash.main()`](../../create_tar_archive_acl_for_duplicati.sh:166)
- Atomic/Verify/SUMMARY: [`bash.main()`](../../create_tar_archive_acl_for_duplicati.sh:152)