#!/usr/bin/env bash
#
# Sync db and assets from prod to local
#
# SSH-keys is mandatory
# Example usage `scripts/sync/stage_to_local.sh`

read -p "This will replace your LOCAL database - Are you sure? [y/n]" -n 1 -r
echo # nl
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

cd $(git rev-parse --show-toplevel)

source scripts/sync/STAGES

ssh $STAGE_USERNAME@$STAGE_HOSTNAME "cd $STAGE_SRC_PATH;
    wp --allow-root db export /tmp/latest.sql;"

scp $STAGE_USERNAME@$STAGE_HOSTNAME:/tmp/latest.sql docker/files/db-dumps/latest.sql

./scripts/wp.sh db import /app/db-dumps/latest.sql
./scripts/wp.sh search-replace $STAGE_HOSTNAME $LOCAL_HOSTNAME
./scripts/wp.sh option set ep_host http://search:9200
./scripts/wp.sh cache flush
./scripts/wp.sh elasticpress index

rsync -re ssh $STAGE_USERNAME@$STAGE_HOSTNAME:$STAGE_UPLOAD_PATH/* src/app/uploads

cd -