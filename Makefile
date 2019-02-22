TAG        := latest
IMAGE_NAME := panubo/rundeck
REGISTRY   := docker.io

DOCKER_VOLUMES := -v $(shell pwd)/config.yaml:/config/config.yaml \
	-v $(shell pwd)/test/lib/data:/var/lib/rundeck/data \
	-v $(shell pwd)/test/lib/logs:/var/lib/rundeck/logs \
	-v $(shell pwd)/test/home:/home/rundeck \
	-v $(shell pwd)/test/var:/var/rundeck \
	-v $(shell pwd)/test/log:/var/log/rundeck

.PHONY: build bash run push
build:
	docker build --pull -t ${IMAGE_NAME}:${TAG} .

bash:
	docker run --rm -it --name rundeck -p 4440:4440 $(DOCKER_VOLUMES) --entrypoint /bin/bash ${IMAGE_NAME}:${TAG}

run:
	docker run --rm -it --name rundeck -p 4440:4440 $(DOCKER_VOLUMES) ${IMAGE_NAME}:${TAG}

push:
	docker tag ${IMAGE_NAME}:${TAG} ${REGISTRY}/${IMAGE_NAME}:${TAG}
	docker push ${REGISTRY}/${IMAGE_NAME}:${TAG}
