#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR

cd "$(dirname "$0")" || exit

source fluxr.conf

LOCAL_HOSTNAME=$(hostname)

services_backup() {
    for services in "${SERVICES[@]}"; do
        echo -e "\tBacking up $services -->"
        ./"$services".sh
    done
    unset SERVICES
}

core_backup() {
    if [[ "$LOCAL_HOSTNAME" == "$BACKUP_DIR_HOST" ]]; then
        echo -e "\tBacking up $ROOT --> $BACKUP_DIR/$hostname/"
        echo "---"
        sudo rsync $RSYNC_OPTS --files-from=./"$hostname".include "$ROOT"/ "$BACKUP_DIR"/"$hostname"/
    else
        echo -e "\tBacking up $ROOT --> $BACKUP_DIR_HOST$BACKUP_DIR/$hostname/"
        echo "---"
        sudo rsync $RSYNC_OPTS --files-from=./"$hostname".include "$ROOT"/ "$BACKUP_DIR_HOST""$BACKUP_DIR"/"$hostname"/
    fi
}

stage_1() {
    echo "+++ START STAGE 1"
    for hostname in "${HOSTNAMES[@]}"; do
        source "$hostname".conf

        echo Host: "$hostname" "-->"

        if [[ "$LOCAL_HOSTNAME" != "$hostname" ]]; then
            echo -e "??? \tHost is remote"
            if [[ -n "$SSH_TTY" ]]; then
                echo -e "??? \tCan't backup ssh client"
                continue
            else
                echo "---"

                # To make this work I have to create arguments for the script,
                # e.g., "./fluxr.sh $hostname", this will skip the for loop
                # and only run for the current host when the script starts remotely
                #
                # ssh root@"$hostname" /storage/fluxr-test/fluxr.sh

                continue
            fi
        fi

        if [[ -n "$SERVICES" ]]; then
            echo -e "\tThere are services to backup >>>"
            services_backup
        else
            echo -e "??? \tThere are no services to backup"
        fi
        core_backup
    done
}

stage_1
./propagation.sh
