#!/bin/sh
set -eu

REPO_URL="https://github.com/hermansildnes/vmconfig.git"
INSTALL_DIR="$HOME/vmconfig"

usage() {
  cat <<EOF
Usage:
  bootstrap.sh [--dir <path>]

Examples:
  bootstrap.sh
  bootstrap.sh --dir /path/to/dir
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dir) INSTALL_DIR="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[ -n "${INSTALL_DIR}" ] || { echo "ERROR: --dir requires a path" >&2; exit 2; }

log() { printf "\n==> %s\n" "$*"; }

need_sudo() {
  command -v sudo >/dev/null 2>&1 || { echo "sudo is required." >&2; exit 1; }
  sudo -v
  sudo -n true
}

apt_install() { sudo apt-get install -y --no-install-recommends "$@"; }

log "Checking sudo"
need_sudo

log "Installing prerequisites..."
sudo apt-get update -y
apt_install ca-certificates curl git gpg zsh ripgrep

log "Configuring eza apt repository"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
  | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
  | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
sudo chmod 0644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

log "Installing eza..."
sudo apt-get update -y
apt_install eza

log "Installing latest fzf"
FZF_DIR="$HOME/.fzf"
if [ -d "$FZF_DIR/.git" ]; then
  git -C "$FZF_DIR" pull --ff-only
else
  git clone --depth 1 https://github.com/junegunn/fzf.git "$FZF_DIR"
fi
"$FZF_DIR/install" --bin

log "Installing zoxide..."
if apt-cache show zoxide >/dev/null 2>&1; then
  apt_install zoxide
else
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

log "Installing starship..."
command -v starship >/dev/null 2>&1 || curl -fsSL https://starship.rs/install.sh | sh -s -- --yes

log "Installing znap..."
ZNAP_DIR="$HOME/repos/znap"
if [ ! -r "$ZNAP_DIR/znap.zsh" ]; then
  mkdir -p "$HOME/repos"
  git clone --depth 1 https://github.com/marlonrichert/zsh-snap.git "$ZNAP_DIR"
fi

log "Cloning/updating vmconfig into: $INSTALL_DIR"
if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --ff-only
else
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

log "Symlinking configs"
mkdir -p "$HOME/.config"
[ -f "$INSTALL_DIR/zshrc" ] || { echo "Could not find $INSTALL_DIR/zshrc" >&2; exit 1; }
[ -f "$INSTALL_DIR/starship.toml" ] || { echo "Could not find $INSTALL_DIR/starship.toml" >&2; exit 1; }
ln -sf "$INSTALL_DIR/zshrc" "$HOME/.zshrc"
ln -sf "$INSTALL_DIR/starship.toml" "$HOME/.config/starship.toml"

log "Updating default shell to zsh"
ZSH_PATH="$(command -v zsh)"
[ "${SHELL:-}" = "$ZSH_PATH" ] || chsh -s "$ZSH_PATH" || true

log "Done. Start zsh with: exec zsh"

