<!-- markdownlint-disable MD033 MD041 -->

<p align="center">
    <img
        src="https://img.shields.io/badge/Fedora%20setup%20scripts-reproducible%20automation-294172?style=for-the-badge&logo=fedora&logoColor=white"
        alt="Fedora-branded badge: reproducible workstation automation"
    />
</p>

<h1 align="center">Fedora Setup Scripts</h1>

<p align="center"><strong>Production-style Bash provisioning for standardized developer workstations.</strong></p>

<p align="center">
    Split <strong>install</strong> and <strong>configuration</strong> flows, audited helper patterns, submodule-backed dotfiles, and CI you can anchor release gates on—whether you onboard one laptop or fifty.
</p>

<p align="center">
    <a href="./LICENSE"><img src="https://img.shields.io/github/license/garretpatten/fedora-setup-scripts?style=flat-square" alt="License: MIT" /></a>
    <a href="https://fedoraproject.org/"
        ><img src="https://img.shields.io/badge/platform-Fedora%20Workstation%2038%2B-294172?style=flat-square&logo=fedora&logoColor=white" alt="Fedora Workstation 38 or newer"
    /></a>
    <img src="https://img.shields.io/badge/shell-bash-black?style=flat-square&logo=gnu-bash&logoColor=white" alt="Shell: Bash" />
    <img src="https://img.shields.io/badge/infra-DNF%20%2B%20Flatpak-3C6EB4?style=flat-square&logo=redhat&logoColor=white" alt="Package flows: DNF and Flatpak" />
</p>

<p align="center">
    <a href="https://github.com/garretpatten/fedora-setup-scripts/actions/workflows/test-runner.yaml"
        ><img src="https://img.shields.io/github/actions/workflow/status/garretpatten/fedora-setup-scripts/test-runner.yaml?branch=master&label=Fedora%20CI&logo=github&style=flat-square" alt="Test runner workflow status"
    /></a>
    <a href="https://github.com/garretpatten/fedora-setup-scripts/actions/workflows/quality-checks.yaml"
        ><img src="https://img.shields.io/github/actions/workflow/status/garretpatten/fedora-setup-scripts/quality-checks.yaml?branch=master&label=quality&logo=github&style=flat-square" alt="Quality checks workflow status"
    /></a>
    <a href="https://github.com/garretpatten/fedora-setup-scripts/actions/workflows/security-checks.yaml"
        ><img src="https://img.shields.io/github/actions/workflow/status/garretpatten/fedora-setup-scripts/security-checks.yaml?branch=master&label=security&logo=github&style=flat-square" alt="Security checks workflow status"
    /></a>
</p>

<p align="center">
    ✓ Modular orchestration &nbsp;
    ✓ Split install/config bundles &nbsp;
    ✓ Linted Bash + docs in PR &nbsp;
    ✓ Idempotent, rerunnable phases
</p>

<!-- markdownlint-enable MD033 MD041 -->

---

## Overview

