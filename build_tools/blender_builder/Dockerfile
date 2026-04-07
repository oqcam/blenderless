# Builds a headless Blender Python module (bpy) from source.
# The output is a self-contained tarball that can be used as a Bazel dependency.
#
# Usage:
#   ./build.sh
#
# The resulting bpy-*.tar.zst tarball should be uploaded to the GitHub releases
# page and referenced in build_tools/repositories.bzl.

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_VERSION=3.12

# Build tools and system library development packages.
# The -dev packages provide headers and static libraries that Blender's CMake
# build links against. The resulting bpy binary will depend on the corresponding
# runtime libraries (without -dev suffix) at execution time.
RUN apt-get update \
    && apt-get install -y \
        build-essential git git-lfs cmake ninja-build \
        libpython$PYTHON_VERSION-dev python$PYTHON_VERSION zstd \
        libx11-dev libxxf86vm-dev libxcursor-dev libxi-dev libxrandr-dev libxinerama-dev libegl-dev \
        libjpeg-dev libpng-dev libtiff-dev libfreetype-dev libepoxy-dev libxml2-dev \
        libwayland-dev libdecor-0-dev wayland-protocols libdbus-1-dev libhdf5-dev \
        libfftw3-dev libblosc-dev libopenexr-dev libtbb-dev \
        libzstd-dev libboost-all-dev libopencolorio-dev libopenimageio-dev \
        libpugixml-dev libpotrace-dev libopenjp2-7-dev libembree-dev \
    && update-alternatives --install /usr/bin/python python /usr/bin/python$PYTHON_VERSION 1

RUN mkdir /blender_ws
WORKDIR /blender_ws

ARG BLENDER_VERSION_MAJOR=4
ARG BLENDER_VERSION_MINOR=2
ARG BLENDER_VERSION_PATCH=19
ARG BLENDER_VERSION=$BLENDER_VERSION_MAJOR.$BLENDER_VERSION_MINOR.$BLENDER_VERSION_PATCH

# Clone from projects.blender.org (not GitHub) to get proper Git LFS support.
# GitHub's mirror doesn't serve LFS objects, resulting in .blend files being
# LFS pointers instead of real data, which causes bpy to segfault on import.
RUN git clone --branch v$BLENDER_VERSION --depth 1 https://projects.blender.org/blender/blender.git \
    && cd blender \
    && git submodule update --init --recursive

# Fetch Blender's asset submodules (fonts, icons, startup templates).
RUN cd blender && make update

# Build OpenImageIO v2.5.11.0 from source.
# Ubuntu 24.04 ships OIIO v2.4.17, but Blender 4.2 requires v2.5.11 (API break in
# ImageInput::valid_file signature).
RUN git clone --branch v2.5.11.0 --depth 1 https://github.com/AcademySoftwareFoundation/OpenImageIO.git /tmp/oiio \
    && cmake -S /tmp/oiio -B /tmp/oiio/build \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DOIIO_BUILD_TOOLS=OFF \
        -DOIIO_BUILD_TESTS=OFF \
        -DUSE_PYTHON=OFF \
        -G Ninja \
    && ninja -C /tmp/oiio/build -j12 \
    && ninja -C /tmp/oiio/build install \
    && rm -rf /tmp/oiio

# Build OpenVDB v11.0.0 from source.
# Ubuntu 24.04 ships OpenVDB v8.1, but Blender 4.2 requires v11.0.0 (incompatible
# with system TBB due to tbb::split API changes).
RUN git clone --branch v11.0.0 --depth 1 https://github.com/AcademySoftwareFoundation/openvdb.git /tmp/openvdb \
    && cmake -S /tmp/openvdb -B /tmp/openvdb/build \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DOPENVDB_BUILD_BINARIES=OFF \
        -DOPENVDB_BUILD_PYTHON_MODULE=OFF \
        -DOPENVDB_BUILD_NANOVDB=ON \
        -G Ninja \
    && ninja -C /tmp/openvdb/build -j12 \
    && ninja -C /tmp/openvdb/build install \
    && rm -rf /tmp/openvdb

# Build OpenImageDenoise v2.3.0 from source.
# OIDN is not available as an Ubuntu package. It provides CPU-based denoising
# for Cycles renders. The weights submodule contains pre-trained neural network models.
RUN apt-get update && apt-get install -y --no-install-recommends ispc && rm -rf /var/lib/apt/lists/*
RUN git clone --branch v2.3.0 --depth 1 --recurse-submodules https://github.com/RenderKit/oidn.git /tmp/oidn \
    && cmake -S /tmp/oidn -B /tmp/oidn/build \
        -DCMAKE_INSTALL_PREFIX=/usr/local \
        -DOIDN_APPS=OFF \
        -G Ninja \
    && ninja -C /tmp/oidn/build -j12 \
    && ninja -C /tmp/oidn/build install \
    && rm -rf /tmp/oidn

# Build headless bpy module.
# - bpy_module.cmake: configures Blender to build as a Python module instead of a standalone app
# - WITH_HEADLESS: disables GUI/window system support (no X11/Wayland at runtime)
# - WITH_INSTALL_PORTABLE: installs bpy relative to the module directory (not system-wide)
# - CMAKE_PREFIX_PATH: find the custom-built OIIO, OpenVDB, and OIDN in /usr/local
# - PYTHON_*: link against the system Python 3.12 headers and static library
RUN mkdir build \
    && cd build \
    && cmake -C ../blender/build_files/cmake/config/bpy_module.cmake \
        -DWITH_HEADLESS=ON \
        -DWITH_INSTALL_PORTABLE=ON \
        -DCMAKE_PREFIX_PATH=/usr/local \
        -DPYTHON_VERSION=$PYTHON_VERSION \
        -DPYTHON_INCLUDE_DIR=/usr/include/python$PYTHON_VERSION \
        -DPYTHON_LIBRARY=/usr/lib/python$PYTHON_VERSION/config-$PYTHON_VERSION-x86_64-linux-gnu/libpython$PYTHON_VERSION.a \
        -DPYTHON_LINKFLAGS="-Xlinker -export-dynamic -lexpat" \
        -DTEST_PYTHON_EXE=/usr/bin/python$PYTHON_VERSION \
        -DCMAKE_INSTALL_PREFIX=/blender_ws/install \
        -G Ninja ../blender \
    && ninja -j12

RUN cd build && ninja install

# Bundle custom-built shared libraries into the install directory.
# These are not available as Ubuntu packages at the required versions, so they must
# be shipped alongside the bpy module for the tarball to be self-contained.
RUN mkdir -p install/lib \
    && cp /usr/local/lib/libOpenImageIO*.so* install/lib/ \
    && cp /usr/local/lib/libopenvdb*.so* install/lib/ \
    && cp /usr/local/lib/libOpenImageDenoise*.so* install/lib/

# Create the distributable tarball.
RUN tar --zstd -cf bpy-$BLENDER_VERSION-headless-python$PYTHON_VERSION-x86_64-linux-gnu.tar.zst install/

# Verify that bpy can be imported successfully.
RUN ldconfig /usr/local/lib \
    && cd install \
    && LD_LIBRARY_PATH=./lib python$PYTHON_VERSION -c "import bpy; print(f'bpy {bpy.app.version_string} loaded successfully')"
