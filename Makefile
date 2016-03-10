.PHONY: all test docker publish-docker assets glide deps

VERSION?=$(shell git describe HEAD | sed s/^v//)
DATE?=$(shell date -u '+%Y-%m-%d_%H:%M:%S')
DOCKERNAME?=alde/eremetic
DOCKERTAG?=${DOCKERNAME}:${VERSION}
LDFLAGS=-X main.Version '${VERSION}' -X main.BuildDate '${DATE}'
TOOLS=${GOPATH}/bin/go-bindata \
	${GOPATH}/bin/go-bindata-assetfs \
	${GOPATH}/bin/glide
SRC=$(shell find . -name '*.go')
STATIC=$(shell find static templates)
PACKAGES=$(shell glide novendor)

all: test

test: eremetic
	go test -v ${PACKAGES}

assets:
	go generate

${TOOLS}:
	go get github.com/Masterminds/glide
	go get github.com/jteeuwen/go-bindata/...
	go get github.com/elazarl/go-bindata-assetfs/...

deps: ${TOOLS}
	glide install

eremetic: deps assets
eremetic: ${SRC}
	go build -ldflags "${LDFLAGS}" -o $@

docker/eremetic: deps assets
docker/eremetic: ${SRC}
	CGO_ENABLED=0 GOOS=linux go build -ldflags "${LDFLAGS}" -a -installsuffix cgo -o $@

docker: docker/eremetic docker/Dockerfile docker/marathon.sh
	docker build -t ${DOCKERTAG} docker

publish-docker: docker
	docker push ${DOCKERTAG}
	git describe HEAD --exact 2>/dev/null && \
		docker tag ${DOCKERTAG} ${DOCKERNAME}:latest && \
		docker push ${DOCKERNAME}:latest || true
