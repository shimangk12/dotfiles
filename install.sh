#!/usr/bin/env bash

# This script installs and sets up various dotfiles, programs, and configurations.
set -euo pipefail

# Cleanup function for error handling
cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        show_error "Installation failed with exit code: $exit_code"
        echo ""
        echo "Partial installation may have occurred."
        echo "Check the output above for errors."
        echo "You can try running the script again or use individual commands."
    fi
}

# Set trap to call cleanup on exit
trap cleanup EXIT

# Detect script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"

# Validate dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "ERROR: Dotfiles directory not found: $DOTFILES_DIR" >&2
    exit 1
fi

show_help() {
    cat << 'EOF'
Usage: install.sh [OPTIONS] [COMMAND]

Install and configure dotfiles for development environment

COMMANDS:
    all         Install everything (default)
    program     Install system packages (zsh, vim, tmux, neovim, etc.)
    font        Install and setup fonts
    dotfiles    Symlink dotfiles using stow or manual method
    starship    Install starship prompt
    zinit       Install zinit (zsh plugin manager)
    vundle      Install Vundle (vim plugin manager)
    tpm         Install TPM (tmux plugin manager)
    brew        Install Homebrew and packages from Brewfile
    nvim        Clean and setup neovim directories

OPTIONS:
    -n, --dry-run   Show what would be done without executing
    -f, --force     Skip confirmation prompts (use with caution)
    -h, --help      Show this help message

ENVIRONMENT VARIABLES:
    DOTFILES_DIR    Location of dotfiles (default: script directory)

EXAMPLES:
    # Preview all installations
    ./install.sh --dry-run all
    
    # Only setup dotfiles
    ./install.sh dotfiles
    
    # Install programs on clean Debian system
    ./install.sh program
    
    # Install from custom dotfiles location
    DOTFILES_DIR=/path/to/dotfiles ./install.sh all

REQUIREMENTS:
    - Debian-based system (tested on Debian Bookworm)
    - Internet connection for package downloads
    - sudo access for system package installation

NOTE:
    This script will backup existing dotfiles to *-old before symlinking.
    Destructive operations (removing plugin directories) will ask for confirmation.

EOF
}

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Progress indicator functions
show_progress() {
    local step=$1
    local total=$2
    local message=$3
    echo -e "${BLUE}[$step/$total]${NC} $message"
}

show_success() {
    echo -e "${GREEN}✓${NC} $1"
}

show_error() {
    echo -e "${RED}✗${NC} $1" >&2
}

show_warning() {
    echo -e "${YELLOW}⚠${NC} $1" >&2
}

# Track installation results for summary
declare -a INSTALLED=()
declare -a FAILED=()
declare -a SKIPPED=()

# Check for help flag first
for arg in "$@"; do
    if [[ "$arg" == "--help" || "$arg" == "-h" ]]; then
        show_help
        exit 0
    fi
done

DRYRUN=0
FORCE=0
for arg in "$@"; do
    if [[ "$arg" == "--dry-run" || "$arg" == "-n" ]]; then
        DRYRUN=1
    elif [[ "$arg" == "--force" || "$arg" == "-f" ]]; then
        FORCE=1
    fi
done

# Execute command with dry-run support
# Args:
#   $@: Command and arguments to execute (as string)
# Globals:
#   DRYRUN - if 1, shows command without executing
# Returns:
#   Command exit code, or 0 if dry-run
run_cmd() {
    if [ "$DRYRUN" -eq 1 ]; then
        echo "[DRYRUN] $*"
    else
        bash -c "$*"
    fi
}

# Safely remove directory with user confirmation
# Args:
#   $1: Directory path to remove
#   $2: Description of directory (for prompt)
# Globals:
#   DRYRUN - if 1, shows what would be removed
#   FORCE - if 1, skips confirmation prompts
# Returns:
#   0 on success, 1 if user declined or failed
safe_remove_dir() {
    local dir=$1
    local desc=$2
    
    if [ ! -d "$dir" ]; then
        return 0
    fi
    
    if [ "$DRYRUN" -eq 1 ]; then
        echo "[DRYRUN] Would remove: $dir"
        return 0
    fi
    
    if [ "$FORCE" -eq 0 ]; then
        show_warning "About to remove $desc at: $dir"
        read -p "Continue? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Skipped removal of $dir"
            return 1
        fi
    fi
    
    if rm -rf "$dir"; then
        show_success "Removed: $dir"
        return 0
    else
        show_error "Failed to remove $dir"
        return 1
    fi
}

