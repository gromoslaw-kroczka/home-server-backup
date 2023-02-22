# Home Server Backup Script
> Multi-purpose Backup script dedicated for Home Servers
\
---
\
[01. Features](https://github.com/gromoslaw-kroczka/home-server-backup#01-features)\
[02. Dependencies](https://github.com/gromoslaw-kroczka/home-server-backup#02-dependencies)\
[03. Content](https://github.com/gromoslaw-kroczka/home-server-backup#03-content)\
[04. How to use it](https://github.com/gromoslaw-kroczka/home-server-backup#04-how-to-use-it)\
[05. Developement checklists](https://github.com/gromoslaw-kroczka/home-server-backup#05-development-checklist)\
\
---
\
## 01. Features
* Multiple directory backup:
    * Docker Volumes
    * Docker Bind Mounts
    * Server Home Directory
* Cloud backup using `rclone`
* Delete old backup files
* Archive bakcup every 10 days
\
## 02. Dependencies
> WORK IN PROGRESS
\
## 03. Content
> WORK IN PROGRESS
\
## 03. How to use it
To execute it, use the following command:\
`$ sudo ./homeServerBackup.sh -t <TYPE (instant/daily)>`\
    'instant' => used for executing script from terminal\
    'daily' => used in 'sudo crontab' for scheduled backups\
\
## 04. Developement checklist
- [ ] Appropriate script description in README.md file [#1](https://github.com/gromoslaw-kroczka/home-server-backup/issues/1)
- [ ] Conditional messages - depend if script success or not [#2](https://github.com/gromoslaw-kroczka/home-server-backup/issues/2)
- [ ] Release version to download (in which file format?) [#3](https://github.com/gromoslaw-kroczka/home-server-backup/issues/3)