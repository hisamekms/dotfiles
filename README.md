My dotfiles.

# Installation

```bash
brew install chezmoi
chezmoi init https://github.com/hisamekms/dotfiles.git
chezmoi apply
brew bundle install --file ~/Brewfile

# シェルを再起動してから実施
mise install
```