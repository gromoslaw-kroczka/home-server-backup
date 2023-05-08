<p align="center">
  Multi-purpose <b>Backup script</b> dedicated for <b>Home Servers</b>
</p>

> :exclamation: Work-in-progress :hammer:\
Script under developement, designed for homelab application.\
Feel free to test, modify, report bugs & propose features.\
Have fun :rocket:

## Table of content
* [Features][1]
* [Prequisitions and Dependencies][2]
* [Files descriptions][3]
* [How to use it][4]
* [Configuration][5]
* [Developement checklists][6]

## Features
* Separate `parameters.sh` file for settings & sensitive data
* Core functionalities:
    * Multiple directory local backup:
        * Docker Volumes
            * With stopping containers
        * Docker Bind Mounts
            * With /or without stopping containers
        * Server Home Directory
            * Separated by sub-directiories
    * Cloud backup using `rclone`
    * Delete old backup files (both locally & in the Cloud)
    * Archive locally backup every 10 days
* Additional functionalities:
    * Gotify notifications
    * Netdata notifications silencer during backup

## Prequisitions and Dependencies
* Linux environment (to execute bash script)
* For required dependencies for each feature see [How to use it][4]

## Files descriptions
File  | Description
-- | --
`homeServerBackup.sh`  | *core* of the application
`parameters-sample.sh`  | external file with settings & sensitive data
`.gitignore` | git configuration file
`.shellcheckrc` | [ShellCheck][shellCheck] configuration file
`README.md` | documentation file
`LICENSE.md` | open source license details

## How to use it
1. Clone GitHub repository to you server
2. Make core script executable\
    ```shell
    $ chmod u+x homeServerBackup.sh
    ```
3. Execute it\
`$ sudo ./homeServerBackup.sh -t <TYPE (instant/daily)>`\
    `instant` => used for executing script from terminal\
    `daily` => used in 'sudo crontab' for scheduled backups\
4. For scheduled backups add above line as cronjob (preferebly with 'daily' type)
    1. Open crontab\
    ```shell
    $ sudo crontab -e
    ```
    2. Add scheduled script execution\
        For example below code with execute script located in <example directory> everyday at 2:00 am.\
    ```shell
    * 2 * * * cd /<example directory> && ./homeServerBackup.sh -t daily
    ```
        To set up cron schedule expressions see [crontab gutu][crontab]\

## Configuration
> :exclamation: Before changing any settings / parameters copy `parameters-sample.sh` file and remove `-sample` part of the name\
```shell
$ cp parameters-sample.sh parameters.sh
```

