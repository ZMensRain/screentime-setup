#! /bin/bash

# A script for setting up screentime on linux using pam_time, cronjobs, and loginctl

#Must be run as root
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
  echo "Requires root privileges" >&2
  exit 1
fi

# # Must be run with 6 arguments
if [[ $# -ne 5 ]]; then
    echo "Illegal number of parameters expected 5 arguments\n <username> <start hour> <start minute> <end hour> <end minute>" >&2
    exit 2
fi

# Variables
username=$1
startHour=$2
startMinute=$3
endHour=$4
endMinute=$5


# Add pam_time to the login config
pamConfig="account required pam_time.so"

if [[ $(grep -o "$pamConfig" /etc/pam.d/login | wc -l) == 0 ]]; then
    echo "$pamConfig" >>/etc/pam.d/login
fi

# Configure pam_time
timeConfig="*;*;$username;Al$(printf "%02d%02d-%02d%02d" $startHour $startMinute $endHour $endMinute)"

if [[ $(grep -o "$timeConfig" /etc/security/time.conf | wc -l ) == 0 ]]; then
    echo "$timeConfig" >>/etc/security/time.conf
else
    echo "Time already listed for this user"
fi

# Setup cronjob
crontab -l > current_cron
cronJob="$endMinute $endHour * * * loginctl terminate-user $username"

if [[ $(grep -o "$cronJob" current_cron | wc -l) == 0 ]]; then
    echo "$cronJob" >> current_cron
    crontab < current_cron
fi
rm -f current_cron