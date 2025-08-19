build:
	docker build -t kiwix-zip-updater .

run:
	docker run -v ./zims:/zims -e DIR='zims' -e ARGS='-t -d' --rm -it kiwix-zip-updater
