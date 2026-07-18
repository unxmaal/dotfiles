# ---- Locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# ---- Homebrew
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export HOMEBREW_NO_AUTO_UPDATE=TRUE     # don't auto-update on every brew invocation

# ---- pyenv (shims must precede homebrew so pyenv's python wins)
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

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
. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh --disable-up-arrow)"

# ---- Misc
unalias -a
export CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1