dotfiles_list=(
    "$HOME/.bashrc"
    "$HOME/.bashrc_USER"
    "$HOME/.bash_profile"
    "$HOME/.bashrc_arrcus"
    "$HOME/.zshrc"
    "$HOME/.zshrc_zinit"
    "$HOME/.vimrc"
    "$HOME/.gitconfig"
    "$HOME/.tmux.conf"
    "$HOME/.config/starship-bash.toml"
    "$HOME/.config/starship-zsh.toml"
    "$HOME/.config/nvim"
)

symlink_files_list=(
    "$DOTFILES_DIR/bash/.bashrc" 
    "$DOTFILES_DIR/bash/.bashrc_USER"
    "$DOTFILES_DIR/bash/.bash_profile"
    "$DOTFILES_DIR/bash/.bashrc_arrcus"
    "$DOTFILES_DIR/zsh/.zshrc"
    "$DOTFILES_DIR/zsh/.zshrc_zinit"
    "$DOTFILES_DIR/vim/.vimrc"
    "$DOTFILES_DIR/git/.gitconfig"
    "$DOTFILES_DIR/tmux/.tmux.conf"
    "$DOTFILES_DIR/starship/.config/starship-bash.toml"
    "$DOTFILES_DIR/starship/.config/starship-zsh.toml"
    "$DOTFILES_DIR/nvim/.config/nvim"
)
# Install system packages using apt-get
# Detects sudo availability and uses it if present
# Installs: zsh, vim, tmux, neovim, stow, curl, git, locales, fontconfig, build-essential
# Globals:
#   DRYRUN
# Returns:
#   0 on success
install_programs() {
    if [ -x "$(command -v apt-get)" ]; then 
        if [ -x "$(command -v sudo)" ]; then
            run_cmd "sudo apt-get update -qq"
            run_cmd "sudo apt-get install -y -qq zsh vim tmux neovim stow curl git locales fontconfig build-essential"
            run_cmd "sudo locale-gen en_US.UTF-8"
            run_cmd "sudo update-locale LANG=en_US.UTF-8"
        else
            run_cmd "apt-get update -qq"
            run_cmd "apt-get install -y -qq zsh vim tmux neovim stow curl git locales fontconfig build-essential"
            run_cmd "locale-gen en_US.UTF-8"
            run_cmd "update-locale LANG=en_US.UTF-8"
        fi
    fi
}

# Setup fonts by copying to user fonts directory and updating font cache
# Requires: fontconfig (fc-cache, fc-list)
# Globals:
#   DOTFILES_DIR, DRYRUN
# Returns:
#   0 on success
setup_fonts() {
    if [ -x "$(command -v fc-cache)" ] && [ -x "$(command -v fc-list)" ]; then
        echo "Setting up Fonts"
        local fonts_dir="$HOME/.local/share/fonts"
        local font_file="$DOTFILES_DIR/JetBrainsMonoNerdFont-Regular.ttf"
        
        run_cmd "mkdir -p \"$fonts_dir\""
        
        if [ -f "$font_file" ]; then
            run_cmd "cp \"$font_file\" \"$fonts_dir/\""
            run_cmd "fc-cache --force"
            run_cmd "fc-list | grep \"JetBrains\""
        else
            echo "Font file not found: $font_file"
        fi
    else
        echo "fc-cache not found, skipping font cache update"
    fi
}

# Backup existing file/directory before removal
# Creates timestamped backup if one already exists
# Args:
#   $1: Source file or directory path
# Globals:
#   DRYRUN
# Returns:
#   0 on success, 1 on failure
backup_and_remove() {
    local src=$1
    local backup="${src}-old"
    
    # Skip if source doesn't exist
    if [ ! -e "$src" ]; then
        return 0
    fi
    
    # Append timestamp if backup already exists
    if [ -e "$backup" ]; then
        backup="${src}-old-$(date +%Y%m%d-%H%M%S)"
        echo "Previous backup exists, using: $(basename "$backup")"
    fi
    
    # Backup with error checking
    if run_cmd "mv -f \"$src\" \"$backup\""; then
        echo "Backed up: $src -> $(basename "$backup")"
    else
        echo "WARNING: Failed to backup $src" >&2
        return 1
    fi
}

