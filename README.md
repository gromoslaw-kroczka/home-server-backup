# Home Server Backup Script
> Multi-purpose Backup script dedicated for Home Servers


* [Features][1]
* [Dependencies][2]
* [Content][3]
* [How to use it][4]
* [Developement checklists][5]

[1]: https://github.com/gromoslaw-kroczka/home-server-backup#features
[2]: https://github.com/gromoslaw-kroczka/home-server-backup#dependencies
[3]: https://github.com/gromoslaw-kroczka/home-server-backup#content
[4]: https://github.com/gromoslaw-kroczka/home-server-backup#how-to-use-it
[5]: https://github.com/gromoslaw-kroczka/home-server-backup#development-checklist

## Features
* Separate `parameters.sh` file for sensitive data and settings
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

## Dependencies
> WORK IN PROGRESS

## Content
> WORK IN PROGRESS

## How to use it
To execute it, use the following command:\
`$ sudo ./homeServerBackup.sh -t <TYPE (instant/daily)>`\
    `instant` => used for executing script from terminal\
    `daily` => used in 'sudo crontab' for scheduled backups\

## Developement checklist
- [X] Functionality chooser
- [X] `dev` mode [#7](https://github.com/gromoslaw-kroczka/home-server-backup/issues/7)
- [X] Gotify Notifications [#6](https://github.com/gromoslaw-kroczka/home-server-backup/issues/6)
- [X] Netdata notification silencer
- [X] Choose to stop /or not containers during bind mounts backup
- [X] (?) Choose to stop /or not containers during volume backup
- [ ] Appropriate script description in README.md file [#1](https://github.com/gromoslaw-kroczka/home-server-backup/issues/1)
- [ ] Conditional messages - depend if script success or not [#2](https://github.com/gromoslaw-kroczka/home-server-backup/issues/2)
- [ ] Release version to download (in which file format?) [#3](https://github.com/gromoslaw-kroczka/home-server-backup/issues/3)