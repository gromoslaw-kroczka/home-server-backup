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
#   02.     Declarations of parameters & log setting                        #
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
#region | 02.       Declarations of parameters & log setting                #
#                                                                           #
#===========================================================================#
#
#region | 02.01.    Time variables
#
#   Start time in format YYYY-MM-DD_HH-MM-SS
today="$(date '+%F_%H-%M-%S')"
#
#   Strat time in format DD
todayDayOfMonth="$(date '+%d')"
#
#endregion
#
#===========================================================================#
#
#region | 02.02.    'type' parameter
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
declare -a typeChecker=(
    'instant'
    'daily'
    'dev'
)
#
if  [[ ! "${typeChecker[*]}" =~ "${type}" ]]; then
    echo "usage: $0 [-t] <TYPE (instant/daily)>
            <instant> used for executing script from terminal
            <daily> used in 'sudo crontab' for scheduled backups" >&2
            exit 1
fi
#
if  [[ "${typeChecker[*]}" =~ 'dev' ]]; then
    echo "Let's have some fun!"
fi
#
#endregion
#
#===========================================================================#
#
#region | 02.03.    Logs settings
#
echo "Logs available in logs/log_"$type"_"$today".out"
#
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>logs/log_"$type"_"$today".out 2>&1
#
#   Everything below will go to the log gile file in logs directory
echo "=================================================="
echo "homeServerBackup script launched $today"
echo "=================================================="
#
#endregion
#
#===========================================================================#
#
#region | 02.04.    Import parameters
#
if [ "$type" == "dev" ]; then
    source parameters-dev.sh
else
    source parameters.sh
fi
#
#endregion
#
#===========================================================================#
#
#region | 02.05.    Netdata silencer
#
# Disable all health notifications during backup
if [ "$NetdataSilencer" == true ]; then
    echo "==================================================" && \
    sudo docker exec -it netdata curl "http://localhost:19999/api/v1/manage/health?cmd=SILENCE&context=disk.backlog" -H "X-Auth-Token: $NetdataAuthToken" && \
    echo "Netdata health notifications disabled" && \
    echo "=================================================="
fi
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
if  [[ "${functionality[*]}" =~ "Local Backup | Docker Volumes" ]]; then
    declare -n volumeDocker
    for volumeDocker in "${volumeDockers[@]}"; do
        if [ "${volumeDocker[stop]}" == true ]; then
            docker stop "${volumeDocker[container]}" && \
            mkdir -pv "$backupDir"/"$type"/"$today" && \
            docker run --rm --volumes-from "${volumeDocker[container]}" \
            -v "$backupDir"/"$type"/"$today":/backup \
            ubuntu tar cvf /backup/"${volumeDocker[name]}".tar "${volumeDocker[volumePath]}" && \
            docker start "${volumeDocker[container]}" && \
            echo "==================================================" && \
            echo "${volumeDocker[container]} stopped, Volume backuped and restarted" && \
            echo "=================================================="
        else
            mkdir -pv "$backupDir"/"$type"/"$today" && \
            docker run --rm --volumes-from "${volumeDocker[container]}" \
            -v "$backupDir"/"$type"/"$today":/backup \
            ubuntu tar cvf /backup/"${volumeDocker[name]}".tar "${volumeDocker[volumePath]}" && \
            echo "==================================================" && \
            echo "${volumeDocker[container]} Volume backuped" && \
            echo "=================================================="
        fi
    done
fi
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
#       Stop docker container (if selected so in parameters)
#       Create backup directory
#       Perform backup
#       Restart stopped docker container (if previously stopped)
#
if  [[ "${functionality[*]}" =~ "Local Backup | Docker Bind Mounts" ]]; then
    for container in "${bindDocker[@]}"
    do
        if  [[ "${bindDockerStop[*]}" =~ "$container" ]]; then
            docker stop "$container" && \
            mkdir -pv "$backupDir"/"$type"/"$today" && \
            tar cvf "$backupDir"/"$type"/"$today"/"$container".tar "$homeDir"/docker/"$container" && \
            docker start "$container" && \
            echo "==================================================" && \
            echo "$container stopped, Bind Mount backuped and restarted" && \
            echo "=================================================="
        else
            mkdir -pv "$backupDir"/"$type"/"$today" && \
            tar cvf "$backupDir"/"$type"/"$today"/"$container".tar "$homeDir"/docker/"$container" && \
            echo "==================================================" && \
            echo "$container Bind Mount backuped" && \
            echo "=================================================="
        fi
    done
