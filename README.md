# DOTfiles
Different DOT files got bash, zsh, git

## Steps to bootstrap a new System

### 1.  Clone repo into dotfiles directory.
```
git clone git@github.com:divakaran-arrcus/DOTfiles.git ~/dotfiles
```

### 2. Install apps on debian
```
    sudo apt update
    sudo apt install zsh vim tmux neovim stow curl git -y
```

### 3. Install Nerd Fonts
```
#Setup Folder
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts

#Copy the Fonts
cp ~/dotfiles/JetBrainsMonoNerdFont-Regular.ttf ~/.local/share/fonts

#Install the fonts
fc-cache --force

#Verify the fonts have been installed
fc-list | grep "JetBrains"

```

### 4. Install Starship
```
mkdir -p $HOME/.local/bin
curl -sS https://starship.rs/install.sh | sh -s -- -b $HOME/.local/bin -y
```

### 5. Install zinit
```
#Installation
bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"

#Update
zinit update
```

### 6. Create symlinks in the Home directory to the real files in the repo.
```
cp $HOME/.bashrc -i $HOME/.bashrc-old
cp $HOME/.bashrc_USER -i $HOME/.bashrc_USER-old
cp $HOME/.bash_profile -i $HOME/.bash_profile-old
cp $HOME/.zshrc  -i $HOME/.zshrc-old
cp $HOME/.vimrc -i $HOME/.vimrc-old
cp $HOME/.gitconfig -i $HOME/.gitconfig-old
cp $HOME/.tmux.conf -i $HOME/.tmux.conf-old
cp $HOME/.config/starship.toml $HOME/.config/starship-old.toml
cp -r $HOME/.config/nvim -i $HOME/.config/nvim-old
```

```
rm -fv $HOME/.bashrc
rm -fv $HOME/.bashrc_USER
rm -fv $HOME/.bashrc_arrcus
rm -fv $HOME/.bash_profile
rm -fv $HOME/.zshrc
rm -fv $HOME/.zshrc_zinit
rm -fv $HOME/.gitconfig
rm -fv $HOME/.vimrc
rm -fv $HOME/.config/starship.toml
rm -fv $HOME/.config/starship-bash.toml
rm -fv $HOME/.config/starship-zsh.toml
rm -fv $HOME/.tmux.conf
rm -rf $HOME/.config/nvim

```
### If Stow is present
```
stow bash git nvim starship tmux vim zsh
```

### If Stow not present
```
ln -s $HOME/dotfiles/bash/.bashrc $HOME/.bashrc
ln -s $HOME/dotfiles/bash/.bash_profile $HOME/.bash_profile
ln -s $HOME/dotfiles/bash/.bashrc_arrcus $HOME/.bashrc_arrcus
ln -s $HOME/dotfiles/bash/.bashrc_USER $HOME/.bashrc_USER
ln -s $HOME/dotfiles/zsh/.zshrc $HOME/.zshrc
ln -s $HOME/dotfiles/zsh/.zshrc_zinit $HOME/.zshrc_zinit
ln -s $HOME/dotfiles/git/.gitconfig $HOME/.gitconfig
ln -s $HOME/dotfiles/vim/.vimrc $HOME/.vimrc
ln -s $HOME/dotfiles/tmux/.tmux.conf $HOME/.tmux.conf
ln -s $HOME/dotfiles/nvim/.config/nvim $HOME/.config/nvim
ln -s $HOME/dotfiles/starship/.config/starship-zsh.toml $HOME/.config/starship-zsh.toml
ln -s $HOME/dotfiles/starship/.config/starship-bash.toml $HOME/.config/starship-bash.toml
```

### 7. Install Vundle
```
rm -rf ~/.vim

mkdir -p ~/.vim/backup

git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim

vim --clean '+source $HOME/.vimrc' +VundleInstall +qall
```

### 8. Install Homebrew, followed by the software listed in the Brewfile.

```
# Install Brew

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Then pass in the Brewfile location...
brew bundle --file ~/dotfiles/Brewfile

```

```
#List all Installed Applications
brew list [<name>]

#Update all Applications
brew upgrade [<name>]

#Install / Uninstall an Application
brew install <name>
brew uninstall <name>
```

### 9. Neovim
```
# optional but recommended
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim

```

### 10. Tmux

```
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

### 11. Setup python venv

```
python -m venv ~/venv
```

### 12. Reset your .gitconfig with your username and password
```
vim ~/.gitconfig
```

### 13. SSH setup from Mac to Linux
```
Install iterm2
# On Mac
ssh-keygen
ssh-copy-id $USER@<server>

eval `ssh-agent -s`
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
ssh-add -l

# On Linux
eval `ssh-agent -s`
ssh-add ~/.ssh/id_ed25519
ssh-add -l

```

# New Commands replacement for Original unix commands

| Sno | OG Command | New Command  | Functionality                            |
|-----|------------|--------------|------------------------------------------|
| 1   | ls         | lsd, eza     | Color and Icon                           |
| 2   | cat        | bat          | Color                                    |
| 3   | du         | gdu, dust    | gdu has browsing support, dust has graph |
| 4   | top        | htop, btm    | htop has more features, btm is a tui     |
| 5   | grep       | rg(ripgrep)  | speed and color                          |
| 6   | find       | fd           | speed and color                          |
| 7   | ps         | procs        | color and search                         |
| 8   | tree       | broot        | color and collapsing                     |
| 9   | cd         | zoxide       | learns about common folders              |
| 10  | curl       | httpie       | simple and easy                          |
| 11  | man        | batman, tldr | colors in batman, summary in tldr        |
|     |            |              |                                          |


# New functionality commands

| Sno | New Command | Functionality                                              |
|-----|-------------|------------------------------------------------------------|
| 1   | fzf         | Fuzzy Finder                                               |
| 2   | yazi        | A terminal file browser                                    |
| 3   | gping       | A graphical ping                                           |
| 4   | mtr         | traceroute on steroids                                     |
| 5   | tokei       | Get statistics of your code                                |
| 6   | fastfetch   | Fetch specs of your system                                 |
| 7   | onefetch    | Fetch specs of your git repo                               |
| 8   | git-delta   | A syntax-highlighting pager for git, diff, and grep output |
| 9   | jc          | JSONifies the output of many CLI tools                     |
| 10  | jq          | command-line JSON processor                                |
| 11  | jless       | A cli viewer for json                                      |
| 12  | lazygit     | A TUI for git                                              |
| 13  | gitui       | A fast TUI for git                                         |
| 14  | et          | An Eternal terminal instead of ssh                         |
| 15  | autossh     | An auto connecting ssh                                     |
|     |             |                                                            |
