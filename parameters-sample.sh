#!/bin/bash
#
#===========================================================================#
#   
#region | 00.   Functionality
#
#   Comment out with <#> tasks to exclude them from executing
#
declare -a functionality=(
    'Local Backup | Home directory'
    'Local Backup | Docker Volumes'
    'Local Backup | Docker Bind Mounts'
    'Cloud Backup'
    'Daily-backup cleaner'
    'Daily-backup archiver'
    'Daily-backup cloud cleaner'
)
#
#endregion
#
#===========================================================================#
#   
#region | 01.   Declare directories & folders
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
#endregion
#
#===========================================================================#
#
#region | 02.   Declare Arrays of Docker Containers
#
#   declare -A volumeDocker00=(
#       [container]='Container name'
#       [volumePath]='Path to volume'
#       [name]='Backup .tar file name'
#    )
#
declare -x -A volumeDocker00=(
    [container]='1st-container'
    [volumePath]='/path/to/volume'
    [name]='1st-container-backup'
)
#
declare -x -A volumeDocker01=(
    [container]='2nd-container'
    [volumePath]='/path/to/volume'
    [name]='2nd-container-backup'
)
#
#endregion
#
#===========================================================================#
# 
#region | 03.   Declare Associative Array
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
declare -x bindDocker=(
    '3rd-container'
    '4th-container'
)
#
#
#   List of Docker Container with Bind Mounts to stop during backup
#
declare -x bindDockerStop=(
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
#
declare -x GotifyHost="https://push.example.de/message?token=<apptoken>"
#
#   Title of Notification
#
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
#
declare -x NetdataAuthToken="<apptoken>"
#
#
#   #Change to 'false' to disable Netdata silencer
#
declare -x NetdataSilencer=true
#
#
#endregion



