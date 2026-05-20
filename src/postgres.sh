#!/usr/bin/env bash

source ./fluxr.conf

# Database dump
sudo -u postgres pg_dumpall | gzip >"$BACKUP_DIR"/"$(hostname)"/database.sql.gz
