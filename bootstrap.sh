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

# Parse args
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dir)
      INSTALL_DIR="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [ -z "${INSTALL_DIR}" ]; then
  echo "ERROR: --dir requires a path" >&2
  exit 2
fi

log() { printf "\n==> %s\n" "$*"; }

need_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required." >&2
    exit 1
  fi
  sudo -v
  sudo -n true
}

apt_install() {
  sudo apt-get install -y --no-install-recommends "$@"
}

log "Checking sudo"
need_sudo

log "Installing prerequisites..."
sudo apt-get update -y
apt_install ca-certificates curl git gpg zsh

log "Configuring eza apt repository"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
  | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg

echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
  | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null

sudo chmod 0644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list

log "Installing eza, fzf and ripgrep..."
sudo apt-get update -y
apt_install eza fzf ripgrep

log "Installing zoxide..."
if apt-cache show zoxide >/dev/null 2>&1; then
  apt_install zoxide
else
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

log "Installing starship..."
if ! command -v starship >/dev/null 2>&1; then
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
fi

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

if [ -f "$INSTALL_DIR/zshrc" ]; then
  ln -sf "$INSTALL_DIR/zshrc" "$HOME/.zshrc"
else
  echo "Could not find $INSTALL_DIR/zshrc" >&2
  exit 1
fi

if [ -f "$INSTALL_DIR/starship.toml" ]; then
  ln -sf "$INSTALL_DIR/starship.toml" "$HOME/.config/starship.toml"
else
  echo "Could not find $INSTALL_DIR/starship.toml" >&2
  exit 1
fi

log "Updating default shell to zsh"
ZSH_PATH="$(command -v zsh)"
if [ "${SHELL:-}" != "$ZSH_PATH" ]; then
  chsh -s "$ZSH_PATH" || true
fi

log "Done. Start zsh with: exec zsh"

