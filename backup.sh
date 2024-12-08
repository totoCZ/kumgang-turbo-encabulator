#!/bin/bash

export RESTIC_REPOSITORY='/mnt/restic/router'
export RESTIC_PASSWORD=''
export RESTIC_CACHE_DIR=/var/cache/restic/

restic unlock
restic backup / -x --exclude-caches --verbose
restic forget --prune --keep-weekly 4 --keep-monthly 3
