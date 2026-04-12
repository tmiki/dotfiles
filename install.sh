#!/usr/bin/env bash
set -euo pipefail

# ==============
# 処理ステップ
# 1) コピー先がシンボリックリンクか確認（該当対象はスキップ）
# 2) local/ 以下の各ディレクトリにファイルが揃っているか確認（スキップ対象を除く）
# 3) bash 設定の追記・コピー (.profile, .bashrc は追記 / .bashrc.d/ はコピー)
# 4) git 設定のコピー (local/git/ → $HOME/)
# 5) ssh 設定のコピー (local/ssh/ → $HOME/.ssh/)
# 6) aws 設定のコピー (local/aws/ → $HOME/.aws/)
# ==============

# ------------------------------------------------------------
# Globals
# ------------------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKIP_GIT=false
SKIP_SSH=false
SKIP_AWS=false

# ------------------------------------------------------------
# Utils
# ------------------------------------------------------------
info()  { echo -e "\e[32m[INFO]\e[0m  $*"; }
warn()  { echo -e "\e[33m[WARN]\e[0m  $*"; }
error() { echo -e "\e[31m[ERROR]\e[0m $*"; }

# ------------------------------------------------------------
# Functions
# ------------------------------------------------------------
check_symlinks() {
    if [ -L "$HOME/.gitconfig" ]; then
        warn "$HOME/.gitconfig はシンボリックリンクのためスキップします。"
        SKIP_GIT=true
    fi
    if [ -L "$HOME/.ssh" ]; then
        warn "$HOME/.ssh はシンボリックリンクのためスキップします。"
        SKIP_SSH=true
    fi
    if [ -L "$HOME/.aws" ]; then
        warn "$HOME/.aws はシンボリックリンクのためスキップします。"
        SKIP_AWS=true
    fi
}

check_local_dirs() {
    local missing=()

    # git は .gitconfig の存在を直接確認する
    if [ "$SKIP_GIT" = false ] && [ ! -f "$DOTFILES_DIR/local/git/.gitconfig" ]; then
        missing+=("git")
    fi

    # ssh / aws はファイル名が環境依存のため、.gitkeep 以外のファイルの有無を確認する
    for dir in ssh aws; do
        local skip_var="SKIP_$(echo "$dir" | tr '[:lower:]' '[:upper:]')"
        if [ "${!skip_var}" = true ]; then
            continue
        fi
        local count
        count=$(find "$DOTFILES_DIR/local/$dir" -maxdepth 1 -type f ! -name '.gitkeep' | wc -l)
        if [ "$count" -eq 0 ]; then
            missing+=("$dir")
        fi
    done

    if [ "${#missing[@]}" -gt 0 ]; then
        error "The following directories are empty. Place your config files before running install.sh:"
        for dir in "${missing[@]}"; do
            case "$dir" in
                git) error "  local/git/.gitconfig  ->  ~/.gitconfig" ;;
                ssh) error "  local/ssh/  ->  ~/.ssh/        (e.g. config, id_ed25519, id_ed25519.pub)" ;;
                aws) error "  local/aws/  ->  ~/.aws/        (e.g. credentials, config)" ;;
            esac
        done
        exit 1
    fi
}

install_bash() {
    info "Installing bash config..."
    # .profile / .bashrc は上書きせず追記する
    cat "$DOTFILES_DIR/shared/bash/.profile" >> "$HOME/.profile"
    cat "$DOTFILES_DIR/shared/bash/.bashrc"  >> "$HOME/.bashrc"

    mkdir -p "$HOME/.bashrc.d"
    for f in "$DOTFILES_DIR/shared/bash/.bashrc.d/"*.sh; do
        cp -f "$f" "$HOME/.bashrc.d/"
    done
    info "bash config installed."
}

install_git() {
    info "Installing git config..."
    cp -f "$DOTFILES_DIR/local/git/.gitconfig" "$HOME/.gitconfig"
    info "git config installed."
}

install_ssh() {
    info "Installing ssh config..."
    if [ ! -d "$HOME/.ssh" ]; then
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
    fi
    find "$DOTFILES_DIR/local/ssh" -maxdepth 1 -type f ! -name '.gitkeep' \
        -exec cp -f {} "$HOME/.ssh/" \;
    chmod 600 "$HOME/.ssh/"*
    info "ssh config installed."
}

install_aws() {
    info "Installing aws config..."
    mkdir -p "$HOME/.aws"
    find "$DOTFILES_DIR/local/aws" -maxdepth 1 -type f ! -name '.gitkeep' \
        -exec cp -f {} "$HOME/.aws/" \;
    info "aws config installed."
}

main() {
    check_symlinks
    check_local_dirs
    install_bash
    [ "$SKIP_GIT" = false ] && install_git
    [ "$SKIP_SSH" = false ] && install_ssh
    [ "$SKIP_AWS" = false ] && install_aws
    info "All done! Restart your shell (or run: source ~/.bashrc) to apply changes."
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
main "$@"
