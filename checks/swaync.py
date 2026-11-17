"""Checks that swaync runs every command in its configuration as written.

swaync runs a command with Shell.parse_argv("/bin/sh -c \"%s\"".printf(cmd)). A double quote or a
backslash in the command changes what /bin/sh gets, or splits the command into several arguments.
"""
import json
import shlex
import sys

KEYS = ("command", "update-command")


def commands(node, path=""):
    if isinstance(node, dict):
        for key, value in node.items():
            if key in KEYS and isinstance(value, str):
                yield f"{path}.{key}", value
            else:
                yield from commands(value, f"{path}.{key}")
    elif isinstance(node, list):
        for index, value in enumerate(node):
            yield from commands(value, f"{path}[{index}]")


failed = 0
for config in sys.argv[1:]:
    with open(config) as f:
        for where, cmd in commands(json.load(f)):
            argv = None
            if '"' not in cmd and "\\" not in cmd:
                argv = shlex.split('/bin/sh -c "%s"' % cmd)
            if argv != ["/bin/sh", "-c", cmd]:
                print(f'{config}: {where}: swaync runs this as /bin/sh -c "...", so use no double quotes or backslashes: {cmd}')
                failed += 1

sys.exit(1 if failed else 0)
