# Source all snippets in ~/.bashrc.d/
if [ -d "$HOME/.bashrc.d" ]; then
    for f in "$HOME/.bashrc.d/"*.sh; do
        [ -r "$f" ] && source "$f"
    done
    unset f
fi
