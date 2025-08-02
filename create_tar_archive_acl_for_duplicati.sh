#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ==============================================================================
# Standalone TAR creator for rsync backup tree with ACLs (no timestamps)
# Purpose: Create a single, unencrypted TAR file from the rsync backup directory,
#          preserving permissions, ownership, and ACLs for reliable restore.
# Author: Florian Grimmer - 2025
# ==============================================================================

# ========================= USER-CONFIGURABLE DEFAULTS =========================
# Adjust these to your environment if needed. All can be overridden via CLI flags.
SOURCE_DIR="/volume2/backups/docker-nas-backup"   # rsync mirror source
DEST_DIR="/volume2/backups/docker-nas-backup-duplicati-tar"   # where to place TAR
OUT_NAME="docker-backup-latest-for-duplicati.tar"                     # fixed filename (overwritten)
OUT_PATH=""                                                           # computed after args (DEST_DIR/OUT_NAME)
OWNER_UIDGID="1000:10"                                                # final TAR owner:group
FILE_MODE="0640"                                                      # final TAR file mode
DO_VERIFY=true                                                        # verify with 'tar -tf' after write
ONE_FILE_SYSTEM=false                                                 # tar --one-file-system
QUIET=false                                                           # reduce INFO output
INCLUDE_XATTRS=false                                                  # add --xattrs if true
# Optional progress toggle (settable via --no-progress); default is progress ON
NO_PROGRESS=false                                                     # disable progress if true

# Explain xattrs briefly:
# Extended attributes (xattrs) store metadata (e.g., SELinux labels, custom attributes).
# For most NAS use-cases focusing on permissions and ACLs, ACLs are the critical part.
# xattrs are optional and can be enabled with --xattrs if needed (e.g., Samba/macOS attrs).

# Requirements:
# - Run as root to ensure all metadata readable (recommended).
# - GNU tar with ACL support (option --acls). For xattrs, tar must support --xattrs.
# - pv is preferred for progress; if not present we show a preflight hint and use a dot-progress fallback.
# Note on OUT_PATH: It is intentionally empty above and computed later from DEST_DIR/OUT_NAME
# after processing CLI flags so user overrides are respected.

# ------------------------------------------------------------------------------

log() {
  local level="$1"; shift
  if [ "${QUIET}" = true ] && [ "$level" = "INFO" ]; then
    return
  fi
  # Modern, plain ASCII, machine-parsable "LEVEL  message"
  printf '%s  %s\n' "$level" "$*" >&2
}

die() {
  log "ERROR" "$*"
  exit 1
}

usage() {
  cat <<'EOF'
Usage: create_tar_archive_acl.sh [options]

Options:
  --source DIR           Source directory to archive (default: /volume2/backups/docker-nas-backup)
  --dest DIR             Destination directory for TAR (default: /volume2/backups/duplicati-source-archives)
  --filename NAME.tar    Output filename (default: docker-backup-latest.tar)
  --owner UID:GID        chown for result file (default: 1000:10)
  --mode MODE            chmod for result file (default: 0640)
  --verify               Enable verification with 'tar -tf' (default)
  --no-verify            Disable verification
  --one-file-system      Do not cross filesystem boundaries
  --xattrs               Include extended attributes (adds tar --xattrs --xattrs-include='*')
  --no-progress          Disable progress display entirely
  --quiet                Reduce INFO output
  -h, --help             Show this help

Notes:
  - pv is preferred for the best progress UX. If pv is not installed, the script shows a clear hint
    how to install it and falls back to dot progress (unless --no-progress is set).
  - Common pv installation commands:
      Debian/Ubuntu: sudo apt install pv
      RHEL/CentOS:   sudo yum install pv
      macOS (brew):  brew install pv
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      SOURCE_DIR="${2:-}"; shift 2 ;;
    --dest)
      DEST_DIR="${2:-}"; shift 2 ;;
    --filename)
      OUT_NAME="${2:-}"; shift 2 ;;
    --owner)
      OWNER_UIDGID="${2:-}"; shift 2 ;;
    --mode)
      FILE_MODE="${2:-}"; shift 2 ;;
    --verify)
      DO_VERIFY=true; shift ;;
    --no-verify)
      DO_VERIFY=false; shift ;;
    --one-file-system)
      ONE_FILE_SYSTEM=true; shift ;;
    --xattrs)
      INCLUDE_XATTRS=true; shift ;;
    --no-progress)
      NO_PROGRESS=true; shift ;;
    --quiet)
      QUIET=true; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      die "Unknown option: $1 (use --help)" ;;
  esac
done

# Compute OUT_PATH
OUT_PATH="${DEST_DIR%/}/${OUT_NAME}"

# Preflight checks
[ -d "$SOURCE_DIR" ] || die "Source directory not found: $SOURCE_DIR
Hint: Adjust --source to your rsync backup root."
mkdir -p "$DEST_DIR" || die "Failed to create destination directory: $DEST_DIR
Hint: Check permissions or choose a writable --dest"

