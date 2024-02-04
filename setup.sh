sudo -v

######################
### System setting ###
######################

######################
#      Finder        #
######################

## Disable the warning when changing a file extension
echo "Disabling the warning when changing a file extension..."
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

## Show path bar, and layout as multi-column
echo "Show path bar, and layout as multi-column..."
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder FXPreferredViewStyle -string clmv

## Show the status bar
echo "Show the status bar..."
defaults write com.apple.finder ShowStatusBar -bool true

## Allow text selection in Quick Look
echo "Allow text selection in Quick Look..."
defaults write com.apple.finder QLEnableTextSelection -bool true

## Search in current folder by default
echo "Search in current folder by default..."
defaults write com.apple.finder FXDefaultSearchScope -string SCcf

######################
#       Safari       #
######################

## Enable Develop Menu, Web Inspector
echo "Enabling Develop Menu, Web Inspector..."
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtras -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" -bool true

######################
#      Disk          #
######################

## Avoid creating .DS_Store files on USB or network volumes
echo "Avoid creating .DS_Store files on USB or network volumes..."
defaults write com.apple.desktopservices dsdontwriteusbstores -bool true
defaults write com.apple.desktopservices dsdontwritenetworkstores -bool true


## Disable disk image verification
echo "Disabling disk image verification..."
defaults write com.apple.frameworks.diskimages skip-verify -bool true
defaults write com.apple.frameworks.diskimages skip-verify-locked -bool true
defaults write com.apple.frameworks.diskimages skip-verify-remote -bool true

######################
#       Others       #
######################

## Expand save panel by default
echo "Expanding save panel by default..."
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

######################
### Other setting ###
######################

## Disable Gatekeeper
sudo spctl --master-disable

# Install Xcode CLI
install_xcode_cli() {
  if test ! $(which xcode-select); then
    echo "Installing Xcode CLI..."
    xcode-select --install
  fi
}
install_xcode_cli

install_homebrew() {
  if test ! $(which brew); then
    echo "Installing Homebrew..."
    /bin/zsh -c "$(curl -fsSL https://gitee.com/cunkai/HomebrewCN/raw/master/Homebrew.sh)"
  fi
}
install_homebrew

# Install packages
install_rcm() {
  if test ! $(which rcup); then
    echo "Installing rcm..."
    brew install rcm
  fi
}
install_rcm

cd
dotfiles() {
  if test ! -d ~/.dotfiles; then
    echo "Cloning dotfiles..."
    git clone git@github.com:wibus-wee/dotfiles.git .dotfiles
    rcup -t base
    mkdir -p .config
    mv .Brewfile Brewfile
  else
    echo "Updating dotfiles..."
    cd ~/.dotfiles
    git pull
  fi
}
dotfiles
brew bundle install

# Install Operator Mono Nerd Font
install_operator_mono_nerd_font() {
  if test ! -f ~/Library/Fonts/OperatorMonoLigNerdFont-Italic.otf; then
    echo "Installing Operator Mono Nerd Font..."
    fonts=https://github.com/wibus-wee-ac/patch-operator-mono-nerd-cron/releases/download/nightly/with-nerd-fonts.zip
    wget -O /tmp/OperatorMono.zip $fonts
    unzip /tmp/OperatorMono.zip -d /tmp
    mv /tmp/out/*.otf ~/Library/Fonts
  fi
}
install_operator_mono_nerd_font

source ~/.zshrc