""" Defines blenderless dependencies.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def blenderless_repositories():
    http_archive(
        name = "bpy",
        build_file = "@blenderless//build_tools:bpy.BUILD.bazel",
        sha256 = "69323b1235f16143245a72d3446f9071cd6743345d806c3cd659ac2713052237",
        strip_prefix = "install",
        url = "https://github.com/oqcam/blenderless/releases/download/bpy-4.2.19-python3.12-r2/bpy-4.2.19-headless-python3.12-x86_64-linux-gnu.tar.zst",
    )
