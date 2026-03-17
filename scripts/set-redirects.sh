#!/bin/bash -l

echo -e "${style}Updating redirect $reset"

section="$1"
tag=$(cd docs/$1; ls -d */ | cut -f1 -d'/' | sort -V | tail -1)
file="$REPO_PATH/docs/_redirects"

# Replace the /js/latest or /php/latest redirect to point to the latest version
sed -i "s/^\\/$1\/latest.*$/\\/$1\\/latest\t\t\t\\/$1\/$tag\\/index.html/" $file

# Generate per-minor redirects -- e.g. /js/v2.0 -> /js/v2.0.2 and /js/v2.0.0 -> /js/v2.0.2
start="# BEGIN AUTO ${section^^} REDIRECTS"
end="# END AUTO ${section^^} REDIRECTS"
tmp_block="$(mktemp)"
tmp_out="$(mktemp)"

{
    echo "$start"

    declare -A latest_by_minor=()

    # per-minor redirects from vX.Y.Z folders
    last_minor=""
    while IFS= read -r v; do
        [[ "$v" =~ ^v([0-9]+)\.([0-9]+)\.([0-9]+)$ ]] || continue

        minor="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
        patch="${BASH_REMATCH[3]}"

        [[ "$minor" == "$last_minor" ]] && continue
        last_minor="$minor"

        echo "/$section/v$minor            /$section/$v/index.html     302"
        [[ "$patch" != "0" ]] && echo "/$section/v$minor.0          /$section/$v/index.html     302"
    done < <(cd "$REPO_PATH/docs/$section" && ls -d v*/ | tr -d '/' | sort -Vr)

    echo "$end"

} > "$tmp_block"

start_line=$(grep -nF "$start" "$file" | cut -d: -f1)
end_line=$(grep -nF "$end" "$file" | cut -d: -f1)

{
  head -n $((start_line - 1)) "$file"
  cat "$tmp_block"
  tail -n +$((end_line + 1)) "$file"
} > "$tmp_out"

mv "$tmp_out" "$file"