#!/usr/bin/env bash
set -euo pipefail

# ==============
# 処理ステップ
# 1) バックアップ先ディレクトリの作成
# 2) git 設定のコピー (~/.gitconfig)
# 3) ssh 設定のコピー (~/.ssh/ 直下のファイル)
# 4) aws 設定のコピー (~/.aws/ 直下のファイル)
# 5) 完了メッセージの表示
# ==============

# ------------------------------------------------------------
# Globals
# ------------------------------------------------------------
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$DOTFILES_DIR/dotfiles_$(hostname)_$(date +%s)"

# ------------------------------------------------------------
# Utils
# ------------------------------------------------------------
info()  { echo -e "\e[32m[INFO]\e[0m  $*"; }
warn()  { echo -e "\e[33m[WARN]\e[0m  $*"; }
error() { echo -e "\e[31m[ERROR]\e[0m $*"; }

# ------------------------------------------------------------
# Functions
# ------------------------------------------------------------
create_backup_dir() {
    mkdir -p "$BACKUP_DIR/git" "$BACKUP_DIR/ssh" "$BACKUP_DIR/aws"
}

backup_git() {
    if [ ! -f "$HOME/.gitconfig" ]; then
        warn "~/.gitconfig not found, skipping git backup."
        return
    fi
    cp -f "$HOME/.gitconfig" "$BACKUP_DIR/git/.gitconfig"
    info "  ~/.gitconfig  ->  $BACKUP_DIR/git/.gitconfig"
}

backup_ssh() {
    if [ ! -d "$HOME/.ssh" ]; then
        warn "~/.ssh not found, skipping ssh backup."
        return
    fi
    while IFS= read -r f; do
        cp -f "$f" "$BACKUP_DIR/ssh/"
        info "  $f  ->  $BACKUP_DIR/ssh/$(basename "$f")"
    done < <(find "$HOME/.ssh" -maxdepth 1 -type f)
}

backup_aws() {
    if [ ! -d "$HOME/.aws" ]; then
        warn "~/.aws not found, skipping aws backup."
        return
    fi
    while IFS= read -r f; do
        cp -f "$f" "$BACKUP_DIR/aws/"
        info "  $f  ->  $BACKUP_DIR/aws/$(basename "$f")"
    done < <(find "$HOME/.aws" -maxdepth 1 -type f)
}

print_result() {
    info "Backup completed: $BACKUP_DIR"
    info "Next: copy the files you need into local/git/, local/ssh/, local/aws/ before running install.sh"
}

main() {
    create_backup_dir
    backup_git
    backup_ssh
    backup_aws
    print_result
}

# ------------------------------------------------------------
# Main
# ------------------------------------------------------------
main "$@"
