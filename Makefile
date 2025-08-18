build:
	docker build -t kiwix-zip-updater .

run:
	docker run -v ./zims:/zims -e DIR='zims' -e ARGS='' --rm -it kiwix-zip-updater
