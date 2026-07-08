#!/bin/sh

dataset=$1

if [ -z "$dataset" ]; then
    printf "%s\n" "Missing positional argument: dataset"
    exit 1
fi

zfs destroy -r "$dataset@7daysago"
zfs rename -r "$dataset@6daysago" "@7daysago"
zfs rename -r "$dataset@5daysago" "@6daysago"
zfs rename -r "$dataset@4daysago" "@5daysago"
zfs rename -r "$dataset@3daysago" "@4daysago"
zfs rename -r "$dataset@2daysago" "@3daysago"
zfs rename -r "$dataset@yesterday" "@2daysago"
zfs rename -r "$dataset@today" "@yesterday"
zfs snapshot -r "$dataset@today"

