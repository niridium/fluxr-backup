#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

CONFIG_DIR="$HOME"/.config/fluxr

config_setup() {
    mkdir --parents "$HOME"/.local/share/fluxr

    INCLUDE_FILE="$HOME"/.local/share/fluxr/"$hostname".include
    export INCLUDE_FILE

    source "$CONFIG_DIR"/"$hostname".sh

    # WIP: Some target syntax checks
    # if echo "$TARGET" | grep -q ':'; then
    #     echo This is remote
    # elif [[ $TARGET == \/* || $TARGET == ~\/* ]]; then
    #     echo Target is available
    # else
    #     echo Target is not available
    #     exit 1
    # fi

    echo "$INCLUDE" >"$HOME"/.local/share/fluxr/"$hostname".include

    echo "$COMMAND" >"$HOME"/.local/share/fluxr/"$hostname"-command.sh
    chmod +x "$HOME"/.local/share/fluxr/"$hostname"-command.sh
}
core_backup() {
    echo -e "\tBacking up $ROOT --> $TARGET"
    if [[ -n "$COMMAND" ]]; then
        "$HOME"/.local/share/fluxr/"$hostname"-command.sh
        echo -e "\t---"
    else
        rclone sync --progress --links --include-from "$INCLUDE_FILE" "$ROOT" "$TARGET"
        echo -e "\t---"
    fi
}
remote_backup() {
    # When fluxr is called over ssh this if statement will execute, close connection and continue the for loop
    if [[ -n $1 ]]; then
        hostname=$1

        echo -e "\tSsh as $USER@$hostname >>>"
        config_setup
        core_backup

        exit 0
    fi
}
stage_1() {
    remote_backup "$1" # Exit script when finish execution

    LOCAL_HOSTNAME=$(hostname)
    # Parse hosts and remotes to backup based on config file names, files starting with underscore are ignored
    HOSTNAMES="$(find "$CONFIG_DIR" -maxdepth 1 -name "*.sh" | sed "s|${CONFIG_DIR}/||;s|.sh||" | sed "/_/d" | sed "N;s|\n| |")"

    echo "+++ START STAGE 1"

    for hostname in ${HOSTNAMES}; do
        echo Host: "$hostname" "-->"
        # Execute command over ssh when host is remote
        if [[ "$LOCAL_HOSTNAME" != "$hostname" ]]; then
            if [[ -n "$SSH_TTY" ]]; then
                echo -e "!!! \tCan't backup ssh client"
                continue
            else
                sudo rsync "$HOME"/.config/fluxr/"$hostname".sh "$hostname":/root/.config/fluxr/"$hostname".sh --quiet
                ssh root@"$hostname" nix run gitlab:niridium/fluxr-backup/rclone -- "$hostname"
                continue
            fi
        fi

        config_setup
        core_backup
    done
}
rclone_sync() {
    REMOTES="$(find "$CONFIG_DIR"/remotes -name "*.sh" | sed "s|${CONFIG_DIR}/remotes/||;s|.sh||" | sed "/_/d" | sed "N;s|\n| |")"
    for remote in ${REMOTES}; do
        source "$CONFIG_DIR"/remotes/"$remote".sh
        for _target in "${SYNC[@]}"; do
            echo "Transfering $remote: to $_target -->"
            rclone sync --progress --links --checkers 16 --transfers 8 --stats 1s --stats-file-name-length 80 --fast-list "$remote": "$_target"
        done
    done
}
stage_1 "$1"
rclone_sync
