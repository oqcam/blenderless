""" Defines blenderless dependencies.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def blenderless_repositories():
    http_archive(
        name = "bpy",
        build_file = "@blenderless//build_tools:bpy.BUILD.bazel",
        sha256 = "4bf30b5eb6365e648e4ad7a0ce3d45a8a303cb0b722890fe0c33e799e1fe736b",
        strip_prefix = "install",
        url = "https://github.com/oqcam/blenderless/releases/download/bpy-4.2.19-python3.12/bpy-4.2.19-headless-python3.12-x86_64-linux-gnu.tar.zst",
    )
