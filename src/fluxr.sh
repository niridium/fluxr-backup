#!/usr/bin/env bash

cd "$(dirname "$0")" || exit

CONFIG_DIR="$HOME"/.config/fluxr

config-setup() {
    mkdir --parents "$HOME"/.local/share/fluxr

    INCLUDE_FILE="$HOME"/.local/share/fluxr/"$hostname".include
    export INCLUDE_FILE

    # shellcheck source=/dev/null
    source "$CONFIG_DIR"/"$hostname".sh

    # ROOT and TARGET are only required when no custom COMMAND overrides the sync
    if [[ -z "$COMMAND" && (-z "$ROOT" || -z "$TARGET") ]]; then
        echo "!!! Error: config for host $hostname is missing ROOT and/or TARGET"
        exit 1
    fi

    echo "$INCLUDE" >"$HOME"/.local/share/fluxr/"$hostname".include

    echo "$COMMAND" >"$HOME"/.local/share/fluxr/"$hostname"-command.sh
    chmod +x "$HOME"/.local/share/fluxr/"$hostname"-command.sh
}
sync() {
    echo -e "\tBacking up $ROOT --> $TARGET"
    if [[ -n "$COMMAND" ]]; then
        "$HOME"/.local/share/fluxr/"$hostname"-command.sh
        echo -e "\t---"
    else
        case $3 in
        */*)
            TARGET=$3
            ;;
        esac
        rclone sync --progress --links --include-from "$INCLUDE_FILE" "$ROOT" "$TARGET"
        echo -e "\t---"
    fi
}
ssh-sync() {

    echo -e "\tSsh as $USER@$2 >>>"
    config-setup
    sync

    exit 0
}
host-sync() {
    LOCAL_HOSTNAME=$(hostname)
    # Parse hosts and remotes to backup based on config file names, files starting with underscore are ignored
    HOSTNAMES="$(find "$CONFIG_DIR" -maxdepth 1 -name "*.sh" | sed "s|${CONFIG_DIR}/||;s|.sh||" | sed "/_/d" | sed "N;s|\n| |")"

    # Fail fast if there are no host config files to process
    # if [[ -z "$HOSTNAMES" ]]; then
    #     echo "!!! Error: no config files found in $CONFIG_DIR"
    #     exit 1
    # fi

    echo "+++ START STAGE 1"

    for hostname in ${HOSTNAMES}; do
        # Execute command over ssh when host is remote
        if [[ "$LOCAL_HOSTNAME" != "$hostname" ]]; then
            if [[ -n "$SSH_TTY" ]]; then
                echo -e "!!! \tCan't backup ssh client"
                continue
            else
                sudo rsync "$HOME"/.config/fluxr/"$hostname".sh "$hostname":/root/.config/fluxr/"$hostname".sh --quiet
                if (which fluxr >/dev/null); then
                    ssh root@"$hostname" fluxr ssh-sync "$hostname"
                else
                    echo "fluxr not found at host ${hostname}"
                fi
                continue
            fi
        fi
        case $2 in
        "$hostname")
            echo Host: "$hostname" "-->"
            config-setup
            sync "$@"
            break
            ;;
        -a)
            echo Host: "$hostname" "-->"
            config-setup
            sync "$@"
            ;;
        *)
            continue
            ;;
        esac
    done
}
remote-sync() {
    REMOTES="$(find "$CONFIG_DIR"/remotes -name "*.sh" | sed "s|${CONFIG_DIR}/remotes/||;s|.sh||" | sed "/_/d" | sed "N;s|\n| |")"
    case $3 in
    *[a-z]*)
        rclone sync --progress --links "$2" "$3"
        exit
        ;;
    esac
    for remote in ${REMOTES}; do
        # shellcheck source=/dev/null
        source "$CONFIG_DIR"/remotes/"$remote".sh
        for _target in "${SYNC[@]}"; do
            echo "Transfering $remote: to $_target -->"
            rclone sync --progress --links --checkers 16 --transfers 8 --stats 1s --stats-file-name-length 80 --fast-list "$remote": "$_target"
        done
    done
}
help() {
    echo "Help"
}
case $1 in
host-sync)
    host-sync "$@"
    ;;
ssh-sync)
    ssh-sync "$@"
    ;;
remote-sync)
    remote-sync "$@"
    ;;
*)
    help
    ;;
esac
