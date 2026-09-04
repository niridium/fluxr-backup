# Installation

## Nix

Add to your flake inputs and system packages:  
`flake.nix`

```nix
{
  inputs = {
    fluxr.url = "github:niridium/fluxr-backup";
  }
}
```

`configuration.nix`

```nix
{
  environment.systemPackages = [
    inputs.fluxr.packages.${stdenv.hostPlatform.system}.default
  ]
}
```

# Usage

Just run the command:

```bash
fluxr
```

Or with nix if you don't want to install:

```bash
nix run github:niridium/fluxr-backup
```

# Configuration

Configuration is done with `.sh` files at `$HOME/.config/fluxr`.

Each file configures one host and must share the hostname.  
If the hostname is `laptop-1` the file must be named `laptop-1.sh`.

#### Example:

`cronos.sh`

```bash
ROOT=/storage

TARGET=/storage/box/Backups/cronos

INCLUDE="
immich/
navidrome/
"

# This custom command will sync the immich/ and navidrome/ directory at /storage to a webdav directory at /storage/box/Backups/cronos
COMMAND="
rsync --info=progress2,stats1 --human-readable --itemize-changes -a --recursive --no-p --delete --super --chown=webdav --chmod=744 --files-from=$INCLUDE_FILE $ROOT $TARGET
"
```

## Configurable variables:

- `ROOT`: Path to the directory to backup.
- `TARGET`: A local absolute path or rclone remote directory.
- `INCLUDE`: String with rclone pattern rules to be used by `--include-from`, one pattern per line. Check [Rclone filtering](https://rclone.org/filtering).

> By default fluxr will use [`rclone sync`](https://rclone.org/commands/rclone_sync) with the [`--links`](https://rclone.org/docs/#l-links) flag, you can replace that with the `COMMAND` variable.

- `COMMAND`(Optional): String containing a shell command, you can declare multiple commands, one per line. It will override the default `rclone sync` command.  
  When `COMMAND` is not empty, the rules for the mandatory variables above don't matter so you can use them as you please.

## Exposed variables:

You can use these variables in your custom commands.

- `INCLUDE_FILE`: Stores the path to a file with the `INCLUDE` variable contents.

## Per remote configuration:

You can also do per remote configuration at `$HOME/.config/fluxr/remotes`.  
One file for each remote, following the same naming convention as per host files.

- `SYNC`: List containing rclone remotes or local absolute paths that you want the configured remote to sync with.

#### Example:

`cronos-box.sh`

```bash
SYNC=(storage-box-1-crypted: /home/callisto/nvme01)
```
