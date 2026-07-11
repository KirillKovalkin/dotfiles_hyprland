# If not running interactively, don't do anything (leave this at the top of this file)
[[ $- != *i* ]] && return

source "$HOME/.config/bash/rc"

# Personal exports and overrides below.

export ANDROID_HOME="$HOME/.android/Sdk"
export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools"

export JAVA_HOME="/usr/lib/jvm/java-11-openjdk"
export PATH="$PATH:$JAVA_HOME/bin"
