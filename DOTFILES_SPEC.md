# dotfiles 実装仕様書（Claude Code向け）

## 概要

bash / git / ssh / AWS CLI の設定ファイルを管理する dotfiles リポジトリを構築する。
対応環境は Linux (Ubuntu) と Windows (Git Bash)。
外部ツールへの依存なし。bash と git のみで完結させる。

---

## ディレクトリ構成

```
dotfiles/
├── install.sh
├── backup.sh
├── .gitignore
│
├── shared/                      # git管理・全環境共通
│   └── bash/
│       ├── .profile
│       ├── .bashrc
│       └── .bashrc.d/
│           ├── 10_envvars.sh
│           ├── 20_aliases.sh
│           └── 30_apps.sh
│
├── local/                       # .gitignore対象・環境固有（バックアップから手動配置）
│   ├── git/
│   │   └── .gitkeep
│   ├── ssh/
│   │   └── .gitkeep
│   └── aws/
│       └── .gitkeep
│
└── dotfiles_<hostname>_<epoch>/ # .gitignore対象・backup.sh が生成（例: dotfiles_myhost_1744382400）
    ├── git/
    ├── ssh/
    └── aws/
```

---

## .gitignore

```
local/git/*
!local/git/.gitkeep
local/ssh/*
!local/ssh/.gitkeep
local/aws/*
!local/aws/.gitkeep
dotfiles_*/
```

---

## backup.sh の仕様

### 使い方

```bash
./backup.sh
```

引数なし。現用環境の設定ファイルを `dotfiles_<epoch>/` にコピーする。

### バックアップ先ディレクトリ名のフォーマット

```
dotfiles_<hostname>_<epoch>

例: dotfiles_myhost_1744382400
```

- `hostname`: `hostname` コマンドの出力
- `epoch`: `date +%s` の出力（UNIX エポック秒）
- 生成方法:
  ```bash
  BACKUP_DIR="$DOTFILES_DIR/dotfiles_$(hostname)_$(date +%s)"
  ```

### 処理ステップ（順序厳守）

**Step 1: バックアップ先ディレクトリの作成**

- `dotfiles_<epoch>/git/`
- `dotfiles_<epoch>/ssh/`
- `dotfiles_<epoch>/aws/`

を一括で `mkdir -p` で作成する。

**Step 2: git 設定のコピー**

以下のファイルをコピーする。

- `~/.gitconfig` → `dotfiles_.../git/`

**Step 3: ssh 設定のコピー**

- `~/.ssh/` が存在しない場合は `warn()` を出力してこのステップをスキップ
- 存在する場合は `~/.ssh/` 以下の全ファイル → `dotfiles_.../ssh/`

**Step 4: aws 設定のコピー**

- `~/.aws/` が存在しない場合は `warn()` を出力してこのステップをスキップ
- 存在する場合は `~/.aws/` 以下の全ファイル → `dotfiles_.../aws/`

**Step 5: 完了メッセージ**

バックアップ先ディレクトリの絶対パスを `info()` で出力する。
`local/` への手動配置を促すメッセージも合わせて出力する。

### 実装要件

- スクリプト冒頭に `set -euo pipefail` を設定すること
- `DOTFILES_DIR` をスクリプトの絶対パスから算出すること
  ```bash
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ```
- `install.sh` と同じログ関数（`info()` / `warn()` / `error()`）を定義して使用すること
- Linux / Git Bash (Windows) 両環境で動作すること

---

## install.sh の仕様

### 使い方

```bash
./install.sh
```

引数なし。

### 処理ステップ（順序厳守）

**Step 1: シンボリックリンクチェック**

以下のコピー先がシンボリックリンクであれば、該当対象を「スキップ対象」としてマークし、`warn()` を出力する。
スキップ対象は Step 2 のチェックおよびそれ以降のインストール処理から除外される。

| コピー先 | スキップ対象 |
|---|---|
| `~/.gitconfig` | git |
| `~/.ssh` | ssh |
| `~/.aws` | aws |

**Step 2: ファイル存在確認**

`local/` 以下の各ディレクトリに `.gitkeep` 以外のファイルが存在するか確認する。
Step 1 でスキップ対象となったディレクトリはチェックを省略する。
1つでも欠けていれば、どのディレクトリが未配置かを明示して終了コード1で終了する。

| 確認対象 | 条件 |
|---|---|
| `local/git/` | `.gitkeep` 以外のファイルが1つ以上存在すること |
| `local/ssh/` | `.gitkeep` 以外のファイルが1つ以上存在すること |
| `local/aws/` | `.gitkeep` 以外のファイルが1つ以上存在すること |

**Step 3: bash 設定の追記・コピー**

- `shared/bash/.profile`  → `$HOME/.profile` に追記
- `shared/bash/.bashrc`   → `$HOME/.bashrc` に追記
- `shared/bash/.bashrc.d/` 以下の全ファイル → `$HOME/.bashrc.d/` にコピー
  （ディレクトリが存在しない場合は作成する）

`.profile` と `.bashrc` は上書きではなく追記とする。再実行時に同一内容が重複追記されることは許容する。

**Step 4: git 設定のコピー**（Step 1 でスキップ対象でない場合のみ）

- `local/git/.gitconfig` → `$HOME/.gitconfig`

**Step 5: ssh 設定のコピー**（Step 1 でスキップ対象でない場合のみ）