# Manually create symlinks for dotfiles (used when stow is not available)
# Uses symlink_files_list and dotfiles_list arrays
# Globals:
#   symlink_files_list, dotfiles_list, DRYRUN
# Returns:
#   0 on success
manual_symlink() {
    for i in "${!symlink_files_list[@]}"; do
        src="${symlink_files_list[$i]}"
        dest="${dotfiles_list[$i]}"
        run_cmd "ln -sf \"$src\" \"$dest\""
    done
}

# Define valid options
readonly VALID_OPTIONS=("program" "font" "dotfiles" "starship" "zinit" "vundle" "tpm" "brew" "nvim" "all")

# Validate if given option is in VALID_OPTIONS array
# Args:
#   $1: Option to validate
# Globals:
#   VALID_OPTIONS
# Returns:
#   0 if valid, 1 if invalid
is_valid_option() {
    local opt=$1
    for valid in "${VALID_OPTIONS[@]}"; do
        if [[ "$opt" == "$valid" ]]; then
            return 0
        fi
    done
    return 1
}

option=""
for arg in "$@"; do
    if [[ "$arg" != "--dry-run" && "$arg" != "-n" ]]; then
        option="$arg"
        break
    fi
done
if [ -z "$option" ]; then
    option="all"
fi

if ! is_valid_option "$option"; then
    echo "ERROR: Invalid option: $option" >&2
    echo "Valid options: ${VALID_OPTIONS[*]}" >&2
    echo "Use --help for more information" >&2
    exit 1
fi

echo "Starting Installation with option: $option"
echo ""

if [ "$option" = "program" ] || [ "$option" = "all" ]; then
    show_progress 1 9 "Installing Programs"
    if install_programs; then
        INSTALLED+=("system packages")
        show_success "System packages installed"
    else
        FAILED+=("system packages")
        show_error "System packages installation failed"
        show_warning "Try running: sudo apt-get update && sudo apt-get install -y zsh vim tmux neovim stow curl git"
    fi
    echo ""
fi

if [ "$option" = "font" ] || [ "$option" = "all" ]; then
    show_progress 2 9 "Setting up Fonts"
    if setup_fonts; then
        INSTALLED+=("fonts")
        show_success "Fonts setup complete"
    else
        FAILED+=("fonts")
        show_error "Font setup failed"
    fi
    echo ""
fi

if [ "$option" = "dotfiles" ] || [ "$option" = "all" ]; then
    show_progress 3 9 "Setting up Dotfiles"
    
    for file in "${dotfiles_list[@]}"; do
        backup_and_remove "$file"
    done

    if [ -x "$(command -v stow)" ]; then
        if run_cmd "stow -d \"$DOTFILES_DIR\" -t \"$HOME\" bash git nvim starship tmux vim zsh"; then
            INSTALLED+=("dotfiles")
            show_success "Dotfiles symlinked with stow"
        else
            FAILED+=("dotfiles")
            show_error "Stow failed"
        fi
    else
        if manual_symlink; then
            INSTALLED+=("dotfiles")
            show_success "Dotfiles symlinked manually"
        else
            FAILED+=("dotfiles")
            show_error "Manual symlink failed"
        fi
    fi
    echo ""
fi

if [ "$option" = "starship" ] || [ "$option" = "all" ]; then
    show_progress 4 9 "Installing Starship"
    if [ -x "$(command -v starship)" ]; then
        SKIPPED+=("starship (already installed)")
        show_success "Starship already installed"
    elif ! [ -x "$(command -v curl)" ]; then
        FAILED+=("starship")
        show_error "curl not found, cannot install Starship"
        show_warning "Install curl first: sudo apt-get install curl"
    else
        run_cmd "mkdir -p \"$HOME/.local/bin\""
        if run_cmd "curl -sS https://starship.rs/install.sh | sh -s -- -b \"$HOME/.local/bin\" -y"; then
            INSTALLED+=("starship")
            show_success "Starship installed to ~/.local/bin"
        else
            FAILED+=("starship")
            show_error "Starship installation failed"
        fi
    fi
    echo ""
