TAG        := latest
IMAGE_NAME := panubo/rundeck
REGISTRY   := docker.io

DOCKER_VOLUMES := -v $(shell pwd)/tests/fixtures/config/:/config \
	-v $(shell pwd)/tests/fixtures/lib/data:/var/lib/rundeck/data \
	-v $(shell pwd)/tests/fixtures/lib/logs:/var/lib/rundeck/var \
	-v $(shell pwd)/tests/fixtures/lib/logs:/var/lib/rundeck/logs \
	-v $(shell pwd)/tests/fixtures/home:/home/rundeck \
	-v $(shell pwd)/tests/fixtures/var:/var/rundeck \
	-v $(shell pwd)/tests/fixtures/log:/var/log/rundeck

.PHONY: *
.PHONY: test _ci_test

build:
	docker build --pull --cache-from ${REGISTRY}/${IMAGE_NAME}:latest -t ${IMAGE_NAME}:${TAG} .

build-amd64:
	docker build --platform linux/amd64 --pull --cache-from ${REGISTRY}/${IMAGE_NAME}:latest -t ${IMAGE_NAME}:${TAG} .

build-aarch64:
	docker build --platform linux/aarch64 --pull --cache-from ${REGISTRY}/${IMAGE_NAME}:latest -t ${IMAGE_NAME}:${TAG} .

build-dev:
	docker build --pull -t ${IMAGE_NAME}:${TAG} .

bash:
	docker run --rm -it --name rundeck -p 4440:4440 $(DOCKER_VOLUMES) --entrypoint /bin/bash ${REGISTRY}/${IMAGE_NAME}:${TAG}

run:
	docker run --rm -it --name rundeck -p 4440:4440 $(DOCKER_VOLUMES) ${IMAGE_NAME}:${TAG}

push:
	docker tag ${IMAGE_NAME}:${TAG} ${REGISTRY}/${IMAGE_NAME}:${TAG}
	docker push ${REGISTRY}/${IMAGE_NAME}:${TAG}

clean:
	docker rmi ${IMAGE_NAME}:${TAG}

tree: build
	docker run --rm -it --name rundeck --entrypoint /bin/bash ${IMAGE_NAME}:${TAG} -c "apt-get update && apt-get -y install tree && tree /opt"

test:  ## run test suite against $(IMAGE_NAME):$(TAG)
	( cd tests; IMAGE="$(IMAGE_NAME):$(TAG)" bats -j 4 . )

_ci_test:
	-mkdir -p tests/results
	( cd tests; IMAGE="$(IMAGE_NAME):test" bats -j 4 --report-formatter junit -o results . )
