#!/usr/bin/env bash
# One-command Android release to GitHub and Gitee.
#
#   tool/release/release.sh --setup                         # once: store the Gitee token
#   tool/release/release.sh 2.6.2 --notes-file notes.md     # every release
#
# Steps: bump pubspec (build number +1) → commit + annotated tag → analyze,
# test and build (tool/release/build_release_apk.sh) → push main + tag to
# GitHub and Gitee → publish identical artifacts to both
# (tool/release/publish_release.py).
#
# Nothing is pushed until the build and tests pass. Re-running the same
# command resumes: an existing release commit/tag and built artifacts are
# reused, pushes and uploads are idempotent. Pass --rebuild to rebuild.
#
# Tokens: GitHub comes from `gh auth token`; Gitee from GITEE_TOKEN or
# ~/.config/fitnessplan/gitee_token (mode 600, written by --setup). Tokens
# are never printed, passed on a command line or saved in git config.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

GITHUB_REPO="Gryvaen/FitnessPlan"
GITEE_REPO="Gryvaen/FitnessPlan"
BRANCH="main"
# Overridable only to rehearse the flow against local bare repositories.
GITHUB_REMOTE="${RELEASE_GITHUB_REMOTE:-origin}"
GITEE_URL="${RELEASE_GITEE_URL:-https://gitee.com/$GITEE_REPO.git}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fitnessplan"
TOKEN_FILE="$CONFIG_DIR/gitee_token"

die() { echo "error: $*" >&2; exit 1; }
step() { echo; echo "==> $*"; }

usage() {
  sed -n '2,6p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

setup() {
  mkdir -p "$CONFIG_DIR"
  chmod 700 "$CONFIG_DIR"
  echo "Gitee → 设置 → 私人令牌，生成一个勾选 projects 权限的令牌。"
  printf '粘贴 Gitee 令牌后回车（输入不显示）: '
  local token
  IFS= read -rs token
  echo
  [[ -n "$token" ]] || die "empty token"
  # Probe without putting the token on a command line.
  local status
  status="$(curl -sS -o /dev/null -w '%{http_code}' --max-time 30 \
    -K - <<<"url = \"https://gitee.com/api/v5/user?access_token=$token\"")" || status=000
  [[ "$status" == 200 ]] || die "Gitee rejected the token (HTTP $status)"
  (umask 077 && printf '%s' "$token" >"$TOKEN_FILE")
  echo "Saved to $TOKEN_FILE (mode 600)."
}

load_gitee_token() {
  if [[ -z "${GITEE_TOKEN:-}" ]]; then
    [[ -f "$TOKEN_FILE" ]] || die "no Gitee token; run: tool/release/release.sh --setup"
    [[ "$(stat -c %a "$TOKEN_FILE")" == 600 ]] || die "$TOKEN_FILE must be mode 600"
    GITEE_TOKEN="$(<"$TOKEN_FILE")"
  fi
  export GITEE_TOKEN
}

# Push via HTTPS with the token supplied through GIT_ASKPASS, never in a URL.
push_gitee() {
  local askpass status=0
  askpass="$(mktemp)"
  cat >"$askpass" <<'EOF'
#!/bin/sh
case "$1" in
  Username*) printf '%s\n' "$GITEE_USER" ;;
  *) printf '%s\n' "$GITEE_TOKEN" ;;
esac
EOF
  chmod 700 "$askpass"
  GITEE_USER="${GITEE_REPO%%/*}" GIT_ASKPASS="$askpass" GIT_TERMINAL_PROMPT=0 \
    git -c credential.helper= push "$GITEE_URL" "$@" || status=$?
  rm -f "$askpass"
  return "$status"
}

VERSION=""
NOTES=""
REBUILD=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --setup) setup; exit 0 ;;
    --notes-file) NOTES="${2:-}"; shift 2 ;;
    --rebuild) REBUILD=1; shift ;;
    -h|--help) usage 0 ;;
    -*) die "unknown option $1" ;;
    *) [[ -z "$VERSION" ]] || die "unexpected argument $1"; VERSION="$1"; shift ;;
  esac
done
[[ -n "$VERSION" && -n "$NOTES" ]] || usage 1
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "version must look like 2.6.2"
TAG="v$VERSION"
[[ -s "$NOTES" ]] || die "notes file is missing or empty: $NOTES"

