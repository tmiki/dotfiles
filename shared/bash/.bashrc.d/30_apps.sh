# Git
if [ -f /usr/share/bash-completion/completions/git ]; then
    source /usr/share/bash-completion/completions/git
fi

# AWS CLI v2 bash completion
if command -v aws_completer &> /dev/null; then
    complete -C "$(command -v aws_completer)" aws
fi

# nvm Node Version Manager
if [ -d "$HOME/.nvm" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ]          && source "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
fi

# Python venv
if [ -f "$HOME/venv-default/bin/activate" ]; then
    source "$HOME/venv-default/bin/activate"
fi

# direnv
if command -v direnv &> /dev/null; then
    eval "$(direnv hook bash)"
fi
