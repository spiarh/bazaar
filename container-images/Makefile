VERSION=latest
REGISTRY=docker.io/spiarh

build: 
	docker build --build-arg REGISTRY=${REGISTRY} -t ${REGISTRY}/${IMAGE}:${VERSION} ${IMAGE}/
	docker tag ${REGISTRY}/${IMAGE}:${VERSION} ${REGISTRY}/${IMAGE}:latest

push:
	docker push ${REGISTRY}/${IMAGE}:${VERSION}
