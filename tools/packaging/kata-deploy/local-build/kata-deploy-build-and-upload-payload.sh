#!/usr/bin/env bash
#
# Copyright 2022 Intel
#
# SPDX-License-Identifier: Apache-2.0
#

[ -z "${DEBUG}" ] || set -x
set -o errexit
set -o nounset
set -o pipefail
set -o errtrace

KATA_DEPLOY_DIR="`dirname ${0}`/../../kata-deploy"
KATA_DEPLOY_ARTIFACT="${1:-"kata-static.tar.xz"}"
REGISTRY="${2:-"ghcr.io/mmhartmann/kata-deploy"}"
TAG="${3:-}"
BAKE_SH_URL="https://raw.githubusercontent.com/flatcar/sysext-bakery/main/bake.sh"

echo "Copying ${KATA_DEPLOY_ARTIFACT} to ${KATA_DEPLOY_DIR}"
cp ${KATA_DEPLOY_ARTIFACT} ${KATA_DEPLOY_DIR}

pushd ${KATA_DEPLOY_DIR}

# Include the bake.sh script from the sysext-bakery
wget "${BAKE_SH_URL}" -O "scripts/bake.sh"

arch=$(uname -m)
[ "$arch" = "x86_64" ] && arch="amd64"
IMAGE_TAG="${REGISTRY}/kata-containers"

echo "Building the image"
docker build --tag ${IMAGE_TAG} .

echo "Pushing the image to the registry"
docker push ${IMAGE_TAG}

if [ -n "${TAG}" ]; then
	ADDITIONAL_TAG="${REGISTRY}:${TAG}"

	echo "Building the ${ADDITIONAL_TAG} image"

	docker build --tag ${ADDITIONAL_TAG} .

	echo "Pushing the image ${ADDITIONAL_TAG} to the registry"
	docker push ${ADDITIONAL_TAG}
fi

rm "scripts/bake.sh"

popd
