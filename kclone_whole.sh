#!/bin/bash

# Author: Keane Audric
# GitHub: https://github.com/KeaneAudric01
# Version: 0.1.0

# User specific variables
FOLDER_PATH=""  # The folder to be backed up (e.g., "/root/abc")
DESTINATION_FOLDER=""  # The folder name on Google Drive (e.g., "testbackup")
LOG_FILE=""  # Log file path (e.g., "/root/kclone_log.txt")
TEMP_FOLDER=""  # The folder where the temporary tar.gz file will be stored (e.g., "/root")
MAX_BACKUPS=5  # Maximum number of backups to keep
COMPRESSION_LEVEL=9  # Compression level from 1 (fastest, least compressed) to 9 (slowest, most compressed)

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")

echo "Starting backup for $FOLDER_PATH" >> $LOG_FILE

echo "Creating destination folder $DESTINATION_FOLDER on Google Drive" >> $LOG_FILE
if ! rclone mkdir "kclone:$DESTINATION_FOLDER" >> $LOG_FILE 2>&1; then
  echo "Failed to create destination folder $DESTINATION_FOLDER on Google Drive" >> $LOG_FILE
  exit 1
fi

DIR_NAME=$(basename $FOLDER_PATH)
echo "Compressing $FOLDER_PATH" >> $LOG_FILE
TAR_FILE="$TEMP_FOLDER/${DIR_NAME}.kclone_$TIMESTAMP.tar.gz"
GZIP=-$COMPRESSION_LEVEL tar -czf $TAR_FILE -C $(dirname $FOLDER_PATH) $(basename $FOLDER_PATH) >> $LOG_FILE 2>&1
if [ $? -eq 0 ]; then
  echo "Compress $FOLDER_PATH successful" >> $LOG_FILE
else
  echo "Compress $FOLDER_PATH failed" >> $LOG_FILE
  exit 1
fi

echo "Uploading $TAR_FILE" >> $LOG_FILE
if rclone copy $TAR_FILE "kclone:$DESTINATION_FOLDER" >> $LOG_FILE 2>&1; then
  echo "Upload $TAR_FILE successful" >> $LOG_FILE
else
  echo "Upload $TAR_FILE failed" >> $LOG_FILE
  exit 1
fi

echo "Deleting temporary file $TAR_FILE" >> $LOG_FILE
if rm $TAR_FILE; then
  echo "Temporary file deletion successful" >> $LOG_FILE
else
  echo "Temporary file deletion failed" >> $LOG_FILE
  exit 1
fi

echo "Checking for old backups to remove" >> $LOG_FILE
if [ $MAX_BACKUPS -ne -1 ]; then
  BACKUPS=$(rclone ls "kclone:$DESTINATION_FOLDER" | wc -l)
  echo "Number of backups: $BACKUPS" >> $LOG_FILE
  if [ $BACKUPS -gt $MAX_BACKUPS ]; then
    OLDEST_BACKUP=$(rclone lsf "kclone:$DESTINATION_FOLDER" | head -n 1)
    echo "Deleting oldest backup $OLDEST_BACKUP" >> $LOG_FILE
    if ! rclone delete "kclone:$DESTINATION_FOLDER/$OLDEST_BACKUP" >> $LOG_FILE 2>&1; then
      echo "Failed to delete oldest backup $OLDEST_BACKUP" >> $LOG_FILE
      exit 1
    fi
  fi
fi

echo "Backup process completed" >> $LOG_FILE
