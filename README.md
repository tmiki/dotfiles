# dotfiles

Personal dotfiles for managing bash, git, ssh, and AWS CLI configuration.
Supports Linux (Ubuntu) and Windows (Git Bash). No external dependencies — bash and git only.

## Repository Structure

```
dotfiles/
├── install.sh               # Install config files to $HOME
├── backup.sh                # Back up current config files
├── shared/                  # Tracked by git — shared across all environments
│   └── bash/
│       ├── .profile
│       ├── .bashrc
│       └── .bashrc.d/
│           ├── 10_envvars.sh
│           ├── 20_aliases.sh
│           └── ...
├── local/                   # Not tracked by git — place environment-specific files here
│   ├── git/                 # Place .gitconfig here
│   ├── ssh/                 # Place ssh config and keys here
│   └── aws/                 # Place credentials and config here
└── dotfiles_<hostname>_<epoch>/  # Created by backup.sh — not tracked by git
```

## Usage

### Setting Up a New Machine

1. Clone this repository:

   ```bash
   git clone <repository_url> ~/dotfiles
   cd ~/dotfiles
   ```

2. Place your environment-specific config files into the `local/` directories:

   | Directory    | Files                              | Destination    |
   |--------------|------------------------------------|----------------|
   | `local/git/` | `.gitconfig`                       | `~/`           |
   | `local/ssh/` | `config`, `id_ed25519`, etc.       | `~/.ssh/`      |
   | `local/aws/` | `credentials`, `config`            | `~/.aws/`      |

3. Run the install script:

   ```bash
   ./install.sh
   ```

4. Reload your shell:

   ```bash
   source ~/.bashrc
   ```

### Backing Up the Current Machine

Run the backup script to copy your current config files into a timestamped directory:

```bash
./backup.sh
```

This creates `dotfiles_<hostname>_<epoch>/` (e.g. `dotfiles_myhost_1744382400/`) containing:

```
dotfiles_<hostname>_<epoch>/
├── git/    # ~/.gitconfig
├── ssh/    # files from ~/.ssh/
└── aws/    # files from ~/.aws/
```

Copy the files you need from the backup directory into `local/` before running `install.sh` on another machine.
