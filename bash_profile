# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

unset USERNAME

export WORKON_HOME=~/workspace
export PATH=/usr/local/sbin:$PATH:$HOME/bin

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
