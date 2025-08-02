# create_tar_archive_acl_for_duplicati.sh

Standalone script to create an unencrypted TAR archive from your rsync backup directory. It preserves permissions, ownership, and ACLs, and can optionally include extended attributes (xattrs). The resulting TAR file is intended as a source artifact for encrypted offsite backups (e.g., rclone or Duplicati).

- Script file: [`create_tar_archive_acl_for_duplicati.sh`](../../create_tar_archive_acl_for_duplicati.sh)
- Recommended execution: run as root (sudo) to fully read/archive all metadata.
- Default behavior: one fixed output file (e.g., docker-backup-latest-for-duplicati.tar) is written atomically (overwrite).

NEW: Structured, modern terminal output
- Unified prefixes: INFO, WARN, ERROR, DONE, SUMMARY
- Consistent Key:Value lines for human readability and easy machine parsing
- Always-on SUMMARY block at the end (SUCCESS/FAILURE) with duration, source/target, size, options, verify status, exit code

Sample run (condensed)
INFO  Start       : 2025-08-02 12:00:01 +0200
INFO  Source      : /volume2/@home/florian/Backups/docker-nas-backup-rsync
INFO  Output      : /volume2/backups/docker-nas-backup-duplicati-tar/docker-backup-latest-for-duplicati.tar
INFO  Preserve    : permissions, ownership, ACLs
INFO  Options     : verify=yes, xattrs=no, one_file_system=no, progress=pv
INFO  AtomicWrite : enabled (.part -> mv)
INFO  Tar Tool    : GNU tar 1.34 (acls=yes, xattrs=yes)
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

## Key Features

1) TAR with permissions and ACLs
   - Uses GNU tar with `--acls` and `--numeric-owner` to fully preserve file rights and ACLs.
   - Stores numeric UID/GID to ensure consistent restores across systems.

2) Optional: Extended Attributes (xattrs)
   - Enable via `--xattrs` to add `--xattrs --xattrs-include='*'`.
   - Useful for NAS environments that need SMB/Windows attributes (e.g., `user.DOSATTRIB`), macOS metadata (`com.apple.*`), or security labels.
   - Default is OFF to minimize size and warnings. Enable only if needed.

3) Progress UX
   - Prefers `pv` for user-friendly progress if installed; prints install hints if missing; automatic dot fallback.
   - `--no-progress` to suppress all progress output (cron-friendly).

4) Atomic writes
   - Writes to `.../.part` first, optionally verifies readability, then atomically renames to the final filename.

5) Verification
   - Enabled by default: uses `tar -tf` after writing to verify archive readability.

6) Ownership/mode on result file
   - Applies owner:group and permissions (defaults: `1000:10` and mode `0640`) to the final TAR file.

7) Optional filesystem boundary
   - `--one-file-system` ensures archiving doesn’t cross filesystem boundaries.

## Safety and Requirements

- Root privileges are recommended (sudo) to read all files/metadata (ACLs and potentially xattrs).
- GNU tar with ACL support is required:
  - The script checks `tar --acls --version` and exits with a clear error if not supported.
- Optional tool: `pv` for the best progress display.
- Source directory must not be empty (safeguard against wrong mounts/paths).

## Paths and Defaults

- Source directory (rsync backup tree):
  - Default: `/volume2/@home/florian/Backups/docker-nas-backup-rsync`
- Destination directory (for the TAR file):
  - Default: `/volume2/backups/docker-nas-backup-duplicati-tar`
- Output filename:
  - Fixed: `docker-backup-latest-for-duplicati.tar` (always overwritten)
- Owner:Group for result file:
  - Default: `1000:10`
- Mode for result file:
  - Default: `0640`

OUT_PATH is computed after CLI parsing from DEST_DIR and OUT_NAME so user overrides are honored.

## CLI Options

Options are parsed in the script, see [`bash.usage()`](../../create_tar_archive_acl_for_duplicati.sh:54) and the main logic in [`bash.main()`](../../create_tar_archive_acl_for_duplicati.sh:1).

