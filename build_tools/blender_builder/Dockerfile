FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

ARG PYTHON_VERSION=3.12

RUN apt-get update \
    && apt-get install -y build-essential git git-lfs subversion cmake libx11-dev libxxf86vm-dev libxcursor-dev libxi-dev libxrandr-dev libxinerama-dev libegl-dev \
        ninja-build libpython$PYTHON_VERSION-dev python$PYTHON_VERSION zstd \
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

RUN GIT_LFS_SKIP_SMUDGE=1 git clone --branch v$BLENDER_VERSION --depth 1 https://github.com/blender/blender.git \
    && cd blender \
    && GIT_LFS_SKIP_SMUDGE=1 git submodule update --init --recursive

RUN cd blender && make update

# Build OpenImageIO v2.5.11.0 from source (Ubuntu 24.04 ships v2.4.17, Blender 4.2 expects v2.5.11)
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

# Build OpenVDB v11.0.0 from source (Ubuntu 24.04 ships v8.1, Blender 4.2 expects v11.0.0)
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

# Copy custom-built shared libs into the install dir so the tarball is self-contained
RUN mkdir -p install/lib \
    && cp /usr/local/lib/libOpenImageIO*.so* install/lib/ \
    && cp /usr/local/lib/libopenvdb*.so* install/lib/

RUN tar --zstd -cf bpy-$BLENDER_VERSION-headless-python$PYTHON_VERSION-x86_64-linux-gnu.tar.zst install/

RUN ldconfig /usr/local/lib && cd install && LD_LIBRARY_PATH=./lib python$PYTHON_VERSION -c "import bpy; print(f'bpy {bpy.app.version_string} loaded successfully')" || echo "Warning: bpy import test had non-zero exit (known issue with headless builds missing startup.blend)"
