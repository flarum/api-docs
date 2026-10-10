import json
import os
import re
import shutil
import subprocess
import sys

from _vars import FLARUM_PATH, FLARUM_CORE_PATH, REPO_PATH, SCRIPTS_PATH, git, group, initialize, run


def generate(ref: str, skip_existing: bool = False) -> None:
    path = REPO_PATH / "docs" / "js" / ref
    if skip_existing and path.is_dir():
        print(f" - {ref} -> tag already exists, skipping", flush=True)
        return

    try:
        ref_sha = git(
            "rev-parse",
            "--verify",
            f"origin/{ref}^{{commit}}",
            cwd=FLARUM_CORE_PATH,
            stderr=subprocess.DEVNULL,
        )
        short_sha = ref_sha[:9]
    except subprocess.CalledProcessError:
        short_sha = "unknown"
        ref_sha = ""

    stamp_file = path / ".source-ref-sha"
    if ref_sha and stamp_file.is_file() and stamp_file.read_text(encoding="utf-8").strip() == ref_sha:
        print(f" - {ref} ({short_sha}) cached", flush=True)
        return

    print(f" - {ref} ({short_sha})", flush=True)
    shutil.rmtree(path, ignore_errors=True)
    path.mkdir(parents=True)

    with group("Prepare source"):
        run(["git", "checkout", "-q", "--", "."], cwd=FLARUM_PATH)
        run(["git", "clean", "-f", "-d"], cwd=FLARUM_PATH)
        run(["git", "checkout", "-q", ref], cwd=FLARUM_PATH)
        run(["yarn", "install", "--immutable"], cwd=FLARUM_PATH)

    package_file = FLARUM_CORE_PATH / "js" / "package.json"
    if package_file.is_file():
        package = json.loads(package_file.read_text(encoding="utf-8"))
        if package.get("name") == "@flarum/core":
            package["name"] = "flarum"
            package_file.write_text(json.dumps(package, indent=2) + "\n", encoding="utf-8")

    typedoc_package = REPO_PATH / "typedoc.package.json"
    core_typedoc = FLARUM_CORE_PATH / "js" / "typedoc.json"
    shutil.copy(typedoc_package, core_typedoc)
    typedoc_lines = core_typedoc.read_text(encoding="utf-8").splitlines(keepends=True)
    del typedoc_lines[10]
    core_typedoc.write_text("".join(typedoc_lines), encoding="utf-8")

    extensions_path = FLARUM_PATH / "extensions"
    for extension in extensions_path.iterdir():
        extension_js = extension / "js"
        if not extension_js.is_dir():
            continue
        shutil.copy(typedoc_package, extension_js / "typedoc.json")
        tsconfig = extension_js / "tsconfig.json"
        if not tsconfig.is_file():
            shutil.copy(extensions_path / "flags" / "js" / "tsconfig.json", tsconfig)

    env = os.environ.copy()
    env["NODE_OPTIONS"] = "--max-old-space-size=16384"
    run(
        ["npx", "typedoc", "--gitRevision", ref, "--out", str(path),
         "--name", f"Flarum ({ref})", "--readme", str(REPO_PATH / "src" / "readme-js.md")],
        cwd=REPO_PATH,
        env=env,
    )
    stamp_file.write_text(f"{ref_sha}\n", encoding="utf-8")


initialize()
with group("Building JS v2.x"):
    generate("2.x")
with group("Building JS v1.x"):
    generate("1.x")

latest_tags: dict[str, str] = {}
tags = git("tag", "--sort=-v:refname", cwd=FLARUM_CORE_PATH).splitlines()
for tag in tags:
    match = re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", tag)
    if not match:
        continue
    key = f"{match.group(1)}.{match.group(2)}"
    if key in {"1.0", "1.1", "1.2"} or key in latest_tags:
        continue
    latest_tags[key] = tag

for key in sorted(latest_tags, key=lambda value: tuple(int(part) for part in value.split("."))):
    ref = latest_tags[key]
    with group(f"Building JS {ref}"):
        generate(ref, True)

run([sys.executable, str(SCRIPTS_PATH / "set-redirects.py"), "js"], cwd=REPO_PATH)
run([sys.executable, str(SCRIPTS_PATH / "set-index-file.py"), "js"], cwd=REPO_PATH)
