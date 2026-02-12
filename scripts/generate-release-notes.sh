#!/usr/bin/env bash
# ──────────────────────────────────────────────────────────────────────
# generate-release-notes.sh
#
# Generates joint release notes by comparing versions.yaml between
# two tinstaller-releases tags. Used by CI (joint-release.yml) and
# can be run locally for testing.
#
# Environment variables (all optional, have defaults):
#   ORG              GitHub org              (default: transpara)
#   INSTALLER_REPO   Release repo name       (default: tinstaller-releases)
#   OUTPUT_FILE      Where to write the .md  (default: JOINT_RELEASE_NOTES.md)
#
# Arguments:
#   $1  target tag   (optional – defaults to latest release)
#   $2  previous tag (optional – defaults to second-latest release)
#
# Prerequisites: gh (authenticated), yq, jq
# ──────────────────────────────────────────────────────────────────────
set -uo pipefail

# ── Detect CI vs local ───────────────────────────────────────────────
IS_CI="${GITHUB_ACTIONS:-false}"

log()     { echo "[*] $*" >&2; }
warn()    { if [ "$IS_CI" = "true" ]; then echo "::warning::$*" >&2; else echo "[!] WARNING: $*" >&2; fi; }
notice()  { if [ "$IS_CI" = "true" ]; then echo "::notice::$*" >&2; else echo "[i] $*" >&2; fi; }

# ── Verify dependencies ─────────────────────────────────────────────
for cmd in gh yq jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' is required but not found." >&2
    exit 1
  fi
done

if [ "$IS_CI" != "true" ] && ! gh auth status &>/dev/null; then
  echo "ERROR: gh CLI is not authenticated. Run:  gh auth login -h github.com" >&2
  exit 1
fi

# ── Configuration ────────────────────────────────────────────────────
ORG="${ORG:-transpara}"
INSTALLER_REPO="${INSTALLER_REPO:-tinstaller-releases}"
OUTPUT_FILE="${OUTPUT_FILE:-JOINT_RELEASE_NOTES.md}"

# Parallel arrays: versions.yaml path → GitHub repo name
# Order here controls the order in the release notes.
YAML_PATHS=(
  "container_images.tsystem.version"
  "container_images.tstudio.version"
  "container_images.tgraph.version"
  "container_images.tcalc.version"
  "container_images.tview.version"
  "container_images.tauth_scraper.version"
  "container_images.interfaces.tstore.version"
  "container_images.extractors.telegraf.version"
  "container_images.extractors.opcua.version"
  "container_images.extractors.odbc.version"
)
REPO_NAMES=(
  "tsystem"
  "tstudio-py"
  "tgraph-api"
  "tcalc"
  "tview"
  "tauth-scraper"
  "tstore-interface"
  "extractor-telegraf"
  "extractor-opcua"
  "extractor_odbc"
)

# ── Resolve target and previous tags ─────────────────────────────────
if [ "${1:-}" ]; then
  TARGET_TAG="$1"
else
  TARGET_TAG=$(gh release list --repo "$ORG/$INSTALLER_REPO" \
    --limit 1 --json tagName --jq '.[0].tagName')
fi

if [ "${2:-}" ]; then
  PREV_TAG="$2"
else
  PREV_TAG=$(gh release list --repo "$ORG/$INSTALLER_REPO" \
    --limit 2 --json tagName --jq '.[1].tagName // empty')
fi

notice "Target tag:   $TARGET_TAG"
notice "Previous tag: ${PREV_TAG:-<none>}"

# ── Download versions.yaml from both releases ────────────────────────
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

mkdir -p "$WORKDIR/current" "$WORKDIR/previous"

log "Downloading versions.yaml for $TARGET_TAG ..."
gh release download "$TARGET_TAG" --repo "$ORG/$INSTALLER_REPO" \
  --pattern "versions.yaml" --dir "$WORKDIR/current"
CURRENT_YAML="$WORKDIR/current/versions.yaml"

PREV_YAML=""
if [ -n "$PREV_TAG" ]; then
  log "Downloading versions.yaml for $PREV_TAG ..."
  if gh release download "$PREV_TAG" --repo "$ORG/$INSTALLER_REPO" \
      --pattern "versions.yaml" --dir "$WORKDIR/previous" 2>/dev/null; then
    PREV_YAML="$WORKDIR/previous/versions.yaml"
  else
    warn "Could not download versions.yaml from previous release $PREV_TAG"
  fi
fi

# ── Helper: read a version value from a YAML file ────────────────────
get_ver() {
  local file="$1" path="$2"
  if [ -z "$file" ] || [ ! -f "$file" ]; then echo ""; return; fi
  yq eval ".$path" "$file" 2>/dev/null | tr -d '"'
}

