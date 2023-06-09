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
#   03.     Backups cleaner                                                 #
#   04.     Local Backup                                                    #
#   04.01.      Docker Volumes                                              #
#   04.02.      Docker Bind Mounts                                          #
#   04.02.      Home directory                                              #
#   05.     Cloud Backup                                                    #
#   06.     Daily-backup cleaner                                            #
#   07.     Daily-backup archiver                                           #
#   08.     Script summary                                                  #
#                                                                           #
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 01.       How to use it                                           #
#                                                                           #
#===========================================================================#
#
#   Everything in the README.md (link below)
#   https://github.com/gromoslaw-kroczka/home-server-backup#how-to-use-it
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
declare today="$(date '+%F_%H-%M-%S')"
#
#   Start time in format DD
declare todayDayOfMonth="$(date '+%d')"
#
#endregion
#
#===========================================================================#
#
#region | 02.02.    'sudo' checker & 'type' parameter declaration & checker
#
#   Check if run as root / sudo
if [ "$EUID" -ne 0 ]
  then echo "Please run as root / sudo"
  exit
fi
#
#   Require -t TYPE for script execution
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
#   List of available TYPES
declare -a typeChecker=(
    'instant'
    'daily'
    'cleaner'
)
#
#   Check if TYPE is one of availables TYPES
if  [[ ! "${typeChecker[*]}" =~ "${type}" ]]; then
    echo "usage: $0 [-t] <TYPE (instant/daily)>
            <instant> used for executing script from terminal
            <daily> used in 'sudo crontab' for scheduled backups
            <cleaner> used to delete old backups" >&2
            exit 1
fi
#
#endregion
#
#===========================================================================#
#
#region | 02.03.    Logs settings
#
echo "Logs available in logs/log_""$type""_""$today"".out"
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>logs/log_"$type"_"$today".out 2>&1
#   Everything below will go to the log gile file in logs directory
echo "========================="
echo "homeServerBackup script launched $today"
echo "========================="
#
#endregion
#
#===========================================================================#
#
#region | 02.04.    Import parameters
#
source parameters.sh
#
#   Declare 'funcionality' array and assaign to it valuse
#   from (...)Daily or (...)Instant array from 'parameters.sh'
#   depend on the type of script execution
#
declare -a functionality
#
if [ "$type" == "daily" ]; then
    functionality=("${functionalityDaily[@]}")
else 
    functionality=("${functionalityInstant[@]}")
fi
#
#endregion
#
#===========================================================================#
#
#region | 02.05.    Netdata silencer
#
# Disable disk.backlog notifications during backup
if [ "$NetdataSilencer" == true ]; then
    echo "=========================" && \
    docker exec netdata curl -s "http://localhost:19999/api/v1/manage/health?cmd=SILENCE&context=disk.backlog" -H "X-Auth-Token: $NetdataAuthToken" && \
    echo "Netdata health notifications disabled" && \
    echo "========================="
fi
#
#endregion
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 03        Backups cleaner                                         #
#                                                                           #
#===========================================================================#
#
#   Execute these commands only for <cleaner> option:
#       Delete all of non-daily & non-archive local backups
#       Delete all of non-daily cloud backups
#
if [ "$type" == "cleaner" ]; then
    #   Local backups cleaner
    cd "$backupDir"/ || { echo "Cannot cd into $backupDir"; exit 1; }
    find . \( -path ./daily -prune -o -path ./archive -prune \) -o -type d -exec rm -rf "{}" \;
    echo "========================="
    echo "Old backups cleaner (local) performed"
    echo "========================="
