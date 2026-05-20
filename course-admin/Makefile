DOCKER_HUB_USER ?= your-dockerhub-username
IMAGE_NAME = k8s-debug-app
VERSION = v1

.PHONY: build push run help

build:
	docker build -t $(DOCKER_HUB_USER)/$(IMAGE_NAME):$(VERSION) .

push:
	docker push $(DOCKER_HUB_USER)/$(IMAGE_NAME):$(VERSION)

run:
	docker run -p 8080:8080 $(DOCKER_HUB_USER)/$(IMAGE_NAME):$(VERSION)

help:
	@echo "Usage:"
	@echo "  make build DOCKER_HUB_USER=<user>   Build the image"
	@echo "  make push DOCKER_HUB_USER=<user>    Push to Docker Hub"
	@echo "  make run DOCKER_HUB_USER=<user>     Run locally"