# ── Helper: fetch release notes between two versions ─────────────────
# Finds releases published after old_ver up to and including new_ver.
# Falls back gracefully when versions or releases are missing.
fetch_notes_between() {
  local repo="$1" old_ver="$2" new_ver="$3"

  if [ -z "$new_ver" ] || [ "$new_ver" = "null" ]; then return; fi
  if [ "$old_ver" = "$new_ver" ]; then return; fi

  local all_releases
  all_releases=$(gh release list --repo "$ORG/$repo" --limit 100 \
    --json tagName,publishedAt 2>/dev/null || echo "[]")

  # Case 1: no previous version – show only new version notes
  if [ -z "$old_ver" ] || [ "$old_ver" = "null" ]; then
    echo "#### Release: $new_ver"
    gh release view "$new_ver" --repo "$ORG/$repo" \
      --json body --jq '.body' 2>/dev/null || true
    echo ""
    return
  fi

  # Look up published dates for old and new versions
  local old_date new_date
  old_date=$(echo "$all_releases" | jq -r \
    ".[] | select(.tagName == \"$old_ver\") | .publishedAt" 2>/dev/null)
  new_date=$(echo "$all_releases" | jq -r \
    ".[] | select(.tagName == \"$new_ver\") | .publishedAt" 2>/dev/null)

  local tags=""

  if [ -n "$old_date" ] && [ -n "$new_date" ]; then
    # Case 2: both versions found – collect releases between them
    tags=$(echo "$all_releases" | jq -r \
      "[.[] | select(.publishedAt > \"$old_date\" and .publishedAt <= \"$new_date\")] | reverse | .[].tagName" 2>/dev/null)
  elif [ -n "$old_date" ] && [ -z "$new_date" ]; then
    # Case 3: new version has no release yet – show all after old
    tags=$(echo "$all_releases" | jq -r \
      "[.[] | select(.publishedAt > \"$old_date\")] | reverse | .[].tagName" 2>/dev/null)
  else
    # Case 4: can't resolve dates – show just new version notes
    echo "#### Release: $new_ver"
    gh release view "$new_ver" --repo "$ORG/$repo" \
      --json body --jq '.body' 2>/dev/null || true
    echo ""
    return
  fi

  if [ -n "$tags" ]; then
    while IFS= read -r tag; do
      echo "#### Release: $tag"
      gh release view "$tag" --repo "$ORG/$repo" \
        --json body --jq '.body' 2>/dev/null || true
      echo ""
    done <<< "$tags"
  fi
}

# ══════════════════════════════════════════════════════════════════════
#  Build the release notes document
# ══════════════════════════════════════════════════════════════════════
log "Generating release notes → $OUTPUT_FILE"

{
  echo "## Joint Release Notes"
  echo "Aggregated updates from \`${PREV_TAG:-initial}\` to \`$TARGET_TAG\`"
  echo ""

  # ── Section 1: tInstaller release notes (shown FIRST) ──────────────
  CURR_TI=$(get_ver "$CURRENT_YAML" "tinstaller.version")
  PREV_TI=""
  [ -n "$PREV_YAML" ] && PREV_TI=$(get_ver "$PREV_YAML" "tinstaller.version")

  echo "### tInstaller"
  if [ -n "$PREV_TI" ] && [ "$PREV_TI" != "null" ] && [ "$PREV_TI" != "$CURR_TI" ]; then
    echo "Version: \`$PREV_TI\` → \`$CURR_TI\`"
  else
    echo "Version: \`$CURR_TI\`"
  fi
  echo ""
  fetch_notes_between "tinstaller" "$PREV_TI" "$CURR_TI"
  echo "---"
  echo ""

  # ── Section 2: Component release notes ─────────────────────────────
  for i in "${!YAML_PATHS[@]}"; do
    yaml_path="${YAML_PATHS[$i]}"
    repo="${REPO_NAMES[$i]}"

    curr_ver=$(get_ver "$CURRENT_YAML" "$yaml_path")
    prev_ver=""
    [ -n "$PREV_YAML" ] && prev_ver=$(get_ver "$PREV_YAML" "$yaml_path")

    # Skip if version is missing or unchanged
    if [ -z "$curr_ver" ] || [ "$curr_ver" = "null" ]; then continue; fi
    if [ -n "$prev_ver" ] && [ "$prev_ver" = "$curr_ver" ]; then continue; fi

    echo "### $repo"
    if [ -n "$prev_ver" ] && [ "$prev_ver" != "null" ]; then
      echo "Version: \`$prev_ver\` → \`$curr_ver\`"
    else
      echo "Version: \`$curr_ver\`"
    fi
    echo ""
    fetch_notes_between "$repo" "$prev_ver" "$curr_ver"
    echo "---"
    echo ""
  done

  # ── Section 3: Components behind latest release ────────────────────
  echo "### Version Status"
  echo ""

  ALL_PATHS=("tinstaller.version" "${YAML_PATHS[@]}")
  ALL_REPOS=("tinstaller" "${REPO_NAMES[@]}")
  BEHIND=""

  for i in "${!ALL_PATHS[@]}"; do
    yaml_path="${ALL_PATHS[$i]}"
    repo="${ALL_REPOS[$i]}"
    curr_ver=$(get_ver "$CURRENT_YAML" "$yaml_path")
    if [ -z "$curr_ver" ] || [ "$curr_ver" = "null" ]; then continue; fi

    latest=$(gh release list --repo "$ORG/$repo" --limit 1 \
      --json tagName --jq '.[0].tagName' 2>/dev/null || true)

    if [ -n "$latest" ] && [ "$latest" != "$curr_ver" ]; then
      BEHIND+="| $repo | \`$curr_ver\` | \`$latest\` |"$'\n'
    fi
  done

  if [ -n "$BEHIND" ]; then
    echo "**Components in versions.yaml that are behind their latest release:**"
    echo ""
    echo "| Component | versions.yaml | Latest Release |"
    echo "|-----------|---------------|----------------|"
    echo -n "$BEHIND"
  else
    echo "All component versions in versions.yaml match their latest releases."
  fi
  echo ""

} > "$OUTPUT_FILE"

# ── Expose target tag for CI ─────────────────────────────────────────
if [ "$IS_CI" = "true" ] && [ -n "${GITHUB_ENV:-}" ]; then
  echo "target_tag=$TARGET_TAG" >> "$GITHUB_ENV"
fi

log "Done. Output written to $OUTPUT_FILE"
