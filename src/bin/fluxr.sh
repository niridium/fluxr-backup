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
check-ssh() {
    if [[ "$LOCAL_HOSTNAME" != "$hostname" ]]; then
        if [[ -n "$SSH_TTY" ]]; then
            echo -e "!!! \tCan't backup ssh client"
            return 1
        else
            sudo rsync -v "$HOME"/.config/fluxr/"$hostname".sh "$hostname":/root/.config/fluxr/"$hostname".sh --quiet
            if (which fluxr >/dev/null); then
                echo -e "Ssh as root@$hostname >>>"
                ssh root@"$hostname" fluxr host-sync "$hostname"
            else
                echo "fluxr not found at host ${hostname}"
            fi
            return 10
        fi
    fi
}
host-sync() {
    LOCAL_HOSTNAME=$(hostname)
    # Parse hosts to backup based on config file names, files starting with underscore are ignored
    HOSTNAMES="$(find "$CONFIG_DIR" -maxdepth 1 -name "*.sh" | sed "s|${CONFIG_DIR}/||;s|.sh||" | sed "/_/d" | sed "N;s|\n| |")"

    for hostname in ${HOSTNAMES}; do
        case $2 in
        -a | "$hostname")
            check-ssh "$@"
            # If ssh sync returns 10 or 1, it exited successfully or with error,
            # on both cases local sync is not needed.
            if [[ $? != 10 && $? != 1 ]]; then
                echo Host: "$hostname" "-->"
                config-setup
                sync "$@"
            fi
            # Loop must continue to sync all hosts
            if [[ $2 != -a ]]; then
                break
            fi
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
    ./* | /*)
        echo -e "\tBacking up $2 --> $3"
        rclone sync --progress --links "$2" "$3"
        exit
        ;;
    *)
        echo "Invalid arguments"
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
    cat ../docs/help.txt
}
case $1 in
host-sync)
    host-sync "$@"
    ;;
remote-sync)
    remote-sync "$@"
    ;;
help | *)
    help
    ;;
esac
