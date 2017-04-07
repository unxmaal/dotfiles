# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH
unset USERNAME

test -r /sw/bin/init.sh && . /sw/bin/init.sh

##
# Your previous /Users/eric/.bash_profile file was backed up as /Users/eric/.bash_profile.macports-saved_2010-01-11_at_08:55:03
##

# MacPorts Installer addition on 2010-01-11_at_08:55:03: adding an appropriate PATH variable for use with MacPorts.
#export PATH=/opt/local/bin:/opt/local/sbin:$PATH
# Finished adapting your PATH environment variable for use with MacPorts.


##
# Your previous /Users/eric/.bash_profile file was backed up as /Users/eric/.bash_profile.macports-saved_2012-07-21_at_10:16:23
##

# MacPorts Installer addition on 2012-07-21_at_10:16:23: adding an appropriate PATH variable for use with MacPorts.
#export PATH=/opt/local/bin:/opt/local/sbin:$PATH
# Finished adapting your PATH environment variable for use with MacPorts.

export WORKON_HOME=~/workspace
export PATH=/usr/local/sbin:$PATH

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

