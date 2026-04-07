""" Defines blenderless dependencies.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def blenderless_repositories():
    http_archive(
        name = "bpy",
        build_file = "@blenderless//build_tools:bpy.BUILD.bazel",
        sha256 = "4a766711ab02059a70f5bdd9dfb42d394d080640c2ece93a9e5fcd64055c7fb6",
        strip_prefix = "install",
        url = "https://github.com/oqcam/blenderless/releases/download/bpy-4.2.19-python3.12/bpy-4.2.19-headless-python3.12-x86_64-linux-gnu.tar.zst",
    )
