#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR

cd "$(dirname "$0")" || exit

CONFIG_DIR=/home/nixy/.config/fluxr
source $CONFIG_DIR/fluxr.conf
source modules/propagation

LOCAL_HOSTNAME=$(hostname)

install() {
    if [[ ! -f $CONFIG_DIR/fluxr.conf ]]; then
        echo "Installing config files >>>"
        mkdir -v "$CONFIG_DIR"

        cp -v ./fluxr.conf.example "$CONFIG_DIR"/fluxr.conf
        echo -e "--- ---\t---"
    fi
    # I have to sync the config with the other hosts when it changes
    # Over ssh directory is created as root owner, I have to change the owner
    # Need to also copy hosts config between hosts
}

services_backup() {
    for services in "${SERVICES[@]}"; do
        echo -e "\tBacking up $services -->"
        ./integrations/"$services"
    done
    echo -e "--- ---\t---"
    unset SERVICES
}

core_backup() {
    if [[ "${LOCAL_HOSTNAME}:" == "$BACKUP_DIR_HOST" ]]; then
        echo -e "\tBacking up $ROOT --> $BACKUP_DIR/$hostname/"
        rsync $RSYNC_OPTS --files-from=$CONFIG_DIR/hosts/"$hostname".include "$ROOT"/ "$BACKUP_DIR"/"$hostname"/
        echo -e "\t---"
    else
        echo -e "\tBacking up $ROOT --> $BACKUP_DIR_HOST$BACKUP_DIR/$hostname/"
        rsync $RSYNC_OPTS --files-from=$CONFIG_DIR/hosts/"$hostname".include "$ROOT"/ "$BACKUP_DIR_HOST""$BACKUP_DIR"/"$hostname"/
        echo -e "\t---"
    fi
}

stage_1() {

    if [[ -n $1 ]]; then
        hostname=$1
        source $CONFIG_DIR/hosts/"$hostname".conf
        echo -e "\tSsh as $USER@$hostname >>>"
        core_backup
        if [[ -n "$SERVICES" ]]; then
            services_backup
        else
            echo -e "??? \tNo services to backup"
            echo -e "--- ---\t---"
        fi
        exit 0
    fi

    echo "+++ START STAGE 1"

    for hostname in "${HOSTNAMES[@]}"; do
        source $CONFIG_DIR/hosts/"$hostname".conf

        echo Host: "$hostname" "-->"

        if [[ "$LOCAL_HOSTNAME" != "$hostname" ]]; then
            # echo -e "??? \tHost is remote"
            if [[ -n "$SSH_TTY" ]]; then
                echo -e "!!! \tCan't backup ssh client"
                continue
            else
                ssh root@"$hostname" /home/nixy/fluxr-backup/src/fluxr.sh "$hostname"
                continue
            fi
        fi

        core_backup

        if [[ -n "$SERVICES" ]]; then
            services_backup
        else
            echo -e "??? \tNo services to backup"
            echo -e "--- ---\t---"
        fi
    done
}
install

stage_1 "$1"
stage_2

### Right now config is independent from the package and is my job to sync it
# Built package works, so now I have to wrap the full script as a command and push the package to github
# Then everytime I change something and push I only have to rebuild in any remote host
# Next I will find the way to automate config so it syncs between hosts in a single directory without hard coded paths