Fedora Setup Scripts automate a **baseline engineering stack**: security tooling,
shells and terminals, development runtimes (Node, Docker, Neovim, and peers), GNOME ergonomics when a
desktop session exists, and a pinned **dotfiles** submodule for editor and tmux parity across
machines. The layout and philosophy mirror [ubuntu-setup-scripts](https://github.com/garretpatten/ubuntu-setup-scripts), with **DNF/RPM** repositories, **Flatpak**, and Fedora-specific paths (e.g. `dnf-automatic`, Brave’s RPM repo, Proton VPN stable RPM, **Ghostty** when Fedora ships it in enabled repos).

## ✨ Features

- **🔧 Automated setup**: Full pass with one command
- **🛡️ Security first**: Tooling, firewall defaults, and guarded downloads
- **⚡ Efficient batching**: Fewer round-trips through DNF metadata where practical
- **🔄 Idempotent**: Safe to rerun; helpers skip first-touch copies when targets exist
- **📝 Centralized errors**: `setup_errors.log` aggregates script noise for triage
- **🎯 Modular design**: Category scripts plus `master.sh`, `run-install.sh`, and `run-config.sh`
- **⚙️ Install vs configuration**: Packages and installers live under `src/scripts/install/`; GNOME
  defaults, `dnf-automatic` timer, home layout, firewall posture, and dotfile copies live under
  `src/scripts/config/`. Use **`npm run installs`**, **`npm run config`**, or **`npm run all`**, or
  invoke runners directly.

## 🚀 Quick Start

### Prerequisites

- Fedora Workstation (GNOME) **38+** recommended; other spins may work with package name drift
- Network access and **sudo**

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/garretpatten/fedora-setup-scripts
cd fedora-setup-scripts
```

1. **Install Node deps** (optional; enables `npm run` shortcuts)

```bash
npm install
```

1. **Update submodules** (for dotfiles)

```bash
git submodule update --init --remote --recursive src/dotfiles/
```

1. **Make scripts executable**

```bash
chmod +x src/scripts/*.sh \
  src/scripts/install/*.sh \
  src/scripts/config/*.sh
```

1. **Run the complete setup**

```bash
npm run all
# or:
./src/scripts/master.sh
```

### npm scripts

| Command            | Runs                                                                                                         |
| ------------------ | ------------------------------------------------------------------------------------------------------------ |
| `npm run all`      | Full provisioning (`master.sh`): installs interleaved with configuration (see execution flow below).         |
| `npm run installs` | Install bundle only (`run-install.sh`): DNF/RPM, Flatpak, third-party installers — no GNOME/dotfiles.        |
| `npm run config`   | Configuration bundle only (`run-config.sh`): defaults, home layout, firewall, submodule copies, shell.       |
| `npm run lint`     | **Prettier**, **markdownlint-cli2**, **yamllint** (local checks; see **[CONTRIBUTING](./CONTRIBUTING.md)**). |

Bash equivalents:

```bash
bash src/scripts/run-install.sh
bash src/scripts/run-config.sh
bash src/scripts/master.sh
```

Use **`npm run config`** when packages are already satisfied but GNOME or dotfiles subtrees should refresh after a submodule bump.

### Granular scripts

Each category exists as **install** and/or **configuration** scripts (paths from repo root):

```bash
bash src/scripts/install/cli.sh
bash src/scripts/install/dev.sh

bash src/scripts/config/system-config.sh       # GNOME + dnf-automatic timer + sysctl + GDM guest hint
bash src/scripts/config/organizeHome.sh
bash src/scripts/config/dev.sh                 # Editors / XDG subtree + Git identity
bash src/scripts/config/security.sh            # Disable firewalld (if present) + UFW posture
bash src/scripts/config/shell.sh               # Submodule shell + terminal configs
```

Prefer the orchestrators so ordering stays predictable (for example **`install/security.sh`** before **`config/security.sh`**, **`install/shell.sh`** before **`config/shell.sh`**, and **`install/post-install.sh`** **docker**/**UFW** hooks before **`config/shell.sh`** in a full pass).

## Project structure

```text
fedora-setup-scripts/
├── src/
│   ├── scripts/
│   │   ├── utils.sh
│   │   ├── master.sh          # Full run — interleaved installs + configuration
│   │   ├── run-install.sh     # DNF/Flatpak/installers/post-install hooks only
│   │   ├── run-config.sh      # GNOME, home layout, firewall policy, dotfiles, shell
│   │   ├── install/
│   │   │   ├── pre-install.sh
│   │   │   ├── cli.sh
│   │   │   ├── media.sh
│   │   │   ├── productivity.sh
│   │   │   ├── dev.sh
│   │   │   ├── security.sh
│   │   │   ├── shell.sh       # Zsh/tmux, Ghostty (Fedora repos), fonts, Oh My Posh
│   │   │   └── post-install.sh
│   │   └── config/
│   │       ├── system-config.sh
│   │       ├── organizeHome.sh
│   │       ├── dev.sh
│   │       ├── security.sh    # Stops firewalld when UFW is configured
│   │       └── shell.sh
│   ├── dotfiles/              # submodule
│   └── assets/
└── ...
```

### Execution flow (`master.sh`)