- `--source DIR`
  - Source directory to archive (default: see above).
- `--dest DIR`
  - Destination directory where the TAR file will be written.
- `--filename NAME.tar`
  - Output filename.
- `--owner UID:GID`
  - Owner:Group to apply to the TAR file (default: `1000:10`).
- `--mode MODE`
  - File mode for the TAR file (default: `0640`).
- `--verify` / `--no-verify`
  - Enable/disable `tar -tf` verification (default: `--verify` enabled).
- `--one-file-system`
  - Do not cross filesystem boundaries (tar `--one-file-system`).
- `--xattrs`
  - Include extended attributes (`--xattrs --xattrs-include='*'`), if tar supports it.
- `--no-progress`
  - Suppress all progress output (neither pv nor dot fallback).
- `--quiet`
  - Reduce INFO level output.
- `-h`, `--help`
  - Show help text.

## Examples

1) Default run (ACLs, numeric owners, verification ON, fixed file, atomic write)
```bash
sudo bash create_tar_archive_acl_for_duplicati.sh
```

2) Include xattrs (e.g., for SMB/macOS relevant metadata)
```bash
sudo bash create_tar_archive_acl_for_duplicati.sh --xattrs
```

3) No progress output
```bash
sudo bash create_tar_archive_acl_for_duplicati.sh --no-progress
```

4) Keep within a single filesystem
```bash
sudo bash create_tar_archive_acl_for_duplicati.sh --one-file-system
```

5) Custom destination/name and result file owner/mode
```bash
sudo bash create_tar_archive_acl_for_duplicati.sh \
  --dest /volume2/backups/docker-nas-backup-duplicati-tar \
  --filename docker-backup-latest-for-duplicati.tar \
  --owner 1000:10 \
  --mode 0640
```

## Detailed Flow

1) Preflight
   - Ensures source exists and is not empty (fails otherwise).
   - Checks GNU tar and that `--acls` is supported (fails otherwise).
   - Chooses progress mechanism:
     - `pv` present → uses pv.
     - If `pv` missing → prints install hint; uses DOT fallback (unless `--no-progress` is set).

2) Build TAR options
   - Always: `--acls --numeric-owner -cpf -` plus `-C <parent> <basename>`.
   - Optional: `--one-file-system`, `--xattrs --xattrs-include='*'`.

3) Atomic write
   - Streams to a `.part` file.
   - Optional: verifies with `tar -tf`.
   - Atomically renames to the final filename.
   - Sets owner/group and mode on the result file.

## Restore Notes

- Restore with ACLs:
```bash
sudo tar --acls -xpf docker-backup-latest-for-duplicati.tar -C /restore/target
```

- If xattrs were included:
```bash
sudo tar --acls --xattrs -xpf docker-backup-latest-for-duplicati.tar -C /restore/target
```

- Ensure the target filesystem supports ACLs (and xattrs if used).

## FAQ

- Why `--numeric-owner`?
  - Stores UID/GID numerically. This ensures consistent restores on systems with different user/group names.

- Do I need xattrs?
  - Only if you rely on specific metadata (SMB DOS attributes, macOS `com.apple.*`, security labels). Otherwise, ACLs/permissions are typically sufficient for most NAS scenarios.

- Why `.part` and atomic move?
  - Prevents rclone/Duplicati from picking up a half-written file and users from consuming it prematurely.

- What if `pv` is missing?
  - The script informs you (with install commands) and uses a DOT fallback (unless `--no-progress` is set).

## Relevant Code Locations

- Argument parsing and help: [`bash.usage()`](../../create_tar_archive_acl_for_duplicati.sh:54)
- Progress logic (pv preferred, dot fallback, no-progress): creation block in [`bash.main()`](../../create_tar_archive_acl_for_duplicati.sh:203)
- xattrs option and validation: TAR options in [`bash.main()`](../../create_tar_archive_acl_for_duplicati.sh:166)
- Atomic write, verification, and SUMMARY: [`bash.main()`](../../create_tar_archive_acl_for_duplicati.sh:152)