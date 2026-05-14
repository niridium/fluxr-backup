#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
cd "$(dirname "$0")" || exit

source fluxr.conf

# Directories shown in the logs are relative to the host

core_backup() {
    echo Host: "$hostname" "-->"

    if [[ -z "$REMOTE_HOST" ]]; then

        echo -e "\tBacking up $ROOT --> $BACKUP_DIR/$hostname/"
        echo ">>>"

        if $IS_REMOTE; then
            rsync $RSYNC_OPTS "$hostname".include "$hostname":"$ROOT"
            ssh -T "$hostname" <<EOF
                cd $ROOT
                rsync $RSYNC_OPTS --files-from=./"$hostname".include "$ROOT"/ "$BACKUP_DIR"/"$hostname"/
EOF
            unset IS_REMOTE
        else
            rsync $RSYNC_OPTS --files-from=./"$hostname".include "$ROOT"/ "$BACKUP_DIR"/"$hostname"/
        fi
    else
        echo -e "\tBacking up $ROOT --> $REMOTE_HOST:$BACKUP_DIR/$hostname/"
        echo ">>>"
        rsync $RSYNC_OPTS --files-from=./"$hostname".include "$ROOT"/ "$REMOTE_HOST":"$BACKUP_DIR"/"$hostname"/
        unset REMOTE_HOST
    fi
}

stage_1() {
    echo "+++ START STAGE 1"
    for hostname in "${HOSTNAMES[@]}"; do
        source "$hostname".conf

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
        rsync $RSYNC_OPTS $BACKUP_DIR/ $PROPAGATION_1_HOST:$PROPAGATION_1/
    else
        echo -e "??? \tBackup directory is remote"
        echo -e "??? \tPropagation directory is local"
        rsync $RSYNC_OPTS $BACKUP_DIR_HOST:$BACKUP_DIR/ $PROPAGATION_1/
    fi
    echo "<><><> FLUX COMPLETED"
    exit 0
}
stage_1
stage_2
