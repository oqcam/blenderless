""" Defines blenderless dependencies.
"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def blenderless_repositories():
    http_archive(
        name = "bpy",
        build_file = "@blenderless//build_tools:bpy.BUILD.bazel",
        sha256 = "ff66454cf44db736b626b7030a30171ce4e271b034bea5049683eb63d314daea",
        strip_prefix = "install",
        url = "https://github.com/oqcam/blenderless/releases/download/bpy-4.2.19-python3.12-r3/bpy-4.2.19-headless-python3.12-x86_64-linux-gnu.tar.zst",
    )
