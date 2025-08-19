build:
	docker build -t kiwix-zip-updater .

run:
	docker run -it --rm -p 9091:9091 -e PUID=1000 -e PGID=1000 -v ./zims:/zims --name updater kiwix-zip-updater
