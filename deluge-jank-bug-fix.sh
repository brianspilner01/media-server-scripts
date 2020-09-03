#!/bin/bash
# janky workaround for deluge bug, torrent reaches 100% completion but stays in "Downloading" state
# will force recheck and optionally alert sysadmin via pushbullet as well as run deluge 'execute' plugin script
# run on cron job, make sure dependencies are installed on the system (e.g. `sudo apt install jq`)
# example cron (every 15min):
# */15 * * * * /scripts/deluge-jank-bug-fix.sh >> /scripts/deluge-jank-bug-fix.log

##### CONFIGURE BELOW #####
DELUGE_HOST=10.1.2.3
DELUGE_PORT=8112
DELUGE_WEB_PASS="deluge"
EXECUTE_SCRIPT="/scripts/deluge-execute.sh" #leave blank if not required
PUSHBULLET_ACCESS_TOKEN=xxx #leave blank if not required
##### CONFIGURE ABOVE #####

COOKIE="/tmp/deluge.cookie"

# authenticate with deluge (create cookie)
curl -s -c "$COOKIE" --compressed "http://${DELUGE_HOST}:${DELUGE_PORT}/json" -H 'Content-Type:application/json' -d '{ "id":1, "method":"auth.login", "params":["'"$DELUGE_WEB_PASS"'"] }' > /dev/null

# get list of downloading torrents from deluge and filter any bug affected torrents
DELUGE_OUT=$(curl -s -b "$COOKIE" --compressed "http://${DELUGE_HOST}:${DELUGE_PORT}/json" -H 'Content-Type:application/json' -d '{ "id":1, "method":"core.get_torrents_status", "params":[{"state":"Downloading"},["name","hash","files","save_path","total_done","total_wanted"]] }' | jq '.result | .[] | select(.total_done == .total_wanted) | select(.files != [])')
# note:files=[] when torrent has no seeds to download torrent file list info (falsely triggers script)

if [ ! -z "$DELUGE_OUT" ]
then
	
	HASH_LIST=$(echo "$DELUGE_OUT" | jq -r .hash)
	
	#send pushbullet notification
	echo "Found the following files:"
	echo "$(echo "$DELUGE_OUT" | jq -r .name)"
	[[ ! $PUSHBULLET_ACCESS_TOKEN =~ ^(xxx|)$ ]] && curl -s -u "${PUSHBULLET_ACCESS_TOKEN}:" -X POST https://api.pushbullet.com/v2/pushes -H 'Content-Type: application/json' -d '{ "type":"note", "title":"WARNING - torrent at 100% & still Downloading", "body":"'"$(echo "$DELUGE_OUT" | jq -r .name | sed 's/$/\\n/' | tr -d '\n')"'Forcing recheck and postprocess when complete"}' > /dev/null
	
	#fix each torrent
	for HASH in $HASH_LIST
	do
		
		NAME=$(echo "$DELUGE_OUT" | jq -r --arg HASH $HASH 'select(.hash == $HASH) | .name')
		
		#force recheck
		echo "Forcing recheck on $NAME"
		curl -s -b "$COOKIE" --compressed "http://${DELUGE_HOST}:${DELUGE_PORT}/json" -H 'Content-Type:application/json' -d '{ "id":1, "method":"core.force_recheck", "params":[["'$HASH'"]] }' > /dev/null
		
		#wait for deluge to recheck
		ATTEMPT_INTERVAL=10 #seconds
		sleep $ATTEMPT_INTERVAL
		while [ ! -z "$(curl -s -b $COOKIE --compressed "http://${DELUGE_HOST}:${DELUGE_PORT}/json" -H 'Content-Type:application/json' -d '{ "id":1, "method":"core.get_torrents_status", "params":[{ "hash":"'$HASH'", "state":"Checking"},["hash"]] }' | jq '.result | .[]')" ]
		do
			echo "Waiting ${ATTEMPT_INTERVAL}s for $NAME to recheck"
			sleep $ATTEMPT_INTERVAL
		done
		
		#execute deluge script
		[ ! -z "$EXECUTE_SCRIPT" ] && "$EXECUTE_SCRIPT" "$HASH" "$NAME" "$(echo "$DELUGE_OUT" | jq -r --arg HASH $HASH 'select(.hash == $HASH) | .save_path')" > /dev/null
		# use the following line instead of the above to use with a docker container (e.g. binhex/arch-delugevpn)
		# [ ! -z "$EXECUTE_SCRIPT" ] && docker exec --user nobody delugevpn "$EXECUTE_SCRIPT" "$HASH" "$NAME" "$(echo "$DELUGE_OUT" | jq -r --arg HASH $HASH 'select(.hash == $HASH) | .save_path')" > /dev/null
		
	done
	
fi

rm "$COOKIE"
