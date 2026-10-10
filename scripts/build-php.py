import sys

from _vars import FLARUM_PATH, REPO_PATH, SCRIPTS_PATH, group, initialize, run


initialize()
with group("PHP: Prepare source"):
    run(["git", "checkout", "-q", "--", "."], cwd=FLARUM_PATH)
    run(["git", "clean", "-f", "-d"], cwd=FLARUM_PATH)

with group("PHP: Generate documentation"):
    run(
        ["php", str(REPO_PATH / "doctum.phar"), "update", "doctum-config.php",
         "--force", "--no-progress", "--ignore-parse-errors"],
        cwd=REPO_PATH,
    )

with group("PHP: Update indexes"):
    run([sys.executable, str(SCRIPTS_PATH / "set-redirects.py"), "php"], cwd=REPO_PATH)
    run([sys.executable, str(SCRIPTS_PATH / "set-index-file.py"), "php"], cwd=REPO_PATH)