1. **`install/pre-install.sh`** — DNF refresh/upgrade, toolchain packages, timezone nudge off **UTC**
2. **`config/system-config.sh`** — GNOME defaults when D-Bus/schemas exist; **`dnf-automatic`** timer; GDM **`AllowGuest`** hint; logind + sysctl keepalive drop-in
3. **`config/organizeHome.sh`** — home scaffold and permissions
4. **`install/cli.sh`** — Flatpak/Flathub, CLI stack (**`bat`**, **`eza`**, **`fd`**, **`fastfetch`**, **`btop`**, …)
5. **`install/media.sh`**, **`install/productivity.sh`**
6. **`install/dev.sh`** — NodeSource **24.x** RPM setup, NVM bootstrap, Python, Docker CE RPMs, Neovim,
   **`gh`**, **`shellcheck`**, Postman (**Flatpak**), **`semgrep`**, **`src`** CLI
7. **`config/dev.sh`** — selective copies from **`src/dotfiles/config/`**; Git globals; VS Code `settings.json`
8. **`install/security.sh`** — **UFW**/OpenVPN RPMs, Proton VPN stable repo bootstrap, Proton Pass (**RPM** resolver), Signal & ZAP (**Flatpak**), clones under **`~/Hacking`**
9. **`config/security.sh`** — stop/disable **firewalld** when present, then **UFW** defaults
10. **`install/shell.sh`** — Zsh stack, **`ghostty`** when packaged upstream, Meslo Nerd Font drop, Oh My Posh
11. **`install/post-install.sh`** — DNF maintenance, **docker** group, best-effort **UFW** enable, banner (**`src/assets/fedora.txt`**)
12. **`config/shell.sh`** — **`home/`** dotfiles, **`~/.dotfiles_path`** for **`home/zsh/fedora.zsh`**, **`chsh`** when possible

---

## 📋 What gets installed vs configured

The lists below mirror the **`install/`** and **`config/`** split; open each script for exact commands.

### **`install/` bundle**

#### 🧰 **Bootstrap** (`install/pre-install.sh`)

- DNF upgrade/autoremove housekeeping; **`git`**, **`curl`**, **`wget`**, **`gnupg`**, **`dnf-plugins-core`**, **`unzip`**, **`file`**
- Timezone nudge from **UTC** toward **America/New_York** when unchanged

#### 🛠️ **CLI tools** (`install/cli.sh`)

- Flatpak + Flathub.
- **`bat`**, **`curl`**, **`eza`**, **`fd`**, **`git`**, **`htop`**, **`jq`**, **`ripgrep`**, **`vim-enhanced`**,
  **`wget`**, **`btop`**, **`fastfetch`**

#### 💻 **Development packages** (`install/dev.sh`)

- **Node.js** from NodeSource Fedora setup (**24.x** line), NVM installer when missing,
  **`@vue/cli`** globally when **`npm`** is available, **`python3`** stack, Docker CE **`.repo`**, **`docker-compose-plugin`**, **`neovim`**, **`gh`**, **`shellcheck`**, **`semgrep`** (pip), **`src`** (Sourcegraph), Postman (**Flatpak**)

#### 🎬 **Media** (`install/media.sh`)

