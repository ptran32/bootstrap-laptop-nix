# bootstrap-laptop-nix

Declarative macOS laptop setup using [nix-darwin](https://github.com/nix-darwin/nix-darwin) and [Home Manager](https://github.com/nix-community/home-manager).

Repository: [github.com/ptran32/bootstrap-laptop-nix](https://github.com/ptran32/bootstrap-laptop-nix)

## Requirements

- macOS Apple Silicon (`aarch64-darwin`) or Intel (`x86_64-darwin`)
- [Nix](https://nixos.org/download/) with flakes
- Git (flake must be a tracked Git repo)

## Workflow (avoid drift)

Edit and commit only in **`~/git/bootstrap-laptop-nix`**. Point nix-darwin at the same directory with a symlink so you never maintain two copies:

```bash
ln -sfn ~/git/bootstrap-laptop-nix ~/.config/nix-darwin
```

```text
~/git/bootstrap-laptop-nix  ←  edit, commit, push
         ↕ (symlink)
~/.config/nix-darwin        ←  darwin-rebuild runs here
```

Commit before rebuilding if the tree is dirty (`git add . && git commit`). Nix flakes in Git repos only see **tracked** files.

## First-time setup

### 1. Install Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Open a **new terminal**, then `which nix`.

### 2. Enable flakes (until first rebuild succeeds)

`darwin-rebuild` uses `sudo`; root does not read `~/.config/nix/nix.conf`. Set system config once:

```bash
sudo mkdir -p /etc/nix
sudo sh -c 'grep -q experimental-features /etc/nix/nix.conf 2>/dev/null || echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf'
```

After the first successful switch, `darwin/default.nix` owns these settings.

### 3. Clone and symlink

```bash
git clone https://github.com/ptran32/bootstrap-laptop-nix.git ~/git/bootstrap-laptop-nix
ln -sfn ~/git/bootstrap-laptop-nix ~/.config/nix-darwin
cd ~/git/bootstrap-laptop-nix
```

If `~/.config/nix-darwin` already exists, remove it first (`rm -rf ~/.config/nix-darwin`), then clone and symlink.

**Already have a separate clone at `~/.config/nix-darwin`?** Move it aside, clone into `~/git`, then symlink as above.

### 4. Bootstrap (first switch only)

`darwin-rebuild` is not on `PATH` yet. Use `github:` (not `nix-darwin/nix-darwin#...`):

```bash
cd ~/.config/nix-darwin

# Apple Silicon
sudo nix run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake .#patricetran-mac

# Intel
sudo nix run github:nix-darwin/nix-darwin#darwin-rebuild -- switch --flake .#patricetran-mac-intel
```

If `nix-command` is disabled under `sudo`, add:

`--extra-experimental-features 'nix-command flakes'`

before `run`. First build can take several minutes.

If activation fails with `Unexpected files in /etc`, rename then retry:

```bash
sudo mv /etc/nix/nix.conf /etc/nix/nix.conf.before-nix-darwin
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
```

### 5. New terminal

Quit Terminal and open a new window (do not only `source` the current session). Then:

```bash
which darwin-rebuild
which kubectl
```

## Day-to-day

```bash
cd ~/git/bootstrap-laptop-nix
# edit home/default.nix or darwin/default.nix
git add -A && git commit -m "..." && git push   # optional

cd ~/.config/nix-darwin
sudo darwin-rebuild switch --flake .#patricetran-mac   # Intel: .#patricetran-mac-intel
```

Open a **new terminal** if packages or shell config do not show up. Rollback: `sudo darwin-rebuild --rollback`.

After bootstrap, install Terraform via tfenv:

```bash
tfenv install latest && tfenv use latest
```

## Layout

| Path | Role |
|------|------|
| `flake.nix` | Flake entrypoint and host definitions |
| `flake.lock` | Pinned inputs (commit with the repo) |
| `darwin/default.nix` | System config (hostname, shell, Nix settings) |
| `home/default.nix` | User packages, zsh, git, vim |
| `home/vimrc` | Extra Vim settings (`programs.vim`) |

## Customize

- **Username**: `username` in `flake.nix` (default `patricetran`)
- **Packages**: `home.packages` in `home/default.nix`
- **Shell / git**: `programs.zsh`, `programs.git` in `home/default.nix`

## Troubleshooting

| Error | Fix |
|-------|-----|
| `sudo: darwin-rebuild: command not found` | Finish step 4, then **new terminal**; or `/nix/var/nix/profiles/system/sw/bin/darwin-rebuild` |
| `nix-command` disabled (with `sudo`) | `/etc/nix/nix.conf` (step 2) or `--extra-experimental-features 'nix-command flakes'` |
| `Unexpected files in /etc` | Rename files (step 4), rebuild |
| `Git tree ... is dirty` | `git commit` in the flake dir |
| `flake.nix` not tracked by Git | `git add . && git commit` |
| `No commit found for SHA: nix-darwin` | Use `github:nix-darwin/nix-darwin#darwin-rebuild` |
| `Author identity unknown` / empty `git config user.*` | Rebuild after symlink; config must match `~/git` (see [Workflow](#workflow-avoid-drift)) |
| `undefined variable` for old packages | Package removed from nixpkgs — update `home/default.nix` (see git history) |
| Oh My Zsh `copydir` / `zsh_reload` not found | Use `copypath`; `src` alias → `omz reload` (no plugin) |

## Vim

Plugins (`vim-fugitive`, `gruvbox-community`) via `programs.vim`. Optional: `~/.vim_runtime/my_configs.vim`.
