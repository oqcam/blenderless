""" Defines blenderless dependencies.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def blenderless_repositories():
    http_archive(
        name = "bpy",
        build_file = "@blenderless//build_tools:bpy.BUILD.bazel",
        sha256 = "ff706a9df0bef6e6671b942896975d4483a845fe42dfa773b4a220aee05c311a",
        strip_prefix = "install",
        url = "https://github.com/oqcam/blenderless/releases/download/bpy-4.2.19-python3.12/bpy-4.2.19-headless-python3.12-x86_64-linux-gnu.tar.zst",
    )
