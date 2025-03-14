#!/bin/bash

# Author: Keane Audric
# GitHub: https://github.com/KeaneAudric01
# Version: 0.1.0

set -euo pipefail

# User specific variables
FOLDER_PATH=""          # The folder to be backed up (e.g., "/root/abc")
DESTINATION_FOLDER=""   # The folder name on Google Drive (e.g., "testbackup")
LOG_FILE=""             # Log file path (e.g., "/root/kclone_log.txt")
TEMP_FOLDER=""          # The folder where the temporary tar.gz file will be stored (e.g., "/root")
MAX_BACKUPS=5           # Maximum number of backups to keep
COMPRESSION_LEVEL=9     # Compression level from 1 (fastest, least compressed) to 9 (slowest, most compressed)

if [[ -z "${FOLDER_PATH}" || -z "${DESTINATION_FOLDER}" || -z "${LOG_FILE}" || -z "${TEMP_FOLDER}" ]]; then
  echo "Error: One or more required variables (FOLDER_PATH, DESTINATION_FOLDER, LOG_FILE, TEMP_FOLDER) are not set."
  exit 1
fi

command -v rclone >/dev/null 2>&1 || { echo "Error: rclone is required but not installed." >> "$LOG_FILE"; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "Error: tar is required but not installed." >> "$LOG_FILE"; exit 1; }

log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $1" >> "$LOG_FILE"
}

cleanup() {
  if [[ -n "${TAR_FILE:-}" && -f "$TAR_FILE" ]]; then
    rm -f "$TAR_FILE"
    log "Temporary file $TAR_FILE removed during cleanup"
  fi
  exit 1
}
trap cleanup SIGINT SIGTERM

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

log "Starting backup for $FOLDER_PATH"

log "Creating destination folder $DESTINATION_FOLDER on Google Drive"
if ! rclone mkdir "kclone:$DESTINATION_FOLDER" >> "$LOG_FILE" 2>&1; then
  log "Failed to create destination folder $DESTINATION_FOLDER on Google Drive"
  exit 1
fi

for ITEM in "$FOLDER_PATH"/*; do
  ITEM_NAME=$(basename "$ITEM")
  TAR_FILE="$TEMP_FOLDER/${ITEM_NAME}.kclone_${TIMESTAMP}.tar.gz"
  
  if [ -d "$ITEM" ]; then
    log "Compressing directory $ITEM"
    if env GZIP=-"$COMPRESSION_LEVEL" tar -czf "$TAR_FILE" -C "$(dirname "$ITEM")" "$(basename "$ITEM")" >> "$LOG_FILE" 2>&1; then
      log "Compression of directory $ITEM successful"
    else
      log "Compression of directory $ITEM failed"
      exit 1
    fi
  elif [ -f "$ITEM" ]; then
    log "Compressing file $ITEM"
    if env GZIP=-"$COMPRESSION_LEVEL" tar -czf "$TAR_FILE" -C "$(dirname "$ITEM")" "$(basename "$ITEM")" >> "$LOG_FILE" 2>&1; then
      log "Compression of file $ITEM successful"
    else
      log "Compression of file $ITEM failed"
      exit 1
    fi
  else
    log "$ITEM is not a file or directory, skipping"
    continue
  fi
  
  log "Uploading $TAR_FILE"
  if rclone copy "$TAR_FILE" "kclone:$DESTINATION_FOLDER" >> "$LOG_FILE" 2>&1; then
    log "Upload of $TAR_FILE successful"
  else
    log "Upload of $TAR_FILE failed"
    exit 1
  fi
  
  log "Deleting temporary file $TAR_FILE"
  if rm "$TAR_FILE"; then
    log "Temporary file deletion successful"
  else
    log "Temporary file deletion failed"
    exit 1
  fi
done

log "Checking for old backups to remove"
if [ "$MAX_BACKUPS" -ne -1 ]; then
  while [ "$(rclone ls "kclone:$DESTINATION_FOLDER" | wc -l)" -gt "$MAX_BACKUPS" ]; do
    OLDEST_BACKUP=$(rclone lsf "kclone:$DESTINATION_FOLDER" --max-depth 1 | sort | head -n 1)
    log "Deleting oldest backup $OLDEST_BACKUP"
    if ! rclone delete "kclone:$DESTINATION_FOLDER/$OLDEST_BACKUP" >> "$LOG_FILE" 2>&1; then
      log "Failed to delete oldest backup $OLDEST_BACKUP"
      exit 1
    fi
  done
fi

log "Backup process completed"