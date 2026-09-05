# ---- Locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ---- Homebrew
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE=TRUE     # don't auto-update on every brew invocation

# ---- Python (uv)
# Migrated off pyenv. uv manages interpreters (`uv python install`) and per-project
# .venv environments. No shell init needed; uv is on PATH via Homebrew.

# ---- Other tool paths
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
export PATH="$HOME/perl5/bin:$PATH"
export PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:$PERL5LIB}"
export PATH="$PATH:$HOME/bin"

# ---- Completions
# compinit -C skips the per-startup compaudit stat-storm + dump rebuild (trusts the
# existing ~/.zcompdump). zcompile turns the dump into bytecode so the FIRST completion
# in a new shell (e.g. `git <TAB>`) loads fast instead of parsing ~400ms of definitions.
# To pick up newly installed completions: rm ~/.zcompdump* && exec zsh
autoload -Uz compinit
compinit -C
if [[ ! -s ~/.zcompdump.zwc || ~/.zcompdump -nt ~/.zcompdump.zwc ]]; then
  zcompile ~/.zcompdump
fi
[ -f ~/.config/zsh/completions/_kubectl ] && source ~/.config/zsh/completions/_kubectl

# ---- Prompt + history
eval "$(starship init zsh)"
# ~/.atuin/bin/env only exists when atuin is installed via its official script;
# Homebrew installs put atuin on PATH directly, so guard the source.
[ -f "$HOME/.atuin/bin/env" ] && . "$HOME/.atuin/bin/env"
eval "$(atuin init zsh --disable-up-arrow)"

# ---- Misc
unalias -a
export CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1

# ---- Model weights
# HF_HOME lives on the Models volume (DockCase C1P, 10 Gbps direct, measured
# 1013 MB/s write / 959 MB/s cold read) because the internal disk runs at 92%
# and a single 70B at 4-bit is ~40GB.
#
# Deliberately NOT guarded by a mount check: /Volumes is root-owned, so if the
# drive is absent huggingface_hub cannot create the directory and fails loudly.
# A silent fallback to ~/.cache/huggingface would re-download tens of GB onto
# the internal disk, which has no room for it.
export HF_HOME=/Volumes/Models/hf

# ---- Local, machine-specific config (kept out of the repo)
# Drop per-machine secrets/paths/aliases in ~/.zshrc_includes. Sourced last so it
# can override anything above. e.g. this machine: source ~/.litellm_env
[ -f ~/.zshrc_includes ] && source ~/.zshrc_includes
# Lima BEGIN
# Make sure iptables and mount.fuse3 are available
PATH="$PATH:/usr/sbin:/sbin"
export PATH
# Lima END
