# Global agent instructions

Linked to `~/.claude/AGENTS.md` by home-manager.
Source of truth: `~/nixos-config/home-manager/dotfiles/config/ai-agents/AGENTS.md`.
Project-level `AGENTS.md`/`CLAUDE.md` files override this one.

## Who I am

Developer at Nasjonalbiblioteket (National Library of Norway). Daily stack:
Kotlin and Java (Spring Boot, Maven/Gradle, Kotlin Multiplatform), Apache NiFi
bundles, PostgreSQL, Kubernetes, GCP. Personal machines run NixOS with
home-manager (`~/nixos-config`). Shell is fish.

## Communication

- Reply in the language I write in (Norwegian or English).
- Code, identifiers, comments and commit messages are always in English.
- Be direct and concise. Recommend one option instead of listing all of them.
- When something is done, say how you verified it. If you didn't verify it, say that.

## System: NixOS

If the project has `flake.nix` or `shell.nix`, always run tools through
`nix develop` / `nix-shell` (without `-p`), even if they're installed globally.
Otherwise try the command directly (some tools are installed via home-manager),
and if it's not found, use an ad-hoc shell:

```sh
nix-shell -p maven jdk21 --run "mvn clean install"   # check pom.xml for JDK version
nix-shell -p gradle jdk21 --run "./gradlew build"
nix-shell -p nodejs --run "npm install"
nix-shell -p python3 python3Packages.pip --run "python main.py"
nix-shell -p go --run "go build ./..."
nix-shell -p cargo rustc --run "cargo build"
```

- Never suggest `apt`, `brew`, `pip install --user`, `npm -g` or `curl | sh`.
- To install something permanently, add it to `~/nixos-config` (home-manager),
  don't install it imperatively.
- Files under `~/.config` and `~/.claude` may be symlinks into `~/nixos-config`
  or the read-only Nix store. Edit the source in the repo, not the symlink target.
- Prebuilt binaries usually won't run on NixOS (no FHS). Use the nixpkgs
  package, or `steam-run`/`appimage-run`/`nix-ld` as a last resort.

## Tools and integrations

- GitHub: use the `gh` CLI.
- Jira and Confluence: use the Atlassian MCP.
- Library and framework docs: look them up (Context7 MCP) before writing code
  against an API. Don't guess from memory.
- Nix packages and options: use the NixOS MCP, or search.nixos.org if it isn't available.
- Browser automation: Playwright MCP (uses Nix-built browsers).

## Code

- Match the surrounding code: naming, structure, comment density, idioms.
- Prefer the smallest change that fully solves the task. No speculative
  abstractions, options or "for later" code.
- Fix root causes in shared code instead of patching each caller.
- Kotlin/Spring tests: JUnit 5, MockK/springmockk, Testcontainers for
  integration tests that need a database.
- Run the project's tests and linters before saying something works.

## Git

- Never commit, push, force-push or open PRs unless I ask.
- Don't work on `main` directly when making a PR; branch first.
- Commit messages: imperative subject line, wrapped at 72 characters. Scope prefix where the repo uses one (e.g. `herdr: ...`).

## Data and security (work)

- Never ask for secrets, tokens or connection strings. If you see one, flag it
  and tell me to rotate it.
- Patron data, loan records and user identifiers are personal data under GDPR.
  Use synthetic values in examples, tests and fixtures, never real ones.
- Database dumps and CSV exports in `~` may contain production data. Don't copy
  their contents into code, commits, issues or external services.
- Internal hostnames and system names are non-public. Keep them out of anything shared externally.
- Name the licence when proposing a new third-party dependency or service.
- Don't reproduce substantial parts of copyrighted collection material.
  Metadata and short excerpts are fine.
