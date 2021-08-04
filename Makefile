YB_BUILD_INFRASTRUCTURE_DOCKER_TAG?=local/yb-builder-toolchain
YB_BUILD_INFRASTRUCTURE_DOCKER_VERSION?=latest
YB_BUILD_INFRASTRUCTURE_GCC_VERSION?=7.3.0
YB_BUILD_INFRASTRUCTURE_GCC_MAKE_PARALLELISM?=32

YB_REPOSITORY?=https://github.com/yugabyte/yugabyte-db.git
YB_SOURCE_VERSION?=v2.7.2

YB_RELEASE_VERSION?=2.7.2.0

YB_RELEASE_DOCKER_TAG?=local/yugabytedb
YB_RELEASE_DOCKER_VERSION?=${YB_RELEASE_VERSION}
YB_RELEASE_DOCKER_ARG_GID?=1000
YB_RELEASE_DOCKER_ARG_GROUP?=yb
YB_RELEASE_DOCKER_ARG_UID?=1000
YB_RELEASE_DOCKER_ARG_USER?=yb

CURRENT_DIR=$(dir $(realpath $(firstword $(MAKEFILE_LIST))))
PLATFORM=$(shell uname -s)

.PHONY: ybdb-build-infrastructure
ybdb-build-infrastructure:
	cd ${CURRENT_DIR}/.docker/yugabytedb-build-infrastructure \
		&& docker build \
			--no-cache --progress=plain \
			--build-arg GCC_VERSION=${YB_BUILD_INFRASTRUCTURE_GCC_VERSION} \
			--build-arg GCC_MAKE_PARALLELISM=${YB_BUILD_INFRASTRUCTURE_GCC_MAKE_PARALLELISM} \
			-t ${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${YB_BUILD_INFRASTRUCTURE_DOCKER_VERSION} .

.PHONY: ybdb-build-first-pass
ybdb-build-first-pass:
ifeq ($(PLATFORM),Linux)
	sudo rm -rf ${CURRENT_DIR}/.tmp/yb-build \
		&& sudo rm -rf ${CURRENT_DIR}/.tmp/yb-maven \
		&& sudo rm -rf ${CURRENT_DIR}/.tmp/yb-source
else
	rm -rf ${CURRENT_DIR}/.tmp/yb-build \
		&& sudo rm -rf ${CURRENT_DIR}/.tmp/yb-maven \
		&& sudo rm -rf ${CURRENT_DIR}/.tmp/yb-source
endif
	mkdir -p ${CURRENT_DIR}/.tmp/yb-build \
		&& mkdir -p ${CURRENT_DIR}/.tmp/yb-maven \
		&& mkdir -p ${CURRENT_DIR}/.tmp/yb-source \
		&& mkdir -p ${CURRENT_DIR}/.tmp/extensions \
		&& docker run --rm -ti \
			-e YB_REPOSITORY=${YB_REPOSITORY} \
			-e YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
			-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
			-v ${CURRENT_DIR}/.tmp/yb-build:/opt/yb-build \
			-v ${CURRENT_DIR}/.tmp/yb-source:/yb-source \
			-v ${CURRENT_DIR}/.tmp/extensions:/extensions \
			${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${YB_BUILD_INFRASTRUCTURE_DOCKER_VERSION} yb-first-pass-build.sh

.PHONY: ybdb-rebuild
ybdb-rebuild:
	docker run --rm -ti \
		-e YB_SOURCE_VERSION=${YB_SOURCE_VERSION} \
		-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
		-v ${CURRENT_DIR}/.tmp/yb-build:/opt/yb-build \
		-v ${CURRENT_DIR}/.tmp/yb-source:/yb-source \
		-v ${CURRENT_DIR}/.tmp/extensions:/extensions \
		${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${YB_BUILD_INFRASTRUCTURE_DOCKER_VERSION} yb-rebuild.sh

.PHONY: ybdb-distribution
ybdb-distribution:
	docker run --rm -ti \
		-e YB_RELEASE_VERSION=${YB_RELEASE_VERSION} \
		-v ${CURRENT_DIR}/.tmp/yb-maven:/root/.m2 \
		-v ${CURRENT_DIR}/.tmp/yb-build:/opt/yb-build \
		-v ${CURRENT_DIR}/.tmp/yb-source:/yb-source \
		-v ${CURRENT_DIR}/.tmp/extensions:/extensions \
		${YB_BUILD_INFRASTRUCTURE_DOCKER_TAG}:${YB_BUILD_INFRASTRUCTURE_DOCKER_VERSION} yb-release.sh

.PHONY: ybdb-build-docker
ybdb-build-docker:
ifeq ($(PLATFORM),Linux)
	sudo chmod 0644 ${CURRENT_DIR}/.tmp/yb-source/build/yugabyte-*.tar.gz
endif
	mkdir -p ${CURRENT_DIR}/.tmp/yb-docker-build \
		&& cp -v ${CURRENT_DIR}/.tmp/yb-source/build/yugabyte-*.tar.gz ${CURRENT_DIR}/.tmp/yb-docker-build/ \
		&& cp -v ${CURRENT_DIR}/.docker/yugabytedb/Dockerfile ${CURRENT_DIR}/.tmp/yb-docker-build/ \
		&& cd ${CURRENT_DIR}/.tmp/yb-docker-build/ \
		&& docker build \
			--build-arg GID=${YB_RELEASE_DOCKER_ARG_GID} \
			--build-arg GROUPNAME=${YB_RELEASE_DOCKER_ARG_GROUP} \
			--build-arg UID=${YB_RELEASE_DOCKER_ARG_UID} \
			--build-arg USERNAME=${YB_RELEASE_DOCKER_ARG_USER} \
			--build-arg YB_VERSION=${YB_RELEASE_VERSION} \
			-t ${YB_RELEASE_DOCKER_TAG}:${YB_RELEASE_DOCKER_VERSION} .

.PHONY: yb-start-masters
yb-start-masters:
	cd ${CURRENT_DIR}/.compose-yb && docker compose -f compose-masters.yaml up

.PHONY: yb-start-tservers
yb-start-tservers:
	cd ${CURRENT_DIR}/.compose-yb && docker compose -f compose-tservers.yaml up

.PHONY: yb-start-traefik
yb-start-traefik:
	cd ${CURRENT_DIR}/.compose-yb && docker compose -f compose-traefik.yaml up

.PHONY: yb-compose-clean
yb-compose-clean:
	cd ${CURRENT_DIR}/.compose-yb \
		&& docker compose -f compose-traefik.yaml -f compose-tservers.yaml -f compose-traefik.yaml rm
