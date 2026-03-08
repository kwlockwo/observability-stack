#!/bin/sh
# fetch-dashboards.sh
#
# Fetches Grafana dashboard JSON files from GitHub repos and writes them to
# /var/lib/grafana/dashboards/ (persistent disk, watched by Grafana provisioner).
# Grafana will pick up changes within 30 seconds — no restart needed.
#
# Usage:
#   GITHUB_TOKEN=<token> \
#   DASHBOARD_GITHUB_REPOS="https://github.com/org/repo/tree/main/dashboards" \
#   ./fetch-dashboards.sh
#
# DASHBOARD_GITHUB_REPOS: semicolon-delimited list of GitHub repo URLs.
# GITHUB_TOKEN: personal access token with repo read access.

set -e

DEST_DIR="${DASHBOARD_DEST_DIR:-/var/lib/grafana/dashboards}"

if [ -z "$DASHBOARD_GITHUB_REPOS" ]; then
    echo "Error: DASHBOARD_GITHUB_REPOS is not set" >&2
    exit 1
fi

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Error: GITHUB_TOKEN is not set" >&2
    exit 1
fi

mkdir -p "$DEST_DIR"

echo "$DASHBOARD_GITHUB_REPOS" | tr ';' '\n' | while IFS= read -r url; do
    [ -z "$url" ] && continue

    # Strip https://github.com/ prefix
    path=$(echo "$url" | sed 's|https://github.com/||')
    # org/repo is first two segments
    repo=$(echo "$path" | cut -d'/' -f1-2)
    # Check if URL contains /tree/<branch>/...
    case "$path" in
        */tree/*)
            # Extract branch: segment after "tree/"
            branch=$(echo "$path" | sed 's|.*/tree/||' | cut -d'/' -f1)
            # Extract subpath: everything after "tree/<branch>/"
            subpath=$(echo "$path" | sed "s|.*/tree/${branch}/||")
            # If subpath equals the branch, there's no subpath
            [ "$subpath" = "$branch" ] && subpath=""
            ;;
        *)
            branch="main"
            subpath=""
            ;;
    esac

    echo "Fetching from $repo (branch: $branch, path: ${subpath:-/})"

    CLONE_DIR=$(mktemp -d)
    git clone --depth=1 --branch "$branch" \
        "https://x-token:${GITHUB_TOKEN}@github.com/${repo}.git" "$CLONE_DIR"

    if [ -n "$subpath" ]; then
        SRC="$CLONE_DIR/$subpath"
    else
        SRC="$CLONE_DIR"
    fi

    count=0
    for f in "$SRC"/*.json; do
        [ -f "$f" ] || continue
        cp "$f" "$DEST_DIR/"
        echo "  Copied $(basename "$f")"
        count=$((count + 1))
    done

    rm -rf "$CLONE_DIR"
    echo "  Done - $count dashboard(s) written to $DEST_DIR"
done
