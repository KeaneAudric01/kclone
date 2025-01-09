# Backup Scripts 🚀

Shell scripts for automated backup to cloud storage using rclone. Supports both whole folder and individual content backup options.

## Features ✨

- Backup entire folders or individual files to Google Drive.
- Configurable compression levels.
- Automatic cleanup of old backups.
- Detailed logging of backup operations.

## Requirements 🛠️

- [rclone](https://rclone.org/downloads/) installed and configured with access to your Google Drive.

## Installation 📋

1. Install rclone:
    ```sh
    sudo -v ; curl https://rclone.org/install.sh | sudo bash
    # or
    sudo apt install rclone
    ```

2. Install zip:
    ```sh
    sudo apt install zip
    ```

3. Configure rclone:
    ```sh
    rclone config
    # Follow the prompts:
    # - new remote (n)
    # - remote name: kclone
    # - storage: google drive
    # - client_id: "empty"
    # - client_secret: "empty"
    # - scope: full access (1)
    # - service_account_file: "empty"
    # - edit advanced config: no
    # - use auto config: yes
    #
    # Authorize Google Drive by following the link. If unable to do so on the server machine, use SSH with port forwarding:
    # ssh -L 53682:127.0.0.1:53682 root@your_host_ip
    #
    # - configure this as a shared drive: no
    # - keep this remote: yes
    ```

4. Clone the repository:
    ```sh
    git clone https://github.com/KeaneAudric01/kclone.git
    cd kclone
    ```

5. Make the scripts executable:
    ```sh
    chmod +x kclone_content.sh
    chmod +x kclone_whole.sh
    ```

## Usage 📋

### Backup Individual Files and Folders

Use `kclone_content.sh` to backup individual files and folders within a specified directory.

```sh
./kclone_content.sh
```

### Backup Entire Folder

Use `kclone_whole.sh` to backup an entire folder.

```sh
./kclone_whole.sh
```

## Configuration 🛠️

Edit the following variables in the scripts to match your setup:

- `FOLDER_PATH`: The folder to be backed up.
- `DESTINATION_FOLDER`: The folder name on Google Drive.
- `LOG_FILE`: Log file path.
- `TEMP_FOLDER`: The folder where the temporary tar.gz file will be stored.
- `MAX_BACKUPS`: Maximum number of backups to keep.
- `COMPRESSION_LEVEL`: Compression level from 1 (fastest, least compressed) to 9 (slowest, most compressed).

## Optional: Automate Backups with Cron 🕒

To automate the backup process, you can set up a cron job:

```sh
crontab -e
```

Add one of the following lines to schedule the backup script:

```sh
0 * * * * /root/backup.sh         # Every hour
0 */3 * * * /root/backup.sh       # Every 3 hours
0 */6 * * * /root/backup.sh       # Every 6 hours
0 */12 * * * /root/backup.sh      # Every 12 hours
0 0 * * * /root/backup.sh         # Every 24 hours
```

## License 📄

This project is licensed under the MIT License. See the [LICENSE](https://github.com/KeaneAudric01/kclone/blob/main/LICENSE) file for details.

## Author 👤

Keane Audric

GitHub: [KeaneAudric01](https://github.com/KeaneAudric01)
