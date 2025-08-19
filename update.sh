#!/usr/bin/with-contenv sh

cd /zims

/kiwix-zim-updater.sh -t -d .

# Move any new torrents to /watch
if [[ "$(ls | grep '.torrent')" != "" ]]; then
    echo "Found $(ls -l | grep '.torrent' | wc -l) torrent files"
    mv *.torrent /watch

    # Wait for transmission to pick up the new torrents
    while [[ "$(ls /watch | grep '.torrent.added')" == "" ]]; do
        echo "Waiting on torrents to be picked up by transmission..."
        sleep 20
    done
    echo "Torrents have been picked up by transmission"

    # Give transmission a bit of time to start the download
    sleep 10

    # Wait for downloads to finish
    while [[ "$(ls /downloads/incomplete)" != "" ]]; do
        echo "Waiting on torrents to be downloaded by transmission..."
        sleep 60
    done
    echo "Downloads finished"

    # Move downloaded zim files to /zims
    mv /downloads/complete/*.zim .
else
    echo "Found no new torrents"
fi
