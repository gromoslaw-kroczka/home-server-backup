#!/bin/bash
#===========================================================================#
#===========================================================================#
#                                                                           #
#                       HOME SERVER BACKUP SCRIPT                           #
#                                                                           #
#===========================================================================#
#===========================================================================#
#                                                                           #
#   Author:             Gromosław Kroczka                                   #
#   Author's GitHub:    https://github.com/gromoslaw-kroczka                #
#                                                                           #
#===========================================================================#
#===========================================================================#
#                                                                           #
#                       Table of contents                                   #
#                                                                           #
#   01.     How to use it                                                   #
#   02.     Declarations of parameters                                      #
#   03.     Local Backup                                                    #
#   03.01.      Docker Volumes                                              #
#   03.02.      Docker Bind Mounts                                          #
#   03.02.      Home directory                                              #
#   04.     Cloud Backup                                                    #
#   05.     Daily-backup cleaner                                            #
#   06.     Daily-backup archiver                                           #
#   07.     Script summary                                                  #
#                                                                           #
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 01.       How to use it                                           #
#                                                                           #
#===========================================================================#
#
#   To execute it, use the following command:
#   $ sudo ./homeServerBackup.sh -t <TYPE (instant/daily)>
#       <instant> used for executing script from terminal
#       <daily> used in 'sudo crontab' for scheduled backups
#
#   For <instant> backup cleaner [05.] and archiver [06.] is N/A
#
#   Check if run as root / sudo
if [ "$EUID" -ne 0 ]
  then echo "Please run as root / sudo"
  exit
fi
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 02.       Declarations of parameters                              #
#                                                                           #
#===========================================================================#
#
#region | 02.01.        Declare type
#
while getopts t: flag
do
    case "${flag}" in
        t) type=${OPTARG};;
        *) echo "usage: $0 [-t] <TYPE (instant/daily)>
            <instant> used for executing script from terminal
            <daily> used in 'sudo crontab' for scheduled backups" >&2
            exit 1 ;;
    esac
done
#
#endregion
#
#===========================================================================#
#
#region | 02.02.        Declare today in format YYYY-MM-DD_HH-MM-SS
#
today="$(date '+%F_%H-%M-%S')"
#
#endregion
#
#===========================================================================#
#
#region | 02.03.        Declare today in format DD
#
todayDayOfMonth="$(date '+%d')"
#
#endregion
#
#===========================================================================#
#
#region | 02.04.        Import parameters
#
source parameters.sh
#
#endregion
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 03.01.    Local Backup | Docker Volumes                           #
#                                                                           #
#===========================================================================#
#
#   Loop trought volumeDockers Associative Array
#       Stop docker container
#       Create backup directory
#       Perform backup
#       Restart stopped docker container
#
declare -n volumeDocker
for volumeDocker in "${volumeDockers[@]}"; do
    docker stop "${volumeDocker[container]}" && \
    mkdir -pv "$backupDir"/"$type"/"$today" && \
    docker run --rm --volumes-from "${volumeDocker[container]}" \
    -v "$backupDir"/"$type"/"$today":/backup \
    ubuntu tar cvf /backup/"${volumeDocker[name]}".tar "${volumeDocker[volumePath]}" && \
    docker start "${volumeDocker[container]}" && \
    echo "== ${volumeDocker[container]} backuped"
done
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 03.02.    Local Backup | Docker Bind Mounts                       #
#                                                                           #
#===========================================================================#
#
#   Loop trought bindDocker array
#       Stop docker container
#       Create backup directory
#       Perform backup
#       Restart stopped docker container
#
for container in "${bindDocker[@]}"
do
    docker stop "$container" && \
    mkdir -pv "$backupDir"/"$type"/"$today" && \
    tar cvf "$backupDir"/"$type"/"$today"/"$container".tar "$homeDir"/docker/"$container" && \
    docker start "$container" && \
    echo "== $container backuped"
done
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 03.03.    Local Backup | Home directory                           #
#                                                                           #
#===========================================================================#
#
#   Create backup directory
#   Perform backup
#
mkdir -pv "$backupDir"/"$type"/"$today" && \
tar --exclude="docker" -cvf "$backupDir"/"$type"/"$today"/"$homeName".tar "$homeDir"/
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 04.       Cloud Backup                                            #
#                                                                           #
#===========================================================================#
#
#   Copy daily backup to the Cloud (encrypted)
#
docker run --rm \
    --volume "$homeDir"/docker/rclone/config:/config/rclone \
    --volume "$homeDir":"$homeDir" \
    --volume "$backupDir":"$backupDir" \
    --user "$(id -u)":"$(id -g)" \
    rclone/rclone \
    copy --progress "$backupDir"/"$type"/"$today" homeServerBackup:"$type"/"$today"
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 05.       Daily-backup cleaner                                    #
#                                                                           #
#===========================================================================#
#
#   Execute these commands only for daily backups:
#       Delete directiories (backups) older than 4 days
#       It keeps todays backup + 4 daily earliers
#
if [ "$type" == "daily" ]; then
    find "$backupDir"/"$type"/ -type d -mtime +4 -exec rm -rf "{}" \;
fi
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 06.       Daily-backup archiver                                   #
#                                                                           #
#===========================================================================#
#
#   Execute these commands only for daily backups:
#        If it's 1st, 11th or 21st day of month:
#           Copy todays backup to archive
#
if [ "$type" == "daily" ]; then
    if [ "$todayDayOfMonth" -eq 1 ] || [ "$todayDayOfMonth" -eq 11 ] || [ "$todayDayOfMonth" -eq 21 ]; then
        rsync -r "$backupDir"/"$type"/"$today" "$backupDir"/archive/ 
    fi
fi
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 07.       Script Summary                                          #
#                                                                           #
#===========================================================================#
#
#   Declare parameter when script've finished 
#
endTime="$(date '+%F_%H-%M-%S')"
#
#   echo short summary
#
echo "==== Backup complete successfully"
echo "==== Start: $today"
echo "==== End: $endTime"
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#                                   THE END                                 #
#                                                                           #
#===========================================================================#
#===========================================================================#



