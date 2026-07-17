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
# - curl: needed to install Bazelisk below
# - zip, file: used by Bazel's test harness to archive test outputs
# - libgl1: OpenGL support required by scikit-image (test dependency)
# - ca-certificates, git: needed by Bazel to fetch external dependencies
# - gcc, g++: needed by Bazel's C++ toolchain auto-configuration
#
# The bpy tarball (fetched by Bazel) is self-contained: it bundles its full
# runtime library closure with RUNPATHs stamped, so no Blender-related
# packages are installed here — this image doubles as a check that the
# tarball really is self-contained.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3.12 python3 curl zip file libgl1 ca-certificates git gcc g++ \
    && rm -rf /var/lib/apt/lists/*

# Install Bazelisk, which auto-downloads the Bazel version specified in .bazelversion.
RUN curl -fsSL https://github.com/bazelbuild/bazelisk/releases/download/v1.25.0/bazelisk-linux-amd64 \
    -o /usr/local/bin/bazel \
    && chmod +x /usr/local/bin/bazel

# Create a non-root user. Bazel's hermetic Python toolchain refuses to run as root
# (see https://github.com/bazelbuild/rules_python/pull/713).
RUN useradd -m builder
WORKDIR /home/builder/workspace

# Copy source with correct ownership so the builder user can write Bazel output files.
COPY --chown=builder:builder . .

USER builder

CMD ["bazel", "test", "tests", "--test_output=errors"]
