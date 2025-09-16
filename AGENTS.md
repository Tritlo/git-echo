# Repository Guidelines

## Project Structure & Module Organization
- `git-echo`: Bash entrypoint that wraps Git with an auxiliary repository under `.git/echo`; keep it portable and dependency-free.
- `tests/run.sh`: Smoke suite that provisions disposable repositories under `/tmp`; extend it when covering new scenarios.
- `.git/echo/*`: Generated at runtime. Never commit or edit these artifacts directly—recreate them via `git echo init`.

## Build, Test, and Development Commands
- `./git-echo help`: Quick reference of available subcommands when developing new behaviour.
- `./tests/run.sh`: Runs the full regression suite; it exits on first failure, so fix order-dependent issues before rerunning.
- `GIT_TRACE=1 ./git-echo <cmd>`: Use tracing to debug forwarded Git invocations without modifying the script.

## Coding Style & Naming Conventions
- Bash 4+ with `set -euo pipefail` is required; maintain defensive checks and explicit `die` paths for user-facing errors.
- Indent with two spaces inside functions and favour lowercase snake_case for helpers; reserve uppercase for exported variables like `PROGRAM_NAME`.
- Keep user messaging consistent with existing `printf` patterns and avoid colour codes for portability.

## Testing Guidelines
- Extend `tests/run.sh` by adding new functions to the `TESTS` array; name them `check_<behaviour>` and rely on the provided `run_test` harness.
- Tests should initialise their own repositories via `create_repo` to stay hermetic and clean up via the shared trap.
- When reproducing regressions, assert on both echo-side (`.git/echo`) and main repo side effects, mirroring current checks.

## Commit & Pull Request Guidelines
- Follow the imperative, concise style seen in history (e.g. `Add tests, CI`). Aim for <60 character summaries with optional detailed body text.
- Reference related issues in the PR description, outline the behavioural change, and document any new configuration flags or files touched.
- Include `./tests/run.sh` output or reproduction commands in the PR to ease verification.

## Security & Operational Notes
- Changes must preserve safeguards that block branch management (`branch`, `checkout`, `switch`) and respect existing config passthrough.
- Treat `.git/echo` as potentially sensitive: never encourage users to commit secrets upstream, and document any new persistence points.
