#!/bin/bash
#
#===========================================================================#
#   
#region | 00.   Functionality and basic settings
#
#   Comment out with <#> features to exclude them from executing in 'instant' backups
declare -x -a functionalityInstant=(
    'Local Backup | Home directory'
    'Local Backup | Docker Volumes'
    'Local Backup | Docker Bind Mounts'
    'Cloud Backup'
    # (!) It is advised to use below features only for 'daily' backups
    #'Daily-backup cleaner'
    #'Daily-backup cloud cleaner'
    #'Daily-backup archiver'
)
#
#   Comment out with <#> features to exclude them from executing in 'daily' backups
declare -x -a functionalityDaily=(
    'Local Backup | Home directory'
    'Local Backup | Docker Volumes'
    'Local Backup | Docker Bind Mounts'
    'Cloud Backup'
    'Daily-backup cleaner'
    'Daily-backup cloud cleaner'
    'Daily-backup archiver'
)
#
#   Choose how many daily backups you want to keep (daily-cleaner settings)
declare -x -i dailyLocal=5
declare -x -i dailyCloud=5
#
#endregion
#
#===========================================================================#
#   
#region | 01.   Directories & folders
#
#   Local Backup Directory
declare -x backupDir="path/to/location/where/backup/will/be/stored"
#
#   Server Home Directory
declare -x homeDir="/your/home/directory"
#
#   Name for backup of Server Home Directory
declare -x homeName="homeYourNameForExample"
#
#   Exclude those homeDir sub-directories from backup
declare -x -a excludeDir=(
    'photos'                #exclude homeDir/photos
    'folder/sub-folder'     #exclude homeDir/folder/sub-folder
)
#
#endregion
#
#===========================================================================#
#
#region | 02.   Arrays of Docker Containers
#
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
#
#endregion
#
#===========================================================================#
# 
#region | 03.   Associative Array
#
declare -x -a volumeDockers=(
    'volumeDocker00'
    'volumeDocker01'
)
#
#endregion
#
#===========================================================================#
#
#region | 04.   List od Docker Containers with Bind Mounts
#
declare -x -a bindDocker=(
    '3rd-container'
    '4th-container'
)
#
#   List of Docker Container with Bind Mounts to stop during backup
declare -x -a bindDockerStop=(
    #'3rd-container'
    #'4th-container'
)
#
#endregion
#
#===========================================================================#
#
#region | 05.   Gotify Configurations
#
#   Gotify website + token, for example: https://push.example.de/message?token=<apptoken>
declare -x GotifyHost="https://push.example.de/message?token=<apptoken>"
#
#   Title of Notification
declare -x GotifyTitle="yourServerName"
#
#endregion
#
#===========================================================================#
#
#region | 06.   Netdata silencer
#
#   Replace <apptoken> with Netdata 'api authorization token'
#   that is stored in the file you will see in the following entry of http://NODE:19999/netdata.conf:
#       [registry]
#           # netdata management api key file = /var/lib/netdata/netdata.api.key
declare -x NetdataAuthToken="<apptoken>"
#
#   Change to 'true' to enable Netdata silencer
declare -x NetdataSilencer=false
#
#
#endregion