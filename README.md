# bootstrap-laptop-nix

Declarative macOS laptop setup using [nix-darwin](https://github.com/nix-darwin/nix-darwin) and [Home Manager](https://github.com/nix-community/home-manager).

Repository: [github.com/ptran32/bootstrap-laptop-nix](https://github.com/ptran32/bootstrap-laptop-nix)

## Requirements

- macOS on Apple Silicon (`aarch64-darwin`) or Intel (`x86_64-darwin`)
- [Nix](https://nixos.org/download/) with flakes enabled
- Git (the flake must live in a Git repository with tracked files)

## First-time setup on a new Mac

### 1. Install Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Open a **new terminal** so `nix` is on your `PATH`. Verify:

```bash
which nix
nix --version
```

### 2. Enable flakes (required before the first build)

`darwin/default.nix` enables `nix-command` and `flakes`, but that only applies **after** the first successful rebuild. Until then, enable them manually.

`darwin-rebuild` must run with `sudo`, and **root does not read** `~/.config/nix/nix.conf`. Set it system-wide:

```bash
sudo mkdir -p /etc/nix
sudo sh -c 'grep -q experimental-features /etc/nix/nix.conf 2>/dev/null || echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf'
```

Verify:

```bash
cat /etc/nix/nix.conf
```

Optional (for non-`sudo` `nix` commands as your user):

```bash
mkdir -p ~/.config/nix
grep -q 'experimental-features' ~/.config/nix/nix.conf 2>/dev/null || \
  echo 'experimental-features = nix-command flakes' >> ~/.config/nix/nix.conf
```

### 3. Clone the config

```bash
git clone https://github.com/ptran32/bootstrap-laptop-nix.git ~/.config/nix-darwin
cd ~/.config/nix-darwin
```

If `~/.config/nix-darwin` already exists (e.g. from an old copy), remove it first:

```bash
rm -rf ~/.config/nix-darwin
git clone https://github.com/ptran32/bootstrap-laptop-nix.git ~/.config/nix-darwin
cd ~/.config/nix-darwin
```

**Forking or editing locally:** Nix only sees files **tracked by Git** in the flake directory. After you change the config, commit before rebuilding:

```bash
git add .
git commit -m "Describe your change"
```

### 4. Bootstrap nix-darwin (first time only)

`darwin-rebuild` does not exist until nix-darwin has been installed once. Use `nix run` for the **first** switch. System activation must be run as **root** (`sudo`).

Use the `github:` flake URL (not `nix-darwin/nix-darwin#...`, which Nix mis-parses as a git ref):

```bash
cd ~/.config/nix-darwin

# Apple Silicon
sudo nix run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake .#patricetran-mac

# Intel Mac
sudo nix run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake .#patricetran-mac-intel
```

If you still see `experimental Nix feature 'nix-command' is disabled` under `sudo`, confirm `/etc/nix/nix.conf` (step 2), or pass flags explicitly:

```bash
cd ~/.config/nix-darwin
sudo nix --extra-experimental-features 'nix-command flakes' \
  run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake .#patricetran-mac
```

The first build can take several minutes.

### 5. Restart your terminal (required)

**Quit Terminal (or iTerm) and open a new window** — do not only run `source` in the same session. A fresh terminal loads:

- `darwin-rebuild` on your `PATH`
- Home Manager packages (`kubectl`, `bat`, etc.)
- zsh / Oh My Zsh / powerlevel10k from Home Manager

Verify in the **new** terminal:

```bash
which darwin-rebuild
which kubectl
which zsh
echo $SHELL
```

If `darwin-rebuild` is still not found, use the full path once (step 6), then open another new terminal.

### 6. Later rebuilds

After bootstrap, use `darwin-rebuild` directly (with `sudo`) in a **new terminal** (or any terminal opened after a successful switch):

```bash
cd ~/.config/nix-darwin

# Apple Silicon
sudo darwin-rebuild switch --flake .#patricetran-mac

# Intel Mac
sudo darwin-rebuild switch --flake .#patricetran-mac-intel
```

If `sudo` cannot find `darwin-rebuild`, use the full path or bootstrap form again:

```bash
sudo /nix/var/nix/profiles/system/sw/bin/darwin-rebuild switch --flake .#patricetran-mac
```

## Source of truth (git repo)

Edit and commit in **`~/git/bootstrap-laptop-nix`** only. Push to GitHub, then sync into the path nix-darwin uses before rebuilding.

`~/.config/nix-darwin` should be a **clone or symlink** of this repo — not a second copy you edit separately (that causes “dirty git” warnings and drift).

**Recommended — symlink (one directory):**

```bash
rm -rf ~/.config/nix-darwin
ln -sfn ~/git/bootstrap-laptop-nix ~/.config/nix-darwin
```

**Or — separate clone (pull before each rebuild):**

```bash
cd ~/git/bootstrap-laptop-nix
git add -A && git commit -m "..." && git push

cd ~/.config/nix-darwin
git pull
sudo darwin-rebuild switch --flake .#patricetran-mac
```

Commit `flake.lock` with the repo so rebuilds pin the same nixpkgs/home-manager revisions.

## Day-to-day

Edit `home/default.nix` (packages, zsh) or `darwin/default.nix` (system settings) in **`~/git/bootstrap-laptop-nix`**, commit, push, sync `~/.config/nix-darwin` (pull or symlink), then rebuild:

```bash
cd ~/.config/nix-darwin
sudo darwin-rebuild switch --flake .#patricetran-mac
```

Open a **new terminal** after each rebuild if new packages or shell config do not appear in the current session.

Rollback to the previous generation:

```bash
sudo darwin-rebuild --rollback
```

## Layout

| Path | Role |
|------|------|
| `flake.nix` | Flake entrypoint and host definitions |
| `darwin/default.nix` | System config (hostname, default shell, Nix settings) |
| `home/default.nix` | User packages, zsh, fonts, dotfiles |
| `home/vimrc` | Vim configuration deployed to `~/.vimrc` |

## Customize

- **Username**: change `username` in `flake.nix` and `home/default.nix` if not `patricetran`
- **Packages**: edit `home.packages` in `home/default.nix`
- **Shell**: edit `programs.zsh` in `home/default.nix`

## Troubleshooting

### `/etc` files block activation (first successful switch)

If activation fails with `Unexpected files in /etc`, nix-darwin will not overwrite existing files. Rename them, then rebuild:

```bash
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin

cd ~/.config/nix-darwin
sudo nix --extra-experimental-features 'nix-command flakes' \
  run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake .#patricetran-mac
```

After switch, flake settings in `darwin/default.nix` manage `nix-command` / `flakes` (you no longer need the manual `/etc/nix/nix.conf` from step 2). Keep the `.before-nix-darwin` copies as backup until you confirm everything works.

Then **restart your terminal** (step 5) before running `darwin-rebuild` or checking tools like `kubectl`.

| Error | Cause | Fix |
|-------|--------|-----|
| `sudo: darwin-rebuild: command not found` | Old terminal session, or bootstrap not finished | **Open a new terminal** (step 5); if still missing, use step 4 or `/nix/var/nix/profiles/system/sw/bin/darwin-rebuild` |
| `experimental Nix feature 'nix-command' is disabled` (with `sudo`) | Root ignores `~/.config/nix/nix.conf` | Set `/etc/nix/nix.conf` (step 2) or use `--extra-experimental-features` |
| `system activation must now be run as root` | nix-darwin requires `sudo` | Prefix the command with `sudo` |
| `No commit found for SHA: nix-darwin` | Wrong flake URL `nix-darwin/nix-darwin#...` | Use `github:nix-darwin/nix-darwin#darwin-rebuild` |
| `flake.nix` is not tracked by Git | Local dir has `.git` but files uncommitted | `git add . && git commit` in the flake directory |
| `destination path ... already exists` | Old config dir present | `rm -rf ~/.config/nix-darwin` then clone again |
| `Permission denied (publickey)` on clone | SSH key not set up for GitHub | Use HTTPS clone URL (step 3) |
| `attribute 'nerdfonts' missing` | Removed in recent nixpkgs | Use `pkgs.nerd-fonts.<name>` (e.g. `nerd-fonts.meslo-lg`) in `home.packages` |
| `fonts.packages' does not exist` | Removed in recent Home Manager | Put fonts in `home.packages` with `fonts.fontconfig.enable = true` |
| `programs.kubectl' does not exist` | Not a Home Manager module | `kubectl` is in `home.packages`; Oh My Zsh `kubectl` plugin handles completions |
| `mkIf` / "not a function but a set" on `home.homeDirectory` | `home.homeDirectory` must be a string | Do not use `lib.mkIf`; set `users.users.<name>.home` in `darwin/default.nix` instead |
| `home.homeDirectory' is not of type absolute path` (value `null`) | nix-darwin + Home Manager conflict | Set `users.users.<name>.home` in `darwin/default.nix`; omit `home.homeDirectory` in `home/default.nix` |
| `Git tree ... is dirty` | Uncommitted changes in the flake dir | `git add . && git commit` before rebuild (Nix flakes in git repos) |
| `undefined variable 'md5sha1sum'` | Removed from nixpkgs | Use `coreutils` (provides `md5sum` / `sha1sum`) |
| `undefined variable 'colorcat'` | Removed from nixpkgs | Use `bat` (alias `c` → `bat --paging=never`) |
| `undefined variable 'kube-ps1'` | Removed from nixpkgs | powerlevel10k `kubecontext` segment (already in zsh config) |
| `undefined variable 'chtf'` | Removed from nixpkgs | Use `tfenv` for Terraform version switching (`tfenv install`, `tfenv use`) |
| `unfree license ('bsl11')` for `terraform` | HashiCorp BSL | `nixpkgs.config.allowUnfreePredicate` in `darwin/default.nix` (already set for `terraform*`) |
| conflicting subpath `bin/terraform` (tfenv + terraform) | Both packages install `terraform` | Keep only `tfenv`; run `tfenv install latest && tfenv use latest` |
| `Unexpected files in /etc, aborting activation` | Pre-existing `/etc` files (Nix installer, manual `nix.conf`) | Rename them (see below), then rebuild |
| Oh My Zsh `plugin 'copydir' not found` | Renamed in upstream | Use `copypath` |
| Oh My Zsh `plugin 'zsh_reload' not found` | Deprecated; use `omz reload` | Alias `src` → `omz reload` in `home/default.nix` (no plugin) |

## Vim

Plugins (`vim-fugitive`, `gruvbox-community`) are installed via `programs.vim` in `home/default.nix`. Settings live in `home/vimrc` (`termguicolors`, `background=dark`, then `colorscheme gruvbox`).

Optional local overrides: `~/.vim_runtime/my_configs.vim` (sourced if present; not managed by Nix).
