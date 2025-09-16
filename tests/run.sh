#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GIT_TWIN="$ROOT_DIR/git-twin"

if [[ ! -x "$GIT_TWIN" ]]; then
  echo "git-twin executable not found at $GIT_TWIN" >&2
  exit 1
fi

TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/git-twin-tests.XXXXXX")
cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

fail() {
  local msg="$1"
  echo "FAIL: $msg" >&2
  exit 1
}

create_repo() {
  local repo
  repo=$(mktemp -d "$TMP_ROOT/repo.XXXXXX")
  (
    cd "$repo"
    git init >/dev/null
    git config user.email "test@example.com"
    git config user.name "Git Twin Tests"
  )
  echo "$repo"
}

init_main_repo_with_commit() {
  local repo="$1"
  (
    cd "$repo"
    printf 'tracked file\n' > tracked.txt
    git add tracked.txt
    git commit -m "Initial commit" >/dev/null
  )
}

run_test() {
  local name="$1"
  shift
  printf 'Running %s... ' "$name"
  if "$@"; then
    echo "ok"
  else
    echo "FAILED" >&2
    exit 1
  fi
}

check_init_creates_twin() {
  local repo
  repo=$(create_repo)
  init_main_repo_with_commit "$repo"
  (
    cd "$repo"
    "$GIT_TWIN" init >/dev/null

    [[ -f .git/twin/HEAD ]] || fail "twin HEAD missing"
    [[ -f .git/twin/config ]] || fail "twin config missing"

    local head_ref
    head_ref=$(git --git-dir=.git/twin symbolic-ref HEAD)
    [[ "$head_ref" == "refs/heads/twin" ]] || fail "unexpected twin HEAD: $head_ref"

    local worktree
    worktree=$(git --git-dir=.git/twin config --get core.worktree)
    [[ "$worktree" == "$repo" ]] || fail "core.worktree not configured correctly"

    grep -q '/tracked.txt$' .git/twin/info/exclude || fail "main tracked files not ignored by twin"
  )
}

check_add_forces_ignored_files() {
  local repo
  repo=$(create_repo)
  (
    cd "$repo"
    printf 'secret.txt\n' > .gitignore
    git add .gitignore
    git commit -m "Ignore secret" >/dev/null

    printf 'top secret\n' > secret.txt

    "$GIT_TWIN" init >/dev/null
    "$GIT_TWIN" add secret.txt >/dev/null

    git --git-dir=.git/twin --work-tree=. diff --cached --name-only | grep -qx 'secret.txt' || fail "secret.txt not staged in twin"

    "$GIT_TWIN" commit -m "Add secret" >/dev/null
    git --git-dir=.git/twin --work-tree=. ls-files --error-unmatch secret.txt >/dev/null
  )
}

check_branch_commands_blocked() {
  local repo
  repo=$(create_repo)
  init_main_repo_with_commit "$repo"
  (
    cd "$repo"
    "$GIT_TWIN" init >/dev/null

    local out
    out=$(mktemp "$TMP_ROOT/branch.out.XXXXXX")

    if "$GIT_TWIN" branch >"$out" 2>&1; then
      fail "git twin branch unexpectedly succeeded"
    fi

    grep -q "disabled" "$out" || fail "branch disable message missing"
  )
}

# List of tests to execute.
declare -a TESTS=(
  check_init_creates_twin
  check_add_forces_ignored_files
  check_branch_commands_blocked
)

for test in "${TESTS[@]}"; do
  run_test "$test" "$test"
done

echo "All ${#TESTS[@]} tests passed."