# Safety: Ensure source is not empty (avoid archiving a wrong mount)
if ! find "$SOURCE_DIR" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
  die "Source directory appears empty: $SOURCE_DIR
Hint: Verify your backup ran successfully and that --source points to the correct path"
fi

# Check for tar
command -v tar >/dev/null 2>&1 || die "GNU tar not found
Hint: Install tar (apt/yum/brew) and ensure it supports ACLs."
# Check if tar supports --acls (GNU tar 1.27+)
if ! tar --acls --version >/dev/null 2>&1; then
  die "tar does not support --acls.
Hint: Install a GNU tar build with ACL support and enable ACLs on the filesystem."
fi

# Decide on progress mechanism (prefer pv; warn if missing; fallback to dots)
USE_PV=false
if [ "${NO_PROGRESS:-false}" = false ]; then
  if command -v pv >/dev/null 2>&1; then
    USE_PV=true
  else
    log "WARN" "pv not found. Using dot progress fallback.
Install pv for better progress:
  Debian/Ubuntu: sudo apt install pv
  RHEL/CentOS:   sudo yum install pv
  macOS (brew):  brew install pv"
  fi
fi

# Recommend root
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  log "WARN" "Running without root. Some permissions/ACLs may not be fully readable."
  log "WARN" "Hint: Run with sudo for complete metadata capture."
fi

# Timing
START_TS="$(date +%s)"
START_AT="$(date '+%Y-%m-%d %H:%M:%S %z')"

# Tool capabilities (for summary)
TAR_VER="$(tar --version 2>/dev/null | head -n1 || echo 'tar (unknown)')"
TAR_HAS_XATTRS="no"
tar --help 2>/dev/null | grep -q -- '--xattrs' && TAR_HAS_XATTRS="yes"

# Announce (structured)
log "INFO" "Start       : ${START_AT}"
log "INFO" "Source      : ${SOURCE_DIR}"
log "INFO" "Output      : ${OUT_PATH}"
log "INFO" "Preserve    : permissions, ownership, ACLs"
log "INFO" "Options     : verify=$([ "$DO_VERIFY" = true ] && echo yes || echo no), xattrs=$([ "$INCLUDE_XATTRS" = true ] && echo yes || echo no), one_file_system=$([ "$ONE_FILE_SYSTEM" = true ] && echo yes || echo no), progress=$([ "${NO_PROGRESS}" = true ] && echo off || { [ "$USE_PV" = true ] && echo pv || echo dots; })"
log "INFO" "AtomicWrite : enabled (.part -> mv)"
log "INFO" "Tar Tool    : ${TAR_VER} (acls=yes, xattrs=${TAR_HAS_XATTRS})"

# Build tar options
declare -a TAR_OPTS
TAR_OPTS+=(--acls)            # include POSIX ACLs
TAR_OPTS+=(--numeric-owner)   # store numeric uid/gid (restore consistent across systems)
# Optionally include xattrs
if [ "$INCLUDE_XATTRS" = true ]; then
  # Validate that tar supports xattrs
  if tar --help 2>/dev/null | grep -q -- '--xattrs'; then
    TAR_OPTS+=(--xattrs --xattrs-include='*')
  else
    die "tar on this system does not support --xattrs; remove --xattrs flag or upgrade tar"
  fi
fi
TAR_OPTS+=(-cpf -)            # create to stdout
# Do NOT use --hard-dereference; we want to preserve links rather than dereference.
# Optionally avoid crossing filesystems:
if [ "$ONE_FILE_SYSTEM" = true ]; then
  TAR_OPTS+=(--one-file-system)
fi

# Fallback progress via tar checkpoints if pv is unavailable and progress not disabled
declare -a TAR_PROGRESS_OPTS=()
if [ "$USE_PV" = false ] && [ "${NO_PROGRESS:-false}" = false ]; then
  # Print a dot every 2000 records processed (adjust if needed)
  TAR_PROGRESS_OPTS+=(--checkpoint=2000 --checkpoint-action=dot)
  log "INFO" "Using fallback progress (dots)."
fi

# We archive the directory name by using -C parent and passing the basename
SRC_PARENT="$(dirname "$SOURCE_DIR")"
SRC_BASENAME="$(basename "$SOURCE_DIR")"

# Temporary file for atomic write
TMP_PATH="${OUT_PATH}.part"

# Remove stale temp if exists
rm -f "$TMP_PATH" 2>/dev/null || true

# Create
log "INFO" "Starting archive write (atomic)..."
set +e
if [ "$USE_PV" = true ]; then
  tar "${TAR_OPTS[@]}" -C "$SRC_PARENT" "$SRC_BASENAME" \
    | pv \
    > "$TMP_PATH"
  rc=$?
