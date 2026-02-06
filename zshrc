# zsh config for VMs

# Download Znap, if it's not there yet.
[[ -r ~/repos/znap/znap.zsh ]] || \
  git clone --depth 1 -- https://github.com/marlonrichert/zsh-snap.git ~/repos/znap
source ~/repos/znap/znap.zsh

znap source zsh-users/zsh-autosuggestions

# Prefer eza if present
if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
fi

# Prefer ripgrep if present
if command -v rg >/dev/null 2>&1; then
  alias grep='rg'
else
  alias grep='grep --color=auto'
fi

alias cp='cp -i'
alias ..='cd ..'

export CLICOLOR=1
export HISTCONTROL=ignoreboth
export TERM=xterm-256color

command -v starship >/dev/null 2>&1 && eval "$(starship init zsh)"
command -v fzf >/dev/null 2>&1 && source <(fzf --zsh)
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh --cmd cd)"

