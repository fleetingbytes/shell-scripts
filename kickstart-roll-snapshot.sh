#!/bin/sh

dataset=$1

if [ -z "$dataset" ]; then
    printf "%s\n" "Missing positional argument: dataset"
    exit 1
fi

zfs snapshot -r "$dataset@7daysago"
zfs snapshot -r "$dataset@6daysago"
zfs snapshot -r "$dataset@5daysago"
zfs snapshot -r "$dataset@4daysago"
zfs snapshot -r "$dataset@3daysago"
zfs snapshot -r "$dataset@2daysago"
zfs snapshot -r "$dataset@yesterday"
zfs snapshot -r "$dataset@today"