fi

if [ "$option" = "zinit" ] || [ "$option" = "all" ]; then
    show_progress 5 9 "Installing Zinit"
    if ! [ -x "$(command -v zsh)" ]; then
        FAILED+=("zinit")
        show_error "zsh not found, cannot install zinit"
        show_warning "Install zsh first: sudo apt-get install zsh"
    elif ! [ -x "$(command -v curl)" ]; then
        FAILED+=("zinit")
        show_error "curl not found, cannot install zinit"
        show_warning "Install curl first: sudo apt-get install curl"
    else
        echo "Installing zinit"
        zinit_dir="$HOME/.local/share/zinit"
        
        if [ "$DRYRUN" -eq 0 ]; then
            # Remove old installation if exists
            if [ -d "$zinit_dir" ]; then
                safe_remove_dir "$zinit_dir" "existing zinit installation"
            fi
            
            # Download and run install script, auto-answer 'n' to modification prompt
            bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)" <<< "n"
            
            # Verify installation
            if [ ! -d "$zinit_dir/zinit.git" ]; then
                FAILED+=("zinit")
                show_error "Zinit installation failed - directory not created"
            else
                INSTALLED+=("zinit")
                show_success "Zinit installed successfully"
                echo "NOTE: Restart your shell or run: exec zsh"
            fi
        else
            if [ -d "$zinit_dir" ]; then
                echo "[DRYRUN] Would remove existing zinit installation: $zinit_dir"
            fi
            echo "[DRYRUN] Would install zinit to $zinit_dir"
        fi
    fi
    echo ""
fi

if [ "$option" = "vundle" ] || [ "$option" = "all" ]; then
    show_progress 6 9 "Installing Vundle"
    if ! [ -x "$(command -v vim)" ]; then
        FAILED+=("vundle")
        show_error "vim not found, cannot install Vundle"
        show_warning "Install vim first: sudo apt-get install vim"
    elif ! [ -x "$(command -v git)" ]; then
        FAILED+=("vundle")
        show_error "git not found, cannot install Vundle"
        show_warning "Install git first: sudo apt-get install git"
    else
        echo "Installing Vundle"
        
        if [ "$DRYRUN" -eq 0 ]; then
            if [ -d "$HOME/.vim" ]; then
                safe_remove_dir "$HOME/.vim" "existing vim plugins and configuration"
            fi
            mkdir -p "$HOME/.vim/backup"
            git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
            vim --clean '+source $HOME/.vimrc' +VundleInstall +qall
            INSTALLED+=("vundle")
            show_success "Vundle and plugins installed"
        else
            if [ -d "$HOME/.vim" ]; then
                echo "[DRYRUN] Would remove existing vim directory: $HOME/.vim"
            fi
            echo "[DRYRUN] Would create $HOME/.vim/backup"
            echo "[DRYRUN] Would clone Vundle to $HOME/.vim/bundle/Vundle.vim"
            echo "[DRYRUN] Would install vim plugins via VundleInstall"
        fi
    fi
    echo ""
fi

if [ "$option" = "nvim" ] || [ "$option" = "all" ]; then
    show_progress 7 9 "Setting up Neovim"
    if ! [ -x "$(command -v nvim)" ]; then
        SKIPPED+=("nvim (not installed)")
        show_warning "nvim not found, skipping nvim setup"
        show_warning "Install neovim first: sudo apt-get install neovim"
    else
        
        if [ "$DRYRUN" -eq 0 ]; then
            safe_remove_dir "$HOME/.local/share/nvim" "nvim data directory"
            safe_remove_dir "$HOME/.local/state/nvim" "nvim state directory"
            safe_remove_dir "$HOME/.cache/nvim" "nvim cache directory"
        else
            [ -d "$HOME/.local/share/nvim" ] && echo "[DRYRUN] Would remove: $HOME/.local/share/nvim"
            [ -d "$HOME/.local/state/nvim" ] && echo "[DRYRUN] Would remove: $HOME/.local/state/nvim"
            [ -d "$HOME/.cache/nvim" ] && echo "[DRYRUN] Would remove: $HOME/.cache/nvim"
            echo "[DRYRUN] Nvim directories would be cleaned"
        fi
        INSTALLED+=("nvim")
        show_success "Neovim directories cleaned"
    fi
    echo ""