fi
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
if  [[ "${functionality[*]}" =~ "Local Backup | Home directory" ]]; then
    mkdir -pv "$backupDir"/"$type"/"$today" && \
    tar --exclude="docker" -cvf "$backupDir"/"$type"/"$today"/"$homeName".tar "$homeDir"/
    echo "==================================================" && \
    echo "$homeDir backuped as $homeName" && \
    echo "=================================================="
fi
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
if  [[ "${functionality[*]}" =~ "Cloud Backup" ]]; then
    docker run --rm \
        --volume "$homeDir"/docker/rclone/config:/config/rclone \
        --volume "$homeDir":"$homeDir" \
        --volume "$backupDir":"$backupDir" \
        --user "$(id -u)":"$(id -g)" \
        rclone/rclone \
        copy --progress "$backupDir"/"$type"/"$today" homeServerBackup:"$type"/"$today" && \
        echo "==================================================" && \
        echo "$backupDir"/"$type"/"$today encrypted and copied to the Cloud" && \
        echo "=================================================="

fi
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
if  [[ "${functionality[*]}" =~ "Daily-backup cleaner" ]]; then
    if [ "$type" == "daily" ]; then
        find "$backupDir"/"$type"/ -type d -mtime +4 -exec rm -rf "{}" \; && \
        echo "==================================================" && \
        echo "Daily-backup cleaner performed" && \
        echo "=================================================="
    fi
fi
#
if  [[ "${functionality[*]}" =~ "Daily-backup cloud cleaner" ]]; then
    if [ "$type" == "daily" ]; then
        docker run --rm \
            --volume "$homeDir"/docker/rclone/config:/config/rclone \
            --volume "$homeDir":"$homeDir" \
            --volume "$backupDir":"$backupDir" \
            --user "$(id -u)":"$(id -g)" \
            rclone/rclone \
            delete homeServerBackup:/ --min-age 4d && \
            echo "==================================================" && \
            echo "Daily-backup cloud cleaner performed" && \
            echo "=================================================="
    fi
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
if  [[ "${functionality[*]}" =~ "Daily-backup archiver" ]]; then
    if [ "$type" == "daily" ]; then
        if [ "$todayDayOfMonth" -eq 1 ] || [ "$todayDayOfMonth" -eq 11 ] || [ "$todayDayOfMonth" -eq 21 ]; then
            rsync -r "$backupDir"/"$type"/"$today" "$backupDir"/archive/ && \
            echo "==================================================" && \
            echo "Daily-backup archiver performed" && \
            echo "=================================================="
        fi
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
#   Re-enable Netdata alarms
if [ "$NetdataSilencer" == true ]; then
    echo "==================================================" && \
    sudo docker exec -it netdata curl "http://localhost:19999/api/v1/manage/health?cmd=RESET" -H "X-Auth-Token: $NetdataAuthToken" && \
    echo "Netdata health check reseted" && \
    echo "=================================================="
fi
#
#   Convert functionalities array to string with newlines after each functionality
declare functionalitySummary=$(printf "= %s\n" "${functionality[@]}")
#
#   Script end time 
declare endTime="$(date '+%F_%H-%M-%S')"
#
#   Total script duration
declare totalDuration="$(($SECONDS/60)) min $(($SECONDS%60)) sec" 
#
#   Declare summary message
summary="==================================================
Following tasks completed:
$functionalitySummary
Start:              $today
End:                $endTime
Total duration:     $totalDuration
=================================================="
#
echo -e "$summary"
#
#   Gotify Summary Notification
curl "$GotifyHost" -F "title=$GotifyTitle" -F "message=$summary" -F "priority=1"
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



