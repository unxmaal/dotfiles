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
# NOTE: plain compinit (no -C) to mirror the live laptop setup we're testing for
# git-repo tab-completion slowness. If it proves slow, switch to `compinit -C` and
# add a `zstyle ':completion:*' use-cache on` to cache expensive ref completions.
autoload -Uz compinit
compinit
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