Brave (**official RPM repo**), VLC, **ffmpeg-free**/**ffmpeg**, Spotify (**Flatpak** — **RPM Fusion** helps for fuller FFmpeg codecs)

#### 📊 **Productivity** (`install/productivity.sh`)

LibreOffice (component set), Zoom (**Flatpak**), Standard Notes (**Flatpak**), KeePassXC, Redshift,
Flameshot, Balena Etcher AppImage

#### 🔒 **Security packages & payloads** (`install/security.sh`)

- **`ufw`**, **`openvpn`**
- **Proton VPN** stable release RPM + **`proton-vpn-gnome-desktop`** (skipped without **systemd** as PID 1 —
  containers/CI-friendly)
- **Proton Pass** desktop RPM (version.json resolver with fallbacks) + CLI tarball
- Signal (**Flatpak**), **`nmap`**, **`perl-Image-ExifTool`**, OWASP ZAP (**Flatpak**)
- Optional clones **`PayloadsAllTheThings`** / **`SecLists`** under **`~/Hacking`**

#### 🐚 **Shell tooling** (`install/shell.sh`)

Zsh + plugins, **`tmux`**, **`ghostty`** from enabled repos (**[Ghostty install docs](https://ghostty.org/docs/install)** for unsupported releases), Google Noto Emoji + Fira Code fonts, Meslo Nerd Font drop, user Oh My Posh + shared themes when **`/usr/share/oh-my-posh/themes`** is empty

#### 🏁 **Post maintenance** (`install/post-install.sh`)

**`dnf upgrade`** + autoremove, **docker** daemon + group membership, best-effort **`ufw`** enable, completion banner

### **`config/` bundle**

#### 🏠 **Home layout** (`config/organizeHome.sh`)

Same structure as the Ubuntu sibling (`Projects`, `Hacking`, **`AppImages`**, etc.) with sane perms.

#### ⚙️ **Desktop & automatic updates** (`config/system-config.sh`)

- **GNOME** when available (mirrors Ubuntu defaults: dark UI, Nautilus ergonomics, Dash to Dock when installed, Night Light, privacy toggles)
- **`dnf-automatic`** timer enablement (adjust **`/etc/dnf/automatic.conf`** locally if you want download-only vs applied updates)
- **`/etc/gdm/custom.conf`** **`AllowGuest`** hint, logind lid policy, TCP keepalive sysctl drop-in

Minimal/CI runners without GNOME sessions skip **`gsettings`** safely.

#### 💻 **Editor & Git prefs** (`config/dev.sh`)

Selective copies from **`src/dotfiles/config/`** into **`~/.config/`**, VS Code **`settings.json`** seed, first-touch **`~/.gitconfig`**.

#### 🔒 **UFW posture** (`config/security.sh`)

Stops/disables **firewalld** when the unit exists, then **`ufw`** reset/deny-in/allow-out/SSH/enable when **iptables filter** works (minimal containers skip quietly).

#### 🐚 **Shell dotfiles** (`config/shell.sh`)

Ghostty, oh-my-posh, modular tmux tree, **`home/`** files, **`~/.dotfiles_path`**, **`chsh`** best-effort.

**Full symlink mirror** from **`src/dotfiles`**: **`./setup.sh --link-xdg-config`** (see the [dotfiles README](https://github.com/garretpatten/dotfiles/blob/master/README.md)).

## 📊 Monitoring & logs

- **Error log**: `setup_errors.log`
- **Summary** (optional tooling): `setup_summary.txt` — parity hook for future reporting
- Console output uses the same red **[ERROR]** helpers as the Ubuntu project

## ⚠️ Post-installation notes

1. **Re-login** after **docker** group and default shell changes.
1. **GNOME**: some `gsettings` tweaks need an active session.
1. **Firewall**: `config/security.sh` **stops firewalld** to run **UFW** like the Ubuntu twin—if you rely on **firewalld** zones, fork that script.
1. **Night Light vs Redshift**: pick one warm-light policy.
1. **Subscriptions & sign-in**: Brave, Proton, Signal, Spotify, etc. still require user auth.

## 🔍 Troubleshooting

### Permission errors

```bash
chmod +x src/scripts/*.sh src/scripts/install/*.sh src/scripts/config/*.sh
```

### DNF failures

`setup_errors.log` only records **failed** **`dnf`** transactions — normal progress no longer floods the file.

```bash
sudo dnf upgrade --refresh
# then re-run the stage that failed
```

If **Docker CE** metadata vanishes after a distro bump, reinstall **`/etc/yum.repos.d/docker-ce.repo`** from Docker’s Fedora instructions and **`sudo dnf makecache`** again.

### Docker still needs sudo

```bash
newgrp docker
```

### Default shell

```bash
chsh -s "$(command -v zsh)"
```

## 🛡️ Security features

- Hashed/verified downloads via shared helpers
- GPG keys imported for vendor RPM repositories (Brave, Docker CE, NodeSource, Proton VPN)
- Firewall defaults with SSH allowance
- Temporary assets under **`/tmp/fedora-setup-$$`**

## Community

| Resource                                | Use                                         |
| --------------------------------------- | ------------------------------------------- |
| [Code of Conduct](./CODE_OF_CONDUCT.md) | Expected behavior in issues and PRs         |
| [Contributing](./CONTRIBUTING.md)       | Branching, checks, submodule notes          |
| [Security policy](./SECURITY.md)        | Vulnerability reporting (not public issues) |
| [Agent guide](./AGENTS.md)              | Conventions for assistants working in-repo  |

## Maintainers

[@garretpatten](https://github.com/garretpatten/).

Use [issue templates](./.github/ISSUE_TEMPLATE/) for bugs and enhancements.

## License

Licensed under the [MIT License](./LICENSE).
