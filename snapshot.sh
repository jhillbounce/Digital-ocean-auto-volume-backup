#!/bin/bash

DIGITALOCEAN_TOKEN=''
VOLUME_ID=''
RETAIN_SNAPSHOT_COUNT=2

DATE=`date '+%Y-%m-%d_%H%-M-%S'`
SNAPSHOT_NAME='snapshot-volume-'${DATE}'-'${VOLUME_ID}

sync

curl -X POST \
  "https://api.digitalocean.com/v2/volumes/$VOLUME_ID/snapshots" \
  -H "authorization: Bearer $DIGITALOCEAN_TOKEN" \
  -H 'cache-control: no-cache' \
  -H 'content-type: application/json' \
  -d "{
  \"name\": \"$SNAPSHOT_NAME\"
}"

OLD_SNAPSHOTS=$(curl https://api.digitalocean.com/v2/snapshots?resource_type=volume \
-H "authorization: Bearer $DIGITALOCEAN_TOKEN" -H 'cache-control: no-cache' \
-H 'content-type: application/json' | jq '.snapshots[] | select(.resource_id == "'$VOLUME_ID'")' | jq -s 'sort_by(.created_at)[:-'$RETAIN_SNAPSHOT_COUNT'][]' | jq .id | sed "s/\"//g")
## Currently, it will keep 2 newest snapshots. If you want to config this, change RETAIN_SNAPSHOT_COUNT to another value, E.g. 1 for keep only the newest snapshot.

status=$?
echo "Status = " $status

if [[ $status != 0 ]] ;
then
	echo "Failed Volume Backup Curl Return Code..." $status
	exit $status;
fi

#Old Backups will not be removed if latest snapshot fails

for SNAPSHOT_ID in $OLD_SNAPSHOTS
do
    echo "Removing Snapshot " $SNAPSHOT_ID
    curl -X DELETE -H 'Content-Type: application/json' \
    -H "authorization: Bearer $DIGITALOCEAN_TOKEN" "https://api.digitalocean.com/v2/snapshots/$SNAPSHOT_ID"
done

#Suggestion to monitor this script with a heartbeat monitor to get an alert if it's not running (E.g. Uptime Robot or other monitoring service)