step "Preflight"
command -v gh >/dev/null || die "gh CLI is required"
GITHUB_TOKEN="$(gh auth token 2>/dev/null)" || die "gh is not logged in; run: gh auth login"
export GITHUB_TOKEN
load_gitee_token
[[ "$(git branch --show-current)" == "$BRANCH" ]] || die "switch to $BRANCH first"
[[ -z "$(git status --porcelain)" ]] || die "working tree is not clean; commit or stash first"
git fetch -q "$GITHUB_REMOTE" "$BRANCH"
git merge-base --is-ancestor FETCH_HEAD HEAD || die "$BRANCH is behind $GITHUB_REMOTE/$BRANCH; pull first"

# Keep the notes beside the artifacts: re-runs must publish byte-identical notes.
mkdir -p dist
RELEASE_NOTES="dist/release-notes-$TAG.md"
if [[ "$(realpath "$NOTES")" != "$(realpath -m "$RELEASE_NOTES")" ]]; then
  if [[ -f "$RELEASE_NOTES" ]] && ! cmp -s "$NOTES" "$RELEASE_NOTES"; then
    die "$RELEASE_NOTES already exists with different text; edit that file or delete it first"
  fi
  cp "$NOTES" "$RELEASE_NOTES"
fi

current="$(sed -nE 's/^version:[[:space:]]*([0-9.]+)\+([0-9]+).*/\1 \2/p' pubspec.yaml)"
read -r cur_version cur_build <<<"$current"
[[ -n "${cur_build:-}" ]] || die "cannot read version from pubspec.yaml"

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  [[ "$(git rev-parse "$TAG^{commit}")" == "$(git rev-parse HEAD)" ]] \
    || die "tag $TAG exists but is not HEAD"
  [[ "$cur_version" == "$VERSION" ]] || die "tag $TAG exists but pubspec says $cur_version"
  step "Resuming: $TAG already at HEAD ($cur_version+$cur_build)"
else
  newest="$(printf '%s\n%s\n' "$cur_version" "$VERSION" | sort -V | tail -1)"
  [[ "$newest" == "$VERSION" && "$VERSION" != "$cur_version" ]] \
    || die "$VERSION must be newer than $cur_version"
  build=$((cur_build + 1))
  step "Bump $cur_version+$cur_build → $VERSION+$build"
  sed -i -E "s/^version:.*/version: $VERSION+$build/" pubspec.yaml
  git add pubspec.yaml
  git commit -q -m "chore(release): 发布 $VERSION"
  git tag -a "$TAG" -m "Release $TAG"
fi

# Reuse artifacts only when a build of exactly this commit succeeded.
BUILT_MARKER="dist/.built-$TAG"
if [[ "$REBUILD" == 0 && -f "$BUILT_MARKER" && "$(<"$BUILT_MARKER")" == "$(git rev-parse HEAD)" ]]; then
  step "Reusing artifacts already built for $TAG (pass --rebuild to rebuild)"
else
  rm -f "$BUILT_MARKER"
  step "Analyze, test and build"
  tool/release/build_release_apk.sh
  git rev-parse HEAD >"$BUILT_MARKER"
fi

step "Push $BRANCH and $TAG to GitHub"
git push -q "$GITHUB_REMOTE" "$BRANCH" "refs/tags/$TAG"

step "Push $BRANCH and $TAG to Gitee"
push_gitee -q "HEAD:refs/heads/$BRANCH" "refs/tags/$TAG"

step "Clean old Gitee APKs (keep the latest 3 versions, including $TAG)"
python3 tool/release/cleanup_gitee_releases.py --tag "$TAG" --repo "$GITEE_REPO"

step "Publish $TAG to GitHub and Gitee"
python3 tool/release/publish_release.py --tag "$TAG" --notes-file "$RELEASE_NOTES" \
  --github-repo "$GITHUB_REPO" --gitee-repo "$GITEE_REPO" \
  --github-target "$BRANCH" --gitee-target "$BRANCH"

echo
echo "Released $TAG:"
echo "  https://github.com/$GITHUB_REPO/releases/tag/$TAG"
echo "  https://gitee.com/$GITEE_REPO/releases/tag/$TAG"
