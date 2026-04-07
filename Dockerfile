FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.12 python3 curl zstd libgl1 ca-certificates git gcc g++ \
        libtbb12 libgomp1 libjpeg8 libpng16-16t64 libtiff6 libfreetype6 \
        libwebp7 libwebpdemux2 libepoxy0 libopenjp2-7 libpugixml1v5 \
        libpotrace0 libopenexr-3-1-30 libopencolorio2.1t64 libblosc1 \
        libfftw3-double3 libfftw3-single3 libboost-filesystem1.83.0 \
        libboost-iostreams1.83.0 libboost-thread1.83.0 libembree4-4 \
        libglu1-mesa libegl1 libxi6 libxrender1 libxxf86vm1 \
    && rm -rf /var/lib/apt/lists/*

# Install Bazelisk (auto-manages Bazel versions)
RUN curl -fsSL https://github.com/bazelbuild/bazelisk/releases/download/v1.25.0/bazelisk-linux-amd64 \
    -o /usr/local/bin/bazel \
    && chmod +x /usr/local/bin/bazel

# Pre-cache Bazel's bpy download and register its bundled libs with ldconfig
RUN mkdir -p /tmp/bpy-cache \
    && curl -fsSL "https://github.com/oqcam/blenderless/releases/download/bpy-4.2.19-python3.12/bpy-4.2.19-headless-python3.12-x86_64-linux-gnu.tar.zst" \
        -o /tmp/bpy.tar.zst \
    && tar --zstd -xf /tmp/bpy.tar.zst -C /tmp/bpy-cache --strip-components=1 \
    && echo "/tmp/bpy-cache/lib" > /etc/ld.so.conf.d/bpy.conf \
    && ldconfig \
    && rm /tmp/bpy.tar.zst

RUN useradd -m builder
WORKDIR /home/builder/workspace

COPY --chown=builder:builder . .

USER builder

CMD ["bazel", "test", "tests", "--test_output=errors"]
