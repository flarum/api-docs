import re
import sys

from _vars import REPO_PATH


section = sys.argv[1]
section_path = REPO_PATH / "docs" / section
redirects_file = REPO_PATH / "docs" / "_redirects"
versions = sorted(
    (directory.name for directory in section_path.iterdir() if directory.is_dir()),
    reverse=True,
    key=lambda value: tuple(int(part) for part in re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", value).groups())
    if re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", value)
    else (-1, -1, -1),
)

latest = versions[0]
content = redirects_file.read_text(encoding="utf-8")
content = re.sub(
    rf"^/{re.escape(section)}/latest.*$",
    f"/{section}/latest\t\t\t/{section}/{latest}/index.html",
    content,
    count=1,
    flags=re.MULTILINE,
)

start = f"# BEGIN AUTO {section.upper()} REDIRECTS"
end = f"# END AUTO {section.upper()} REDIRECTS"
lines = [start]
seen_minors: set[str] = set()

for version in versions:
    match = re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", version)
    if not match:
        continue
    major, minor, patch = match.groups()
    minor_version = f"{major}.{minor}"
    if minor_version in seen_minors:
        continue
    seen_minors.add(minor_version)
    lines.append(f"/{section}/v{minor_version}            /{section}/{version}/index.html     302")
    if patch != "0":
        lines.append(f"/{section}/v{minor_version}.0          /{section}/{version}/index.html     302")

lines.append(end)
block = "\n".join(lines)
pattern = rf"{re.escape(start)}\n.*?{re.escape(end)}"
content, replacements = re.subn(pattern, block, content, count=1, flags=re.DOTALL)
if replacements != 1:
    raise RuntimeError(f"Could not find redirect block for {section}")

redirects_file.write_text(content, encoding="utf-8", newline="")
