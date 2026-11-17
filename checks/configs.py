"""Parses the tracked JSON, JSONC and TOML files outside docs/."""
import json
import subprocess
import sys
import tomllib


def tracked(*patterns):
    files = subprocess.run(["git", "ls-files", *patterns], capture_output=True, text=True, check=True)
    return [f for f in files.stdout.splitlines() if not f.startswith("docs/")]


def strip_jsonc_comments(text):
    """Removes // and /* */ comments outside strings."""
    out, i, in_string = [], 0, False
    while i < len(text):
        c = text[i]
        if in_string:
            out.append(c)
            if c == "\\":
                out.append(text[i + 1])
                i += 1
            elif c == '"':
                in_string = False
        elif c == '"':
            in_string = True
            out.append(c)
        elif text.startswith("//", i):
            while i < len(text) and text[i] != "\n":
                i += 1
            continue
        elif text.startswith("/*", i):
            end = text.find("*/", i + 2)
            i = len(text) if end == -1 else end + 2
            continue
        else:
            out.append(c)
        i += 1
    return "".join(out)


failed = 0
for path in tracked("*.json", "*.jsonc", "*.toml"):
    try:
        with open(path, "rb") as f:
            data = f.read()
        if path.endswith(".toml"):
            tomllib.loads(data.decode())
        elif path.endswith(".jsonc"):
            json.loads(strip_jsonc_comments(data.decode()))
        else:
            json.loads(data)
    except (ValueError, tomllib.TOMLDecodeError) as error:
        print(f"{path}: {error}")
        failed += 1

sys.exit(1 if failed else 0)