- `$HOME/.ssh/` が存在しない場合は `mkdir -p` で作成し `chmod 700` を適用
- `local/ssh/` 以下の全ファイル（`.gitkeep` を除く）→ `$HOME/.ssh/`
- コピー後、`$HOME/.ssh/` 以下の全ファイルに `chmod 600` を適用

**Step 6: aws 設定のコピー**（Step 1 でスキップ対象でない場合のみ）

- `$HOME/.aws/` が存在しない場合は `mkdir -p` で作成
- `local/aws/` 以下の全ファイル（`.gitkeep` を除く）→ `$HOME/.aws/`

### 実装要件

- スクリプト冒頭に `set -euo pipefail` を設定すること
- `DOTFILES_DIR` をスクリプトの絶対パスから算出すること
  ```bash
  DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  ```
- ログ出力は以下の関数を定義して使用すること（色付き出力）
  - `info()`  → 緑色  `[INFO]`
  - `warn()`  → 黄色  `[WARN]`
  - `error()` → 赤色  `[ERROR]`
- Step 2 の未配置通知は `warn()`、終了メッセージは `error()` で出力すること
- 各コピー操作の前後に `info()` でログを出すこと
- Linux / Git Bash (Windows) 両環境で動作すること

---

## 各ファイルの内容仕様

### `shared/bash/.profile`

既存の `.profile` が `.bashrc` を読み込む設定を持つことを前提とする。
以下の設定が有効になっていることを想定し、コメントとして記載する（直接実行はしない）。

```bash
# Presume the following setting is already set.
# If that's not set, please make it enabled.
#
# if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
#     source "$HOME/.bashrc"
# fi
```

### `shared/bash/.bashrc`

`~/.bashrc.d/` 以下の `.sh` ファイルをすべて source する。それ以外の設定は書かない。

```bash
# Source all snippets in ~/.bashrc.d/
if [ -d "$HOME/.bashrc.d" ]; then
    for f in "$HOME/.bashrc.d/"*.sh; do
        [ -r "$f" ] && source "$f"
    done
    unset f
fi
```

### `shared/bash/.bashrc.d/10_envvars.sh`

環境変数を定義する。エディタ設定や WSL 向けの表示環境変数（`DISPLAY` / `WAYLAND_DISPLAY` / `XDG_RUNTIME_DIR` 等）を含める。

### `shared/bash/.bashrc.d/20_aliases.sh`

日常的に使う汎用エイリアスを定義する。
`ls` / `history` を中心に、Linux / Git Bash 両対応の内容にすること。

### `shared/bash/.bashrc.d/30_apps.sh`

アプリケーション固有の初期化設定を定義する。
コマンドやディレクトリの存在を `command -v` / `[ -f ]` / `[ -d ]` で確認し、存在する場合のみ初期化する。

含める設定：
- **Git**: bash-completion の読み込み（`/usr/share/bash-completion/completions/git`）
- **AWS CLI v2**: `aws_completer` が存在する場合に bash 補完を有効化
- **nvm**: `~/.nvm` が存在する場合に nvm および bash_completion を読み込む
- **Python venv**: `~/venv-default/bin/activate` が存在する場合に自動 activate
- **direnv**: `direnv` が存在する場合に `direnv hook bash` を eval

---

## 運用フロー（コード生成不要・参考情報）

### 現用マシンでの退避

```bash
./backup.sh
# → dotfiles_<epoch>/ が生成される
# → 当該フォルダを安全な場所に手動でコピーして保管する
```

### 新環境でのセットアップ

```bash
git clone <repository_url> ~/dotfiles
cd ~/dotfiles
# バックアップフォルダから local/git/ local/ssh/ local/aws/ に手動でファイルを配置
./install.sh
```

---

## 動作確認観点（実装後にチェックすること）

**backup.sh**
1. 実行後に `dotfiles_<epoch>/` が生成されている
2. `~/.gitconfig` が `dotfiles_.../git/` にコピーされている
3. `~/.ssh/` 以下のファイルが `dotfiles_.../ssh/` にコピーされている
4. `~/.aws/` 以下のファイルが `dotfiles_.../aws/` にコピーされている
5. `~/.ssh/` が存在しない環境で実行しても `warn()` を出力してスクリプトが継続する

**install.sh**
1. `~/.gitconfig` / `~/.ssh` / `~/.aws` がシンボリックリンクの場合、該当対象のインストールをスキップし `warn()` を出力する
2. シンボリックリンクの対象は `local/` のファイル有無チェックからも除外される
3. `local/` 以下のいずれかが空（`.gitkeep` のみ）の状態で実行すると、該当ディレクトリ名を表示して終了コード1で終了する
4. 全ディレクトリにファイルが揃った状態で実行すると全ステップが完走する
5. `$HOME/.ssh/` 以下にコピーされたファイルのパーミッションが `600` になっている
6. `$HOME/.ssh/` ディレクトリ自体のパーミッションが `700` になっている
7. `$HOME/.bashrc.d/` に `10_envvars.sh`、`20_aliases.sh`、`30_apps.sh` がコピーされている
8. `~/.profile` と `~/.bashrc` に内容が追記されている（上書きではない）
9. 新規シェル起動時に `~/.bashrc.d/` の各スニペットが正常に読み込まれる