else
  if [ "${NO_PROGRESS:-false}" = false ]; then
    # Fallback with dots
    tar "${TAR_PROGRESS_OPTS[@]}" "${TAR_OPTS[@]}" -C "$SRC_PARENT" "$SRC_BASENAME" \
      > "$TMP_PATH"
  else
    # Silent mode by user choice
    tar "${TAR_OPTS[@]}" -C "$SRC_PARENT" "$SRC_BASENAME" \
      > "$TMP_PATH"
  fi
  rc=$?
fi
set -e

if [ $rc -ne 0 ]; then
  rm -f "$TMP_PATH" 2>/dev/null || true
  die "tar write failed with exit code $rc
Hint: Check free space at --dest and read permissions at --source."
fi

# Verification (list contents)
VERIFY_STATUS="skipped"
if [ "$DO_VERIFY" = true ]; then
  log "INFO" "Verify      : tar -tf (reading index)..."
  if tar -tf "$TMP_PATH" >/dev/null 2>&1; then
    VERIFY_STATUS="passed"
  else
    rm -f "$TMP_PATH" 2>/dev/null || true
    END_TS="$(date +%s)"
    END_AT="$(date '+%Y-%m-%d %H:%M:%S %z')"
    DURATION_SEC=$((END_TS - START_TS))
    DURATION_FMT=$(printf "%02d:%02d:%02d" $((DURATION_SEC/3600)) $(((DURATION_SEC%3600)/60)) $((DURATION_SEC%60)))
    log "ERROR" "Verification failed: cannot list archive"
    log "ERROR" "Hint: Try running again with --no-progress; check free space and special files in source."
    log "SUMMARY" "Status    : FAILURE"
    log "SUMMARY" "Phase     : verify"
    log "SUMMARY" "Start     : ${START_AT}"
    log "SUMMARY" "End       : ${END_AT}"
    log "SUMMARY" "Duration  : ${DURATION_FMT}"
    log "SUMMARY" "Source    : ${SOURCE_DIR}"
    log "SUMMARY" "Output    : ${OUT_PATH}.part"
    log "SUMMARY" "Verify    : failed"
    log "SUMMARY" "ExitCode  : 1"
    exit 1
  fi
fi

# Move into place atomically
mv -f "$TMP_PATH" "$OUT_PATH"

# Set ownership/permissions of the resulting file (for Duplicati/rclone consumer)
if ! chown "$OWNER_UIDGID" "$OUT_PATH" 2>/dev/null; then
  log "WARN" "chown failed on $OUT_PATH (owner:group ${OWNER_UIDGID})"
  log "WARN" "Hint: Ensure the UID:GID exists or adjust with --owner."
fi
if ! chmod "$FILE_MODE" "$OUT_PATH" 2>/dev/null; then
  log "WARN" "chmod failed on $OUT_PATH (mode ${FILE_MODE})"
  log "WARN" "Hint: Adjust mode with --mode (e.g., 0640)."
fi

# Size determination (human readable)
HUM_SIZE=""
if command -v du >/dev/null 2>&1; then
  HUM_SIZE="$(du -h "$OUT_PATH" 2>/dev/null | awk '{print $1}')"
fi

log "DONE" "Archive OK  : $OUT_PATH"
log "INFO" "PostProcess : owner=${OWNER_UIDGID}, mode=${FILE_MODE}"

# Timing end and summary
END_TS="$(date +%s)"
END_AT="$(date '+%Y-%m-%d %H:%M:%S %z')"
DURATION_SEC=$((END_TS - START_TS))
DURATION_FMT=$(printf "%02d:%02d:%02d" $((DURATION_SEC/3600)) $(((DURATION_SEC%3600)/60)) $((DURATION_SEC%60)))

log "SUMMARY" "Status    : SUCCESS"
log "SUMMARY" "Start     : ${START_AT}"
log "SUMMARY" "End       : ${END_AT}"
log "SUMMARY" "Duration  : ${DURATION_FMT}"
log "SUMMARY" "Source    : ${SOURCE_DIR}"
log "SUMMARY" "Output    : ${OUT_PATH}"
[ -n "$HUM_SIZE" ] && log "SUMMARY" "Size      : ${HUM_SIZE}"
log "SUMMARY" "Verify    : ${VERIFY_STATUS}"
log "SUMMARY" "Options   : --acls --numeric-owner $([ "$INCLUDE_XATTRS" = true ] && echo --xattrs || echo '[xattrs disabled]') $([ "$ONE_FILE_SYSTEM" = true ] && echo --one-file-system || echo '[one-file-system disabled]')"
log "SUMMARY" "Progress  : $([ "${NO_PROGRESS}" = true ] && echo off || { [ "$USE_PV" = true ] && echo pv || echo dots; })"
log "SUMMARY" "ExitCode  : 0"

# Restore tips:
#   With ACLs:        sudo tar --acls -xpf docker-backup-latest-for-duplicati.tar -C /restore/target
#   With ACLs+xattrs: sudo tar --acls --xattrs -xpf docker-backup-latest-for-duplicati.tar -C /restore/target
# Ensure ACLs (and xattrs if used) are enabled on the target filesystem.