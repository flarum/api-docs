import shutil
import re
import sys
from datetime import datetime
from html import escape

from _vars import FLARUM_CORE_PATH, REPO_PATH, git


section = sys.argv[1]
section_path = REPO_PATH / "docs" / section
index_file = section_path / "index.html"

TEMPLATE_FILE = REPO_PATH / "src" / "index-template.html"
content = TEMPLATE_FILE.read_text(encoding="utf-8")

# shutil.copy(REPO_PATH / "src" / "index-template.html", index_file)
print(f"Filling {index_file.name}")

directories = [directory.name for directory in section_path.iterdir() if directory.is_dir()]
branches = sorted(
    (value for value in directories if re.fullmatch(r"\d+\.x", value)),
    key=lambda value: int(value.split(".")[0]),
    reverse=True,
)
latest_versions: dict[str, str] = {}
for tag in git("tag", "--sort=-v:refname", cwd=FLARUM_CORE_PATH).splitlines():
    match = re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", tag)
    if not match:
        continue
    major, minor, _ = match.groups()
    if f"{major}.{minor}" in {"1.0", "1.1", "1.2"}:
        continue
    if f"{major}.{minor}" not in latest_versions:
        latest_versions[f"{major}.{minor}"] = tag

versions = sorted(
    (value for value in directories if value in latest_versions.values()),
    key=lambda value: tuple(int(part) for part in value[1:].split(".")),
    reverse=True,
)

def ref_date(ref: str) -> tuple[str, str]:
    value = git("log", "-1", "--format=%cI", f"origin/{ref}" if ref in branches else ref, cwd=FLARUM_CORE_PATH)
    date = datetime.fromisoformat(value).date()
    display = date.strftime("%b %-d, %Y") if sys.platform != "win32" else date.strftime("%b %#d, %Y")
    return date.isoformat(), display


def link(ref: str) -> str:
    iso_date, display_date = ref_date(ref)
    return (
        f'        <li><a class="version-link" href="{escape(ref)}/index.html">'
        f'<span>{escape(ref)}</span><time class="version-date" datetime="{iso_date}">'
        f'{display_date}</time></a></li>\n'
    )


branch_links = "".join(
    link(branch) for branch in branches
)
version_links = "".join(
    link(version) for version in versions
)

content = content.replace("%BRANCHES%", branch_links)
content = content.replace("%VERSIONS%", version_links)
content = content.replace("%LANG%", section.upper())
index_file.write_text(content, encoding="utf-8", newline="")
