#!/usr/bin/env bash

source ./fluxr.conf
stage_2() {
    echo "+++ START STAGE 2"

    if [[ ! -d $PROPAGATION_1 ]]; then
        echo -e "!!! \tPropagation 1 directory is not accesible"
        exit 1
    fi

    if [[ $(hostname) != "$BACKUP_DIR_HOST" && $(hostname) != "$PROPAGATION_1_HOST" ]]; then
        echo -e "!!! \tCan't propagate within two remote directories"
        exit 1
    elif [[ $(hostname) == "$BACKUP_DIR_HOST" ]]; then
        echo -e "??? \tBackup directory is local"
        echo -e "??? \tPropagation directory is remote"
        sudo rsync $RSYNC_OPTS $BACKUP_DIR/ $PROPAGATION_1_HOST$PROPAGATION_1/
    else
        echo -e "??? \tBackup directory is remote"
        echo -e "??? \tPropagation directory is local"
        sudo rsync $RSYNC_OPTS $BACKUP_DIR_HOST$BACKUP_DIR/ $PROPAGATION_1/
    fi
    echo "<><><> FLUX COMPLETED"
    exit 0
}

stage_2
