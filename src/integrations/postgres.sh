#!/usr/bin/env bash

# Database dump
postgres_bkp() {
    sudo -u postgres pg_dumpall | gzip >"$BACKUP_DIR"/database.sql.gz
}
