#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR

cd "$(dirname "$0")" || exit

source fluxr.conf

export ROOT BACKUP_DIR

# Directories shown in the logs are relative to the host



services_backup() {
    for services in "${SERVICES[@]}"; do
        echo Backing up "$services -->"
        ./services/"$services".sh
    done
    unset SERVICES
}

core_backup() {

    if [[ $(hostname) == "$HOSTNAME" ]]; then
        if [[ -z "$REMOTE_HOST" ]]; then

            echo -e "\tBacking up $ROOT --> $BACKUP_DIR/$hostname/"
            echo "---"
            sudo rsync $RSYNC_OPTS --files-from=./"$hostname".include "$ROOT"/ "$BACKUP_DIR"/"$hostname"/
        else

            echo -e "\tBacking up $ROOT --> $REMOTE_HOST:$BACKUP_DIR/$hostname/"
            echo "---"
            sudo rsync $RSYNC_OPTS --files-from=./"$hostname".include "$ROOT"/ "$REMOTE_HOST":"$BACKUP_DIR"/"$hostname"/
            unset REMOTE_HOST
        fi
    fi
}

stage_1() {
    echo "+++ START STAGE 1"
    for hostname in "${HOSTNAMES[@]}"; do
        source "$hostname".conf
        export hostname

        echo Host: "$hostname" "-->"

        if $IS_REMOTE; then
            echo -e "??? \tHost is remote"
            # exit 2
        fi

        if [[ -v "${SERVICES}" ]] then
            echo -e "\tThere are services to backup >>>"
            services_backup
        else
            echo -e "??? \tThere are no services to backup"
        fi
        core_backup
    done
}

stage_2() {
    echo "+++ START STAGE 2"

    if [[ $(hostname) != "$BACKUP_DIR_HOST" && $(hostname) != "$PROPAGATION_1_HOST" ]]; then
        echo -e "!!! \tCan't propagate within two remote directories"
        exit 1
    elif [[ $(hostname) == "$BACKUP_DIR_HOST" ]]; then
        echo -e "??? \tBackup directory is local"
        echo -e "??? \tPropagation directory is remote"
        sudo rsync $RSYNC_OPTS $BACKUP_DIR/ $PROPAGATION_1_HOST:$PROPAGATION_1/
    else
        echo -e "??? \tBackup directory is remote"
        echo -e "??? \tPropagation directory is local"
        sudo rsync $RSYNC_OPTS $BACKUP_DIR_HOST:$BACKUP_DIR/ $PROPAGATION_1/
    fi
    echo "<><><> FLUX COMPLETED"
    exit 0
}
stage_1
stage_2
