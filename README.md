# Git Twin Utility

`git-twin` provides a lightweight "twin" Git repository stored at `.git/twin`. The
secondary repository shares the primary worktree but is intended to track files
ignored by the main project (personal settings, experiments, etc.).

## Installation

Place `git-twin` somewhere on your `PATH` (or run it via `./git-twin`). Once
available, Git will expose it as the `git twin` subcommand.

## Usage

```bash
git twin init          # initialise the twin repo inside .git/twin
git twin add <file>    # force-add ignored files into the twin repo
git twin status        # inspect the twin repo's status
git twin commit -m ... # commit staged twin changes
git twin log           # view twin history
git twin sync-ignore   # refresh ignore list derived from the main repo
```

Run `git twin` or `git twin help` for the full usage summary.

## Behaviour Highlights

- **Safe initialisation** – `git twin init` creates a bare repository in
  `.git/twin`, sets the worktree to the project root, and pins the default
  branch to `refs/heads/twin`. Core settings such as `core.filemode`,
  `core.autocrlf`, and `core.eol` are copied from the main repository so twin
  obeys the same platform rules.
- **Ignore synchronisation** – Every invocation keeps
  `.git/twin/info/exclude` in sync with the files tracked by the main
  repository. Twin therefore hides main-repo content from status output while
  remaining silent about the files you intentionally manage with the primary
  repository.
- **Force-add convenience** – `git twin add` automatically injects
  `--force` (unless incompatible flags are supplied) so ignored files can be
  staged without extra typing. Interactive/patch modes are left untouched in
  case you know what you are doing.
- **Safety checks** – The script exits on the first failure (`set -euo
  pipefail`) and forbids branch/switch commands under `git twin`, reinforcing
  the single-branch design of the twin repository.

## Recommendations and Caveats

- Keep the twin repository private. If you add a remote, ensure it is secure –
  the whole point is to store files that should stay out of your main history.
- GUI Git clients typically ignore `.git/twin`. Use command line tooling when
  interacting with the twin repository.
- If a file tracked by twin becomes tracked by the main repository, resolve the
  overlap manually. `git twin sync-ignore` can help re-generate the ignore list
  once the main repository settles.
- You can forward any other Git command to the twin repository,
  e.g. `git twin remote add origin <url>`, `git twin push`, etc.

## Development Notes

- The helper rewrites `.git/twin/info/exclude` on demand, so avoid editing the
  file manually. If you need extra ignore patterns, add them through the main
  repository or extend the script.
- Unit tests are not yet included. When extending the tool, consider automating
  the manual sanity checks (initialisation, add/commit of ignored files, force
  add behaviour) described in the review document.
