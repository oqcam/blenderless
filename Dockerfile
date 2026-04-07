# Test runner for blenderless.
# Runs the full test suite via Bazel inside a consistent Ubuntu 24.04 environment.
#
# Usage:
#   docker build -t blenderless-test .
#   docker run blenderless-test
#
# Or with docker-compose:
#   docker compose run test

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

# System packages required at runtime:
# - python3.12, python3: Python interpreter (Bazel also downloads its own hermetic copy)
# - curl, zstd: needed to download and extract the pre-built bpy tarball
# - zip, file: used by Bazel's test harness to archive test outputs
# - libgl1: OpenGL support required by scikit-image (test dependency)
# - ca-certificates, git: needed by Bazel to fetch external dependencies
# - gcc, g++: needed by Bazel's C++ toolchain auto-configuration
#
# The remaining packages are runtime shared library dependencies of the pre-built
# headless Blender (bpy) binary. bpy was compiled on Ubuntu 24.04, so these must
# match the build environment's library versions.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.12 python3 curl zstd zip file libgl1 ca-certificates git gcc g++ \
        libtbb12 libjpeg8 libpng16-16t64 libtiff6 libfreetype6 \
        libwebp7 libwebpdemux2 libepoxy0 libopenjp2-7 libpugixml1v5 \
        libpotrace0 libopenexr-3-1-30 libopencolorio2.1t64 libblosc1 \
        libfftw3-double3 libfftw3-single3 libboost-filesystem1.83.0 \
        libboost-iostreams1.83.0 libboost-thread1.83.0 libembree4-4 \
    && rm -rf /var/lib/apt/lists/*

# Install Bazelisk, which auto-downloads the Bazel version specified in .bazelversion.
RUN curl -fsSL https://github.com/bazelbuild/bazelisk/releases/download/v1.25.0/bazelisk-linux-amd64 \
    -o /usr/local/bin/bazel \
    && chmod +x /usr/local/bin/bazel

# Pre-extract the bpy tarball and register its bundled shared libraries.
# The bpy binary bundles custom-built versions of OpenImageIO, OpenVDB, and OpenImageDenoise
# in its lib/ directory. Bazel downloads the same tarball at build time, but the system's
# dynamic linker won't find these bundled libraries unless they're registered via ldconfig.
# This step extracts the tarball to a temporary location solely to run ldconfig on its lib/ dir.
ARG BPY_URL=https://github.com/oqcam/blenderless/releases/download/bpy-4.2.19-python3.12/bpy-4.2.19-headless-python3.12-x86_64-linux-gnu.tar.zst
RUN mkdir -p /tmp/bpy-cache \
    # Download the pre-built headless bpy tarball
    && curl -fsSL "${BPY_URL}" -o /tmp/bpy.tar.zst \
    # Extract to a temporary directory
    && tar --zstd -xf /tmp/bpy.tar.zst -C /tmp/bpy-cache --strip-components=1 \
    # Register the bundled shared libraries (OIIO, OpenVDB, OIDN) with the dynamic linker
    && echo "/tmp/bpy-cache/lib" > /etc/ld.so.conf.d/bpy.conf \
    && ldconfig \
    # Clean up the downloaded archive
    && rm /tmp/bpy.tar.zst

# Create a non-root user. Bazel's hermetic Python toolchain refuses to run as root
# (see https://github.com/bazelbuild/rules_python/pull/713).
RUN useradd -m builder
WORKDIR /home/builder/workspace

# Copy source with correct ownership so the builder user can write Bazel output files.
COPY --chown=builder:builder . .

USER builder

CMD ["bazel", "test", "tests", "--test_output=errors"]
