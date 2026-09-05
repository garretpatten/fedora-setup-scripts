# Agent guide — fedora-setup-scripts

Fedora provisioning scripts under `src/scripts/`: Omarchy-style per-app install/config
scripts, orchestrated by `master.sh`, `run-install.sh`, and `run-config.sh`.
`run-install.sh` accepts `cli` (CLI-only) or `all` (CLI + desktop/native); npm
shortcuts are `npm run install:cli`, `npm run install:all`, `npm run config`, and
`npm run all`. The `src/dotfiles` submodule is maintained separately. **Never edit,
commit, or bump `src/dotfiles` from this repo** unless the user explicitly asks.
Consume it read-only via `link_dotfiles_xdg_config_dirs` in `config/dotfiles.sh`
(symlinks each `src/dotfiles/config/<app>/` under `~/.config/`) and targeted file copies.
`run-config.sh` and `master.sh` initialize/update submodules before running config.

## Dotfiles submodule

`src/dotfiles/` is a **Git submodule** pinned to a commit of
[garretpatten/dotfiles](https://github.com/garretpatten/dotfiles).
Never edit files inside `src/dotfiles/` directly in this repository.

If a dotfiles change is needed:

1. Make the change in the `dotfiles` repository and push it.
2. In this repository, update the submodule:
   `cd src/dotfiles && git pull origin master && cd ../..`
3. Commit the submodule pointer change:
   `git add src/dotfiles && git commit -m "Bump dotfiles submodule"`

## Before you finish

**Do not consider shell or workflow work complete until ShellCheck passes the same way CI does.**

From the repository root:

```bash
chmod +x scripts/check-shellcheck.sh
./scripts/check-shellcheck.sh
```

That runs `shellcheck -x` on **changed** `*.sh` / `*.bash` / `*.zsh` files vs `origin/master`
(matching [quality-checks](https://github.com/garretpatten/quality-checks)). Uses
`.shellcheckrc` (`external-sources=true`, `source-path=SCRIPTDIR`).

To lint all setup scripts locally:

```bash
shellcheck -x src/scripts/**/*.sh
# or
find src/scripts -name '*.sh' -print0 | xargs -0 shellcheck -x
```

### ShellCheck conventions

- Leaf scripts under `install/` and `config/` should be plain commands; avoid
  `source utils.sh` and wrapper functions.
- Orchestrators (`master.sh`, `*/all.sh`) source `lib/env.sh`, `lib/run.sh`, and
  `# shellcheck source=...` for any other `lib/*.sh` they use.
- Do not use `A && B || C` for conditional execution (CI reports **SC2015**). Use
  `if` / `then` / `fi` instead.
- `|| true` on a single command is fine for best-effort provisioning.

### Other CI linters

`.github/workflows/quality-checks.yaml` also runs Prettier, markdownlint, and yamllint on
pull requests. Prettier and markdownlint are installed via `npm ci`; yamllint is a Python
tool. Run the relevant tools when you touch those file types:

```bash
npm ci
npx prettier --check .
npx markdownlint --ignore node_modules '**/*.md'
yamllint .
```

### Test workflow

`.github/workflows/test-runner.yaml` runs four jobs on `fedora:latest`:

- `test-cli`: `run-install.sh cli` → `scripts/validate-installs-cli.sh`
- `test-config`: `run-config.sh` → `scripts/validate-config-only.sh`
- `test-full`: `run-install.sh all` → `scripts/validate-installs.sh`
- `test-master`: `master.sh` → `scripts/validate.sh` (full installs + config)

GNOME gsettings scripts no-op without an active GNOME session.

## Layout

| Path                                                        | Role                                                    |
| ----------------------------------------------------------- | ------------------------------------------------------- |
| `src/scripts/lib/env.sh`                                    | `PROJECT_ROOT`, `TEMP_DIR`                              |
| `src/scripts/lib/run.sh`                                    | `run_script` helper (forwards extra args)               |
| `src/scripts/lib/gnome-session.sh`                          | Skip GNOME config when not on GNOME                     |
| `src/scripts/lib/zsh-login.sh`                              | `.zshrc` pass-cli guard for provisioning                |
| `src/scripts/lib/git-submodules.sh`                         | Initialize/update submodules before config              |
| `src/scripts/lib/dnf-packages.sh`                           | `install_dnf_packages_from_file` helper                 |
| `src/scripts/lib/dnf-repo-add.sh`                           | RPM repository/key helpers                              |
| `src/scripts/lib/flatpak-install.sh`                        | Flatpak app install helpers                             |
| `src/scripts/install/all.sh`                                | Full install orchestrator (`--cli` for CLI-only)        |
| `src/scripts/install/cli.sh`                                | Wrapper that runs `install/all.sh --cli`                |
| `src/scripts/install/packages/*.packages`                   | DNF package lists (one per line)                        |
| `src/scripts/install/packages/third-party-cli.packages`     | Docker/NodeSource packages for CLI install              |
| `src/scripts/install/packages/third-party-desktop.packages` | Brave/appindicator packages for full install            |
| `src/scripts/install/apps/pass-cli.sh`                      | Proton Pass CLI binary install                          |
| `src/scripts/install/`                                      | `packages/`, `apps/`, `dev/`, `shell/`, `post-install/` |
| `src/scripts/config/<category>/`                            | Dotfiles/GNOME/system config + `all.sh`                 |
| `scripts/lib/validate-installs-sections.sh`                 | Shared install validation sections                      |
| `scripts/lib/validate-config-sections.sh`                   | Shared config validation sections                       |
| `scripts/validate-installs-cli.sh`                          | Validate CLI-only install outcomes                      |
| `scripts/validate-installs.sh`                              | Validate full install outcomes                          |
| `scripts/validate-config-only.sh`                           | Validate config-only outcomes                           |
| `scripts/validate-config.sh`                                | Validate config after full install/master               |
| `scripts/validate.sh`                                       | Validate installs + config after master                 |

## Product and safety constraints

- Fedora defaults to **firewalld** — `config/security/ufw-rules.sh` disables it before
  **UFW** to match the Ubuntu playbook; verify this aligns with deployments (servers/Kubernetes
  hosts may need divergence).
- **Night Light vs Redshift** conflict remains documented in `README.md`.
- Downloads should continue to funnel through signed/vendor RPM repos or `curl -fsSL`.
- Secrets never belong in-repo; prefer `~/.local_extras`.

## Making changes

| Task                      | Preferred edit                                                          |
| ------------------------- | ----------------------------------------------------------------------- |
| Packages/repos/installers | Matching `install/<category>/<app>.sh` or `install/packages/*.packages` |
| GNOME / timers / sysctl   | `config/system/gnome-gsettings.sh`, `config/system/system-policy.sh`    |
| Firewall                  | `config/security/ufw-rules.sh` plus `install/packages/base.packages`    |
| Dotfile parity            | `config/dev/all.sh`, `config/shell/all.sh`, `config/dotfiles.manifest`  |
| Shared helpers            | `src/scripts/lib/*.sh`                                                  |

## Commits and PRs

Only commit when the user asks explicitly. Mention manual QA on Fedora Workstation when
altering `gsettings`, `firewalld`, COPR repos, or Proton tooling.

## License

MIT — see [LICENSE](./LICENSE).
