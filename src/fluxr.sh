#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR

cd "$(dirname "$0")" || exit

RSYNC_OPTS="--info=progress2,stats1 --archive --recursive --acls --xattrs --hard-links --human-readable --compress --delete"
LOCAL_HOSTNAME=$(hostname)
CONFIG_DIR="$HOME"/.config/fluxr

# Parse hosts to backup based on config file names, files starting with underscore are ignored
HOSTNAMES="$(find $CONFIG_DIR -name "*.sh" | sed "s|${CONFIG_DIR}/||;s|.sh||" | sed "/_/d" | sed "N;s|\n| |")"

source ./integrations/postgres.sh

services_backup() {
    if [[ -n "$SERVICES" ]]; then
        for service in "${SERVICES[@]}"; do
            echo -e "\tBacking up $service -->"
            # ./integrations/"$services"
            "$service"_bkp
        done
        echo -e "--- ---\t---"
        unset SERVICES
    else
        echo -e "??? \tNo services to backup"
        echo -e "--- ---\t---"
    fi
}

config_setup() {
    source $CONFIG_DIR/"$hostname".sh
    # Parse host and directory targets from config
    backup_dir_mline=$(echo "$TARGET" | sed 's/:/\n/' -)
    BACKUP_HOST=$(echo "$backup_dir_mline" | sed -n '1p' -)
    BACKUP_DIR=$(echo "$backup_dir_mline" | sed -n '2p' -)
    export BACKUP_DIR
    # echo $BACKUP_DIR

    # Redirect directories to backup from $ROOT to file
    mkdir --parents "$HOME"/.local/share/fluxr
    echo "$INCLUDE" >"$HOME"/.local/share/fluxr/"$hostname".include
}
core_backup() {
    if [[ "$LOCAL_HOSTNAME" == "$BACKUP_HOST" ]]; then
        echo -e "\tBacking up $ROOT --> $BACKUP_DIR"
        rsync $RSYNC_OPTS --files-from="$HOME"/.local/share/fluxr/"$hostname".include "$ROOT"/ "$BACKUP_DIR"/
        echo -e "\t---"
    else
        echo -e "\tBacking up $ROOT --> $BACKUP_HOST:$BACKUP_DIR"
        rsync $RSYNC_OPTS --files-from="$HOME"/.local/share/fluxr/"$hostname".include "$ROOT"/ "$BACKUP_HOST":"$BACKUP_DIR"/
        echo -e "\t---"
    fi
}

stage_1() {

    # When fluxr is called over ssh this if statement will execute, close connection and continue the for loop
    if [[ -n $1 ]]; then
        hostname=$1

        echo -e "\tSsh as $USER@$hostname >>>"

        config_setup

        core_backup

        services_backup

        exit 0
    fi

    echo "+++ START STAGE 1"

    for hostname in ${HOSTNAMES}; do
        echo Host: "$hostname" "-->"

        # Execute command over ssh when host is remote
        if [[ "$LOCAL_HOSTNAME" != "$hostname" ]]; then
            if [[ -n "$SSH_TTY" ]]; then
                echo -e "!!! \tCan't backup ssh client"
                continue
            else
                ssh root@"$hostname" nix run gitlab:niridium/fluxr-backup/feat/configuration -- "$hostname"
                continue
            fi
        fi

        config_setup

        core_backup

        services_backup
    done
}

stage_1 "$1"
