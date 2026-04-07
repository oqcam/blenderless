#!/bin/bash
# Builds the headless bpy module inside Docker and extracts the tarball.
#
# The resulting bpy-*.tar.zst file should be uploaded to the GitHub releases
# page and its sha256 updated in build_tools/repositories.bzl.
#
# This takes ~30 minutes on a modern machine (compiles OIIO, OpenVDB, OIDN,
# and Blender from source).

set -ex

IMAGE=blender-builder

BLENDER_VERSION_MAJOR=4
BLENDER_VERSION_MINOR=2
BLENDER_VERSION_PATCH=19
BLENDER_VERSION=$BLENDER_VERSION_MAJOR.$BLENDER_VERSION_MINOR.$BLENDER_VERSION_PATCH
PYTHON_VERSION=3.12

docker_build_args=(
    --build-arg BLENDER_VERSION_MAJOR=$BLENDER_VERSION_MAJOR
    --build-arg BLENDER_VERSION_MINOR=$BLENDER_VERSION_MINOR
    --build-arg BLENDER_VERSION_PATCH=$BLENDER_VERSION_PATCH
    --build-arg PYTHON_VERSION=$PYTHON_VERSION
)

docker build ${docker_build_args[@]} -t ${IMAGE} .
docker run -it --rm -v$(pwd):/output ${IMAGE} bash -c "cp /blender_ws/bpy-$BLENDER_VERSION-headless-python$PYTHON_VERSION-x86_64-linux-gnu.tar.zst /output/"
