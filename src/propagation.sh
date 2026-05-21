#!/usr/bin/env bash
stage_2() {
    echo "+++ START STAGE 2"

    if [[ ! -d $PROPAGATION_1 ]]; then
        echo -e "!!! \tPropagation 1 directory is not accesible"
        echo -e "--- ---\t---"
        exit 1
    fi

    if [[ $(hostname): != "$BACKUP_DIR_HOST" && $(hostname): != "$PROPAGATION_1_HOST" ]]; then
        echo -e "!!! \tCan't propagate within two remote directories"
        echo -e "--- ---\t---"
        exit 1
    elif [[ $(hostname) == "$BACKUP_DIR_HOST" ]]; then
        echo -e "??? \tBackup directory is local"
        echo -e "??? \tPropagation directory is remote"
        sudo rsync $RSYNC_OPTS $BACKUP_DIR/ $PROPAGATION_1_HOST$PROPAGATION_1/
        echo -e "--- ---\t---"
    else
        echo -e "??? \tBackup directory is remote"
        echo -e "??? \tPropagation directory is local"
        echo -e "\tPropagating $BACKUP_DIR_HOST$BACKUP_DIR/ --> $PROPAGATION_1/"
        sudo rsync $RSYNC_OPTS $BACKUP_DIR_HOST$BACKUP_DIR/ $PROPAGATION_1/
        echo -e "--- ---\t---"
    fi
    echo "<><><> FLUX COMPLETED"
    exit 0
}