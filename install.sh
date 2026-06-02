#!/usr/bin/env bash
# Dashboard Skills installer
# Copies one or more skills into a Claude Code skills directory.
#
# Usage:
#   ./install.sh <skill> [<skill> ...]          # project-level (./.claude/skills)
#   ./install.sh --user <skill> [<skill> ...]   # user-level   (~/.claude/skills)
#   ./install.sh --list                         # list available skills
#   ./install.sh --all                          # install every skill (project-level)
#
# Remote (no clone needed):
#   curl -fsSL https://raw.githubusercontent.com/kitariel/dashboard-skills/main/install.sh | bash -s -- redis-admin-dashboard

set -euo pipefail

REPO="kitariel/dashboard-skills"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
API_BASE="https://api.github.com/repos/${REPO}"

SCOPE="project"
SKILLS=()

# ---- parse args ---------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --user)    SCOPE="user" ;;
    --project) SCOPE="project" ;;
    --list)    SCOPE="list" ;;
    --all)     SKILLS=("__ALL__") ;;
    -h|--help)
      sed -n '2,16p' "$0" 2>/dev/null || echo "See README for usage."
      exit 0 ;;
    --*) echo "Unknown flag: $arg" >&2; exit 1 ;;
    *)   SKILLS+=("$arg") ;;
  esac
done

# ---- locate source: local checkout or remote ---------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"
LOCAL_SKILLS_DIR=""
if [[ -n "$SCRIPT_DIR" && -d "$SCRIPT_DIR/skills" ]]; then
  LOCAL_SKILLS_DIR="$SCRIPT_DIR/skills"
fi

list_remote_skills() {
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "${API_BASE}/contents/skills?ref=${BRANCH}" \
      | grep '"name"' | sed -E 's/.*"name": *"([^"]+)".*/\1/'
  fi
}

available_skills() {
  if [[ -n "$LOCAL_SKILLS_DIR" ]]; then
    find "$LOCAL_SKILLS_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
  else
    list_remote_skills
  fi
}

if [[ "$SCOPE" == "list" ]]; then
  echo "Available dashboard skills:"
  available_skills | sed 's/^/  - /'
  exit 0
fi

if [[ ${#SKILLS[@]} -eq 0 ]]; then
  echo "No skill specified. Available:" >&2
  available_skills | sed 's/^/  - /' >&2
  echo "Run: ./install.sh <skill>  (or --all, --list, --user)" >&2
  exit 1
fi

# expand --all
if [[ "${SKILLS[0]:-}" == "__ALL__" ]]; then
  mapfile -t SKILLS < <(available_skills)
fi

# ---- destination --------------------------------------------------------
if [[ "$SCOPE" == "user" ]]; then
  DEST="${HOME}/.claude/skills"
else
  DEST="$(pwd)/.claude/skills"
fi
mkdir -p "$DEST"

echo "Installing into: $DEST"

# ---- copy / download ----------------------------------------------------
install_local() {
  local skill="$1"
  if [[ ! -d "$LOCAL_SKILLS_DIR/$skill" ]]; then
    echo "  ✗ $skill not found in local checkout" >&2; return 1
  fi
  rm -rf "${DEST:?}/$skill"
  cp -r "$LOCAL_SKILLS_DIR/$skill" "$DEST/$skill"
  echo "  ✓ $skill"
}

download_remote() {
  local skill="$1"
  command -v curl >/dev/null 2>&1 || { echo "curl required for remote install" >&2; exit 1; }
  # Walk the git tree and pull every file under skills/<skill>/
  local tree
  tree="$(curl -fsSL "${API_BASE}/git/trees/${BRANCH}?recursive=1")" || {
    echo "  ✗ could not fetch repo tree" >&2; return 1; }
  local paths
  paths="$(echo "$tree" | grep -oE "\"path\": *\"skills/${skill}/[^\"]+\"" | sed -E 's/.*"(skills\/[^"]+)".*/\1/')"
  if [[ -z "$paths" ]]; then echo "  ✗ $skill not found on remote" >&2; return 1; fi
  while IFS= read -r p; do
    [[ -z "$p" ]] && continue
    local rel="${p#skills/}"
    local out="$DEST/$rel"
    mkdir -p "$(dirname "$out")"
    curl -fsSL "${RAW_BASE}/${p}" -o "$out"
  done <<< "$paths"
  echo "  ✓ $skill"
}

for skill in "${SKILLS[@]}"; do
  if [[ -n "$LOCAL_SKILLS_DIR" ]]; then
    install_local "$skill" || true
  else
    download_remote "$skill" || true
  fi
done

echo
echo "Done. Restart Claude Code (or reload skills) and ask, e.g.:"
echo "  \"Build a Redis key management dashboard for my Next.js app.\""
echo "Tip: also install 'dashboard-foundations' for the shared design system."
