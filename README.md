# Git Echo Utility

<img width="350" alt="image" src="https://github.com/user-attachments/assets/90468c93-ec0d-4ef4-acf3-2bc202b7f628" />


`git-echo` provides a lightweight "echo" Git repository stored at `.git/echo`. The
secondary repository shares the primary worktree but is intended to track files
ignored by the main project (personal settings, experiments, etc.).

## Installation

Place `git-echo` somewhere on your `PATH` (or run it via `./git-echo`). Once
available, Git will expose it as the `git echo` subcommand.

## Usage

```bash
git echo init          # initialise the echo repo inside .git/echo
git echo add <file>    # force-add ignored files into the echo repo
git echo status        # inspect the echo repo's status
git echo commit -m ... # commit staged echo changes
git echo log           # view echo history
git echo sync-ignore   # refresh ignore list derived from the main repo
```

Run `git echo` or `git echo help` for the full usage summary.

## Behaviour Highlights

- **Safe initialisation** – `git echo init` creates a bare repository in
  `.git/echo`, sets the worktree to the project root, and pins the default
  branch to `refs/heads/echo`. Core settings such as `core.filemode`,
  `core.autocrlf`, and `core.eol` are copied from the main repository so echo
  obeys the same platform rules.
- **Ignore synchronisation** – Every invocation keeps
  `.git/echo/info/exclude` in sync with the files tracked by the main
  repository. Echo therefore hides main-repo content from status output while
  remaining silent about the files you intentionally manage with the primary
  repository.
- **Force-add convenience** – `git echo add` automatically injects
  `--force` (unless incompatible flags are supplied) so ignored files can be
  staged without extra typing. Interactive/patch modes are left untouched in
  case you know what you are doing.
- **Safety checks** – The script exits on the first failure (`set -euo
  pipefail`) and forbids branch/switch commands under `git echo`, reinforcing
  the single-branch design of the echo repository.

## Recommendations and Caveats

- Keep the echo repository private. If you add a remote, ensure it is secure –
  the whole point is to store files that should stay out of your main history.
- GUI Git clients typically ignore `.git/echo`. Use command line tooling when
  interacting with the echo repository.
- If a file tracked by echo becomes tracked by the main repository, resolve the
  overlap manually. `git echo sync-ignore` can help re-generate the ignore list
  once the main repository settles.
- You can forward any other Git command to the echo repository,
  e.g. `git echo remote add origin <url>`, `git echo push`, etc.

## Development Notes

- The helper rewrites `.git/echo/info/exclude` on demand, so avoid editing the
  file manually. If you need extra ignore patterns, add them through the main
  repository or extend the script.
- Unit tests are not yet included. When extending the tool, consider automating
  the manual sanity checks (initialisation, add/commit of ignored files, force
  add behaviour) described in the review document.

## Tests

Run the automated smoke tests with:

```bash
./tests/run.sh
```

The script creates throwaway repositories under `/tmp` and validates the
initialisation flow, force-add behaviour, and disabled branch commands.
Continuous integration runs the same suite via GitHub Actions.

## License

Released under the [MIT License](LICENSE). Copyright © 2025
Matthias Pall Gissurarson.
