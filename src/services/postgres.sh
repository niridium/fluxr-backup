source ../fluxr.sh
# Database dump
# ssh -T root@"$hostname" <<EOF
#     cd $ROOT
    sudo -u postgres pg_dumpall | gzip > "$BACKUP_DIR"/"$hostname"/database.sql.gz
#     pwd
# EOF