fi

if [ "$option" = "tpm" ] || [ "$option" = "all" ]; then
    show_progress 8 9 "Installing TPM"
    if ! [ -x "$(command -v tmux)" ]; then
        FAILED+=("tpm")
        show_error "tmux not found, cannot install TPM"
        show_warning "Install tmux first: sudo apt-get install tmux"
    elif ! [ -x "$(command -v git)" ]; then
        FAILED+=("tpm")
        show_error "git not found, cannot install TPM"
        show_warning "Install git first: sudo apt-get install git"
    else
        
        if [ "$DRYRUN" -eq 0 ]; then
            if [ -d "$HOME/.tmux" ]; then
                safe_remove_dir "$HOME/.tmux" "existing tmux plugins"
            fi
            git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
            INSTALLED+=("tpm")
            show_success "TPM installed to ~/.tmux/plugins/tpm"
        else
            if [ -d "$HOME/.tmux" ]; then
                echo "[DRYRUN] Would remove existing tmux directory: $HOME/.tmux"
            fi
            echo "[DRYRUN] Would clone TPM to $HOME/.tmux/plugins/tpm"
        fi
    fi
    echo ""
fi

if [ "$option" = "brew" ] || [ "$option" = "all" ]; then
    show_progress 9 9 "Installing Homebrew"
    if ! [ -x "$(command -v brew)" ]; then
        if [ "$DRYRUN" -eq 0 ]; then
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            
            # Add brew to PATH for this session
            if [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
                eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
                INSTALLED+=("homebrew")
                show_success "Homebrew installed successfully"
            elif [ -x "/opt/homebrew/bin/brew" ]; then
                eval "$(/opt/homebrew/bin/brew shellenv)"
                INSTALLED+=("homebrew")
                show_success "Homebrew installed successfully"
            else
                FAILED+=("homebrew")
                show_error "Homebrew installation completed but brew command not found"
            fi
        else
            echo "[DRYRUN] Would install Homebrew"
        fi
    else
        SKIPPED+=("homebrew (already installed)")
        show_success "Homebrew already installed"
    fi

    # Install packages from Brewfile
    if [ -x "$(command -v brew)" ]; then
        if [ -f "$DOTFILES_DIR/Brewfile" ]; then
            if run_cmd "brew bundle --file \"$DOTFILES_DIR/Brewfile\""; then
                INSTALLED+=("brew packages")
                show_success "Brew packages installed from Brewfile"
            else
                FAILED+=("brew packages")
                show_error "Brew bundle installation failed"
            fi
        else
            SKIPPED+=("brew packages (no Brewfile)")
            show_warning "Brewfile not found at $DOTFILES_DIR/Brewfile"
        fi
    else
        FAILED+=("brew packages")
        show_error "Brew not found, cannot install packages"
    fi
    echo ""
fi

# L2: Installation Summary
echo ""
echo "======================================"
echo "Installation Summary"
echo "======================================"
echo ""

if [ ${#INSTALLED[@]} -gt 0 ]; then
    show_success "Successfully installed:"
    for item in "${INSTALLED[@]}"; do
        echo "  ✓ $item"
    done
    echo ""
fi

if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo -e "${YELLOW}⊘${NC} Skipped:"
    for item in "${SKIPPED[@]}"; do
        echo "  - $item"
    done
    echo ""
fi

if [ ${#FAILED[@]} -gt 0 ]; then
    show_error "Failed:"
    for item in "${FAILED[@]}"; do
        echo "  ✗ $item"
    done
    echo ""
    echo "Review the errors above and try running the failed components individually."
    echo ""
fi

if [ "$DRYRUN" -eq 0 ]; then
    echo "Next steps:"
    echo "  1. Restart your shell: exec \$SHELL"
    if [ -x "$(command -v nvim)" ]; then
        echo "  2. Open neovim to initialize plugins: nvim"
    fi
    if [ -x "$(command -v tmux)" ]; then
        echo "  3. Start tmux and install plugins: tmux (then prefix + I)"
    fi
    echo ""
fi
