from pathlib import Path
import os
import shutil
import subprocess


SCRIPTS_PATH = Path(__file__).resolve().parent
REPO_PATH = SCRIPTS_PATH.parent
FLARUM_PATH = REPO_PATH / "flarum"
FLARUM_CORE_PATH = FLARUM_PATH / "framework" / "core"
_last_cwd = Path.cwd().resolve()


def log(message: str) -> None:
    print(f"##[command]{message}")


def run(command: list[str], cwd: Path | None = None, **kwargs) -> None:
    # Log the working directory if it's changed as a `cd` command for GitHub Actions log.
    global _last_cwd
    current_cwd = (cwd or Path.cwd()).resolve()
    if current_cwd != _last_cwd:
        log(f"cd {current_cwd}")
        _last_cwd = current_cwd

    log(" ".join(command))
    executable = shutil.which(command[0])
    if executable is None:
        raise FileNotFoundError(f"Could not find command: {command[0]}")
    subprocess.run([executable, *command[1:]], cwd=cwd, check=True, **kwargs)


def git(*args: str, cwd: Path) -> str:
    return subprocess.check_output(["git", *args], cwd=cwd, text=True).strip()


def write_github_environment(name: str, value: str) -> None:
    github_env = os.environ.get("GITHUB_ENV")
    if github_env:
        with open(github_env, "a", encoding="utf-8", newline="") as file:
            file.write(f"{name}={value}{os.linesep}")


def initialize() -> None:
    os.environ["SCRIPTS_PATH"] = str(SCRIPTS_PATH)
    os.environ["REPO_PATH"] = str(REPO_PATH)
    os.environ["FLARUM_PATH"] = str(FLARUM_PATH)
    os.environ["FLARUM_CORE_PATH"] = str(FLARUM_CORE_PATH)
    print(f"Using flarum/framework @ {FLARUM_CORE_PATH}")
    if not os.environ.get("GITHUB_ENV"):
        print("Assuming local environment. GITHUB_ENV not set.")
    else:
        write_github_environment(
            "FLARUM_SHA", git("rev-parse", "--verify", "HEAD", "--short", cwd=FLARUM_CORE_PATH)
        )
