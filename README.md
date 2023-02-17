# Home Server Backup Script

## Features:
* Multiple directory backup:
    * Docker Volumes
    * Docker Bind Mounts
    * Server Home Directory
* Cloud backup using `rclone`
* Delete old backup files
* Archive bakcup every 10 days

## To execute it, use the following command:
`$ sudo ./homeServerBackup.sh -t <TYPE (instant/daily)>`
    <instant> used for executing script from terminal
    <daily> used in 'sudo crontab' for scheduled backups

## TODO list
* TODO Add appropriate script description in README.md file
* TODO Add conditional messages - depend if script success or not