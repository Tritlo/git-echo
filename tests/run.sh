#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
GIT_ECHO="$ROOT_DIR/git-echo"

if [[ ! -x "$GIT_ECHO" ]]; then
  echo "git-echo executable not found at $GIT_ECHO" >&2
  exit 1
fi

TMP_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/git-echo-tests.XXXXXX")
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
    git config user.name "Git echo Tests"
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

check_init_creates_echo() {
  local repo
  repo=$(create_repo)
  init_main_repo_with_commit "$repo"
  (
    cd "$repo"
    "$GIT_ECHO" init >/dev/null

    [[ -f .git/echo/HEAD ]] || fail "echo HEAD missing"
    [[ -f .git/echo/config ]] || fail "echo config missing"

    local head_ref
    head_ref=$(git --git-dir=.git/echo symbolic-ref HEAD)
    [[ "$head_ref" == "refs/heads/echo" ]] || fail "unexpected echo HEAD: $head_ref"

    local worktree
    worktree=$(git --git-dir=.git/echo config --get core.worktree)
    [[ "$worktree" == "$repo" ]] || fail "core.worktree not configured correctly"

    grep -q '/tracked.txt$' .git/echo/info/exclude || fail "main tracked files not ignored by echo"
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

    "$GIT_ECHO" init >/dev/null
    "$GIT_ECHO" add secret.txt >/dev/null

    git --git-dir=.git/echo --work-tree=. diff --cached --name-only | grep -qx 'secret.txt' || fail "secret.txt not staged in echo"

    "$GIT_ECHO" commit -m "Add secret" >/dev/null
    git --git-dir=.git/echo --work-tree=. ls-files --error-unmatch secret.txt >/dev/null
  )
}

check_branch_commands_blocked() {
  local repo
  repo=$(create_repo)
  init_main_repo_with_commit "$repo"
  (
    cd "$repo"
    "$GIT_ECHO" init >/dev/null

    local out
    out=$(mktemp "$TMP_ROOT/branch.out.XXXXXX")

    if "$GIT_ECHO" branch >"$out" 2>&1; then
      fail "git echo branch unexpectedly succeeded"
    fi

    grep -q "disabled" "$out" || fail "branch disable message missing"
  )
}

check_commit_updates_main_exclude() {
  local repo
  repo=$(create_repo)
  init_main_repo_with_commit "$repo"
  (
    cd "$repo"
    "$GIT_ECHO" init >/dev/null

    printf 'log\n' > echo.log
    "$GIT_ECHO" add echo.log >/dev/null
    "$GIT_ECHO" commit -m "Track log" >/dev/null

    grep -qx '/echo.log' .git/info/exclude || fail "echo-tracked file missing from main exclude"
  )
}

check_disable_main_exclude_config() {
  local repo
  repo=$(create_repo)
  init_main_repo_with_commit "$repo"
  (
    cd "$repo"
    git config git-echo.exclude-tracked false
    "$GIT_ECHO" init >/dev/null

    printf 'scratch\n' > scratch.txt
    "$GIT_ECHO" add scratch.txt >/dev/null
    "$GIT_ECHO" commit -m "Track scratch" >/dev/null

    if grep -qx '/scratch.txt' .git/info/exclude; then
      fail "echo file unexpectedly excluded when config disabled"
    fi
  )
}

# List of tests to execute.
declare -a TESTS=(
  check_init_creates_echo
  check_add_forces_ignored_files
  check_branch_commands_blocked
  check_commit_updates_main_exclude
  check_disable_main_exclude_config
)

for test in "${TESTS[@]}"; do
  run_test "$test" "$test"
done

echo "All ${#TESTS[@]} tests passed."
