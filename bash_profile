# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

unset USERNAME

export WORKON_HOME=~/workspace
export PATH=/usr/local/sbin:$PATH:$HOME/bin:$HOME/.local/lib/aws/bin

#export PATH="$HOME/.rbenv/bin:$PATH"
#eval "$(rbenv init -)"

#for *BSD/darwin
export CLICOLOR=1

alias ls='ls -G' 

shopt -s histappend
shopt -s cmdhist

HISTFILESIZE=1000000
HISTSIZE=1000000
HISTCONTROL=ignoreboth
HISTIGNORE='ls:bg:fg:history'
HISTTIMEFORMAT='%F %T '
PROMPT_COMMAND='history -a'

if which pyenv-virtualenv-init > /dev/null; then eval "$(pyenv virtualenv-init -)"; fi
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

export PATH=$PATH:/Users/dodde/.cargo/bin
export BASH_SILENCE_DEPRECATION_WARNING=1
