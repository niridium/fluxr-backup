#!/usr/bin/env bash

CONFIG_DIR=/home/nixy/.config/fluxr
source $CONFIG_DIR/fluxr.conf

# Database dump
sudo -u postgres pg_dumpall | gzip >"$BACKUP_DIR"/"$(hostname)"/database.sql.gz