### 00. Functionality
Comment out (with <#>) features to exclude them from executing
```shell
declare -a functionality=(
    'Local Backup | Home directory'
    'Local Backup | Docker Volumes'
    'Local Backup | Docker Bind Mounts'
    'Cloud Backup'
    'Daily-backup cleaner'
    'Daily-backup cloud cleaner'
    'Daily-backup archiver'
)
```
To run Docker Volumes & Bind Mounts backups you need Docker environment.\
To run Cloud Backup you have to have installed [rclone][rclone] and remote configured (named as *homeServerBackup*)

### 01. Directories & folders
Set up your:
* Backup Directory - local destination of backups
* Home Directory - server Home directory + name of it (of the backup)
```shell
#   Local Backup Directory
declare -x backupDir="path/to/location/where/backup/will/be/stored"
#
#   Server Home Directory
declare -x homeDir="/your/home/directory"
#
#   Name for backup of Server Home Directory
declare -x homeName="homeYourNameForExample"
```

### 02. Arrays of Docker Containers
Set up details of your Docker Volumes you would like to backup.
```shell
#   declare -A volumeDocker00=(
#       [container]='Container name'
#       [volumePath]='Path to volume'
#       [name]='Backup .tar file name'
#       [stop]=true #or 'false' if you want to backup without stopping the container
#    )
#
declare -x -A volumeDocker00=(
    [container]='1st-container'
    [volumePath]='/path/to/volume'
    [name]='1st-container-backup'
    [stop]=true
)
#
declare -x -A volumeDocker01=(
    [container]='2nd-container'
    [volumePath]='/path/to/volume'
    [name]='2nd-container-backup'
    [stop]=false
)
```

### 03. Associative Array
Expend list of docker volumes to correspond with number of your Docker Volumes. This part of the settings will be moved to *core* code in the future. See [Issue #18][issue_18]
```shell
declare -x -a volumeDockers=(
    'volumeDocker00'
    'volumeDocker01'
)
```

### 04. List od Docker Containers with Bind Mounts
Set up you Docker Containers of which you would like to backup Bind Mounts. Code assume that you have Bind Mounts located in directory `homeDir/Docker/<container name>`. For each of the Docker Container you can choose whether to stop during backup or not.
```shell
declare -x bindDocker=(
    '3rd-container'
    '4th-container'
)
#
#   List of Docker Container with Bind Mounts to stop during backup
declare -x bindDockerStop=(
    #'3rd-container'
    #'4th-container'
)
```

### 05. Gotify Configurations
Set up Gotify server to notify you after each backup.
```shell
#   Gotify website + token, for example: https://push.example.de/message?token=<apptoken>
declare -x GotifyHost="https://push.example.de/message?token=<apptoken>"
#
#   Title of Notification
declare -x GotifyTitle="yourServerName"
```

### 06. Netdata silencer
Backup of the server could couse high disk backlog and therefore *spam* notifications from Netdata about it (if you have that tool installed on the server). You can disable those notifications for the time of the backup script.
```shell
#   Replace <apptoken> with Netdata 'api authorization token'
#   that is stored in the file you will see in the following entry of http://NODE:19999/netdata.conf:
#       [registry]
#           # netdata management api key file = /var/lib/netdata/netdata.api.key
declare -x NetdataAuthToken="<apptoken>"
#
#   Change to 'true' to enable Netdata silencer
declare -x NetdataSilencer=false
```
If you would like to silende Netdata backlog notification not only for the time of the backup but also other scheduled activities (like automatic updates) it is better to disable those directly in the crontab:
```shell
# Disable Netdata disk.backlog notifications during scheduled activities
0 0 * * * docker exec netdata curl -s "http://localhost:19999/api/v1/manage/health?cmd=SILENCE&context=disk.backlog" -H "X-Auth-Token: <apptoken>"

# Daily Backups
0 1 * * * cd /<example directory> && ./homeServerBackup.sh -t daily

# Re-enable Netdata silenced notifications
0 3 * * * docker exec netdata curl -s "http://localhost:19999/api/v1/manage/health?cmd=RESET" -H "X-Auth-Token: <apptoken>"
```

## Developement checklist
- [X] Functionality chooser
- [X] `dev` mode [#7][issue_07]
- [X] Gotify Notifications [#6][issue_06]
- [X] Netdata notification silencer
- [X] Choose to stop /or not containers during bind mounts backup
- [X] (?) Choose to stop /or not containers during volume backup
- [X] Appropriate script description in README.md file [#1][issue_01]
- [ ] Conditional messages - depend if script success or not [#2][issue_02]
- [ ] Release version to download (in which file format?) [#3][issue_03]
- [ ] Clean up configuration of Docker Volumes [#18][issue_18]

[1]: https://github.com/gromoslaw-kroczka/home-server-backup#features
[2]: https://github.com/gromoslaw-kroczka/home-server-backup#Prequisitions-and-dependencies
[3]: https://github.com/gromoslaw-kroczka/home-server-backup#files-descriptions
[4]: https://github.com/gromoslaw-kroczka/home-server-backup#how-to-use-it
[5]: https://github.com/gromoslaw-kroczka/home-server-backup#configuration
[6]: https://github.com/gromoslaw-kroczka/home-server-backup#development-checklist
[schellCheck]: https://www.shellcheck.net/
[crontab]: https://crontab.guru/
[rclone]: https://github.com/rclone/rclone
[issue_01]: https://github.com/gromoslaw-kroczka/home-server-backup/issues/1
[issue_02]: https://github.com/gromoslaw-kroczka/home-server-backup/issues/2
[issue_03]: https://github.com/gromoslaw-kroczka/home-server-backup/issues/3
[issue_06]: https://github.com/gromoslaw-kroczka/home-server-backup/issues/6
[issue_07]: https://github.com/gromoslaw-kroczka/home-server-backup/issues/7
[issue_18]: https://github.com/gromoslaw-kroczka/home-server-backup/issues/18