fi
#
#   Cloud backups cleaner
if [ "$type" == "cleaner" ]; then
    docker run --rm \
        --volume "$homeDir"/docker/rclone/config:/config/rclone \
        --volume "$homeDir":"$homeDir" \
        --volume "$backupDir":"$backupDir" \
        --user "$(id -u)":"$(id -g)" \
        rclone/rclone \
        delete homeServerBackup:/ --exclude /daily/**
    docker run --rm \
        --volume "$homeDir"/docker/rclone/config:/config/rclone \
        --volume "$homeDir":"$homeDir" \
        --volume "$backupDir":"$backupDir" \
        --user "$(id -u)":"$(id -g)" \
        rclone/rclone \
        rmdirs homeServerBackup:/ --leave-root
    echo "========================="
    echo "Old backups cleaner (cloud) cleaner performed"
    echo "========================="
fi
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 04.01.    Local Backup | Docker Volumes                           #
#                                                                           #
#===========================================================================#
#
#   Loop trought volumeDockers Associative Array
#       Stop docker container (if selected so in parameters)
#       Create backup directory
#       Perform backup
#       Restart stopped docker container (if previosuly stopped)
#
if [ "$type" != "cleaner" ]; then
    if  [[ "${functionality[*]}" =~ "Local Backup | Docker Volumes" ]]; then
        declare -n volumeDocker
        for volumeDocker in ${!volumeDocker@}; do
            if [ "${volumeDocker[stop]}" == true ]; then
                docker stop "${volumeDocker[container]}"
            fi
            mkdir -pv "$backupDir"/"$type"/"$today"
            docker run --rm --volumes-from "${volumeDocker[container]}" \
            -v "$backupDir"/"$type"/"$today":/backup \
            ubuntu tar cvf /backup/"${volumeDocker[name]}".tar "${volumeDocker[volumePath]}"
            if [ "${volumeDocker[stop]}" == true ]; then
                docker start "${volumeDocker[container]}"
                echo "========================="
                echo "${volumeDocker[container]} Container stopped, ${volumeDocker[name]} Volume backuped, ${volumeDocker[container]} Container restarted"
                echo "========================="
            else
                echo "========================="
                echo "${volumeDocker[name]} Volume backuped"
                echo "========================="
            fi
        done
    fi
fi
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 04.02.    Local Backup | Docker Bind Mounts                       #
#                                                                           #
#===========================================================================#
#
#   Loop trought bindDocker array
#       Stop docker container (if selected so in parameters)
#       Create backup directory
#       Perform backup
#       Restart stopped docker container (if previously stopped)
#
if [ "$type" != "cleaner" ]; then
    if  [[ "${functionality[*]}" =~ "Local Backup | Docker Bind Mounts" ]]; then
        for container in "${bindDocker[@]}"
        do
            if  [[ "${bindDockerStop[*]}" =~ "$container" ]]; then
                docker stop "$container"
            fi
            mkdir -pv "$backupDir"/"$type"/"$today"
            tar cvf "$backupDir"/"$type"/"$today"/"$container".tar "$homeDir"/docker/"$container"
            if  [[ "${bindDockerStop[*]}" =~ "$container" ]]; then
                docker start "$container"
                echo "========================="
                echo "$container Container stopped, $container Bind Mount backuped, $container Container restarted"
                echo "========================="
            else
                echo "========================="
                echo "$container Bind Mount backuped"
                echo "========================="
            fi
        done
    fi
fi
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 04.03.    Local Backup | Home directory                           #
#                                                                           #
#===========================================================================#
#
#   Create backup directory
#   Perform backup
#
if [ "$type" != "cleaner" ]; then
    if  [[ "${functionality[*]}" =~ "Local Backup | Home directory" ]]; then
        mkdir -pv "$backupDir"/"$type"/"$today"
        tar --exclude="docker" "${excludeDir[@]/#/--exclude=}" -cvf "$backupDir"/"$type"/"$today"/"$homeName".tar "$homeDir"/
        echo "========================="
        echo "$homeDir backuped as $homeName"
        echo "========================="
    fi
fi
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 05.       Cloud Backup                                            #
#                                                                           #
#===========================================================================#
#
#   Copy backup to the Cloud (encrypted)
#
if [ "$type" != "cleaner" ]; then
    if  [[ "${functionality[*]}" =~ "Cloud Backup" ]]; then
        docker run --rm \
            --volume "$homeDir"/docker/rclone/config:/config/rclone \
            --volume "$homeDir":"$homeDir" \
            --volume "$backupDir":"$backupDir" \
            --user "$(id -u)":"$(id -g)" \
            rclone/rclone \
            copy --progress "$backupDir"/"$type"/"$today" homeServerBackup:"$type"/"$today"
            echo "========================="
            echo "$backupDir"/"$type"/"$today encrypted and copied to the Cloud"
            echo "========================="

    fi
fi
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 06.       Daily-backup cleaner                                    #
#                                                                           #
#===========================================================================#
#
#   Delete older directiories (backups)
#   (as specified in parameters.sh)
#
#   (!) It is advised to execute these commands only for <daily> backups
#   (see '00.Functionality and basic settings' in 'parameters.sh')
#
#   Local daily cleaner
if [ "$type" != "cleaner" ]; then
    if  [[ "${functionality[*]}" =~ "Daily-backup cleaner" ]]; then
            find "$backupDir"/daily/ -type d -mtime +"$((dailyLocal - 1))" -exec rm -rf "{}" \;
            echo "========================="
            echo "Daily-backup cleaner performed"
            echo "========================="
    fi
fi
#
#   Cloud daily cleaner
if [ "$type" != "cleaner" ]; then
    if  [[ "${functionality[*]}" =~ "Daily-backup cloud cleaner" ]]; then
        docker run --rm \
            --volume "$homeDir"/docker/rclone/config:/config/rclone \
            --volume "$homeDir":"$homeDir" \
            --volume "$backupDir":"$backupDir" \
            --user "$(id -u)":"$(id -g)" \
            rclone/rclone \
            delete homeServerBackup:/daily/ --min-age "$dailyCloud"d
        docker run --rm \
            --volume "$homeDir"/docker/rclone/config:/config/rclone \
            --volume "$homeDir":"$homeDir" \
            --volume "$backupDir":"$backupDir" \
            --user "$(id -u)":"$(id -g)" \
            rclone/rclone \
            rmdirs homeServerBackup:/ --leave-root
        echo "========================="
        echo "Daily-backup cloud cleaner performed"
        echo "========================="
    fi
fi
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 07.       Daily-backup archiver                                   #
#                                                                           #
#===========================================================================#
#
#   If it's 1st, 11th or 21st day of month:
#       Copy todays backup to archive
#   
#   (!) It is advised to execute these commands only for <daily> backups
#   (see '00.Functionality and basic settings' in 'parameters.sh')
#
#   Local daily archiver
if [ "$type" != "cleaner" ]; then
    if  [[ "${functionality[*]}" =~ "Daily-backup archiver" ]]; then
        if [ "$todayDayOfMonth" -eq 1 ] || [ "$todayDayOfMonth" -eq 11 ] || [ "$todayDayOfMonth" -eq 21 ]; then
            rsync -r "$backupDir"/daily/"$today" "$backupDir"/archive/
            echo "========================="
            echo "Daily-backup archiver performed"
            echo "========================="
        fi
    fi
fi
#
#endregion
#
#===========================================================================#
#===========================================================================#
#                                                                           #
#region | 08.       Script Summary                                          #
#                                                                           #
#===========================================================================#
#
#   Re-enable Netdata alarms
if [ "$NetdataSilencer" == true ]; then
    echo "========================="
    docker exec netdata curl -s "http://localhost:19999/api/v1/manage/health?cmd=RESET" -H "X-Auth-Token: $NetdataAuthToken"
    echo "Netdata health check reseted"
    echo "========================="
fi
#
#   Convert functionalities array to string with newlines after each functionality
declare functionalitySummary=$(printf "= %s\n" "${functionality[@]}")
#
#   Script end time 
declare endTime="$(date '+%F_%H-%M-%S')"
#
#   Total script duration
declare totalDuration="$((SECONDS/60)) min $((SECONDS%60)) sec" 
#
#   Declare summary message
declare summary="=========================
Following tasks completed:
$functionalitySummary
Start:              $today
End:                $endTime
Total duration:     $totalDuration
========================="
#
echo -e "$summary"
#
#   Gotify Summary Notification
echo "Gotify Notification: "
curl -s "$GotifyHost" -F "title=$GotifyTitle" -F "message=$summary" -F "priority=1"
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



