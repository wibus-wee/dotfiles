#!/bin/bash

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 错误处理函数
error_exit() {
    echo -e "${RED}错误：$1${NC}" >&2
    exit 1
}

# 警告函数
warning() {
    echo -e "${YELLOW}警告：$1${NC}"
}

# 成功提示
success() {
    echo -e "${GREEN}成功：$1${NC}"
}

# 检查是否为 macOS
if [[ "$(uname)" != "Darwin" ]]; then
    error_exit "此脚本仅支持 macOS 系统"
fi

# 检查并刷新 sudo 权限
echo "请输入密码以获取管理员权限..."
if ! sudo -v; then
    error_exit "无法获取管理员权限"
fi

# 保持 sudo 权限
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

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
spctl --master-disable

# Install Xcode CLI
install_xcode_cli() {
  # 检查 Xcode Command Line Tools 是否已安装
  if ! xcode-select --print-path &>/dev/null; then
    echo "Installing Xcode CLI..."
    xcode-select --install
  else
    echo "Xcode CLI already installed at: $(xcode-select --print-path)"
  fi
}
install_xcode_cli

install_homebrew() {
    if test ! $(which brew); then
        echo "正在安装 Homebrew..."
        export HOMEBREW_BREW_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git"
        export HOMEBREW_CORE_GIT_REMOTE="https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git"
        echo "已成功设置 Homebrew 为清华镜像源"
        echo "HOMEBREW_BREW_GIT_REMOTE: $HOMEBREW_BREW_GIT_REMOTE"
        echo "HOMEBREW_CORE_GIT_REMOTE: $HOMEBREW_CORE_GIT_REMOTE"
        
        if ! /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
            error_exit "Homebrew 安装失败"
        fi
        
        warning "请重启终端以应用 Homebrew 更改"
        # 直接退出，不执行后续操作
        # return 0
        exit 0
    fi
    success "Homebrew 已安装"
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
        echo "正在克隆 dotfiles..."
        
        # git clone git@github.com:wibus-wee/dotfiles.git ~/.dotfiles;
        git clone https://github.com/wibus-wee/dotfiles.git ~/.dotfiles;
        # 安全地移动文件
        if [ -f Brewfile ]; then
            warning "Brewfile 已存在，将备份为 Brewfile.backup"
            mv Brewfile Brewfile.backup
        fi
        
        rcup -t base || error_exit "rcup 命令执行失败"
        mkdir -p ~/.config || error_exit "无法创建 .config 目录"
        mv .Brewfile Brewfile || error_exit "无法移动 Brewfile"
    else
        echo "正在更新 dotfiles..."
        cd ~/.dotfiles || error_exit "无法进入 dotfiles 目录"
        git pull || warning "dotfiles 更新失败"
    fi
}
dotfiles

source ~/.zshrc

install_homebrew_packages() {
  if test ! $(which brew); then
    error_exit "未安装 Homebrew"
  fi

  # 如果没安装了 bat，那就是表面还没 bundle install
  if test ! $(which bat); then
    brew bundle install
    echo "安装完成，请重启终端以使用其他配置"
  exit 0
  fi
}
install_homebrew_packages

# Install Operator Mono Nerd Font
install_operator_mono_nerd_font() {
    if test ! -f ~/Library/Fonts/OperatorMonoLigNerdFont-Italic.otf; then
        echo "正在安装 Operator Mono Nerd Font..."
        fonts=https://github.com/wibus-wee-ac/patch-operator-mono-nerd-cron/releases/download/nightly/with-nerd-fonts.zip
        
        # 确保字体目录存在，不存在直接报错
        if [ ! -d ~/Library/Fonts ]; then
            error_exit "无字体目录，系统可能发生什么了？"
        fi
        
        # 创建临时目录
        tmp_dir=$(mktemp -d)
        if [ ! -d "$tmp_dir" ]; then
            error_exit "无法创建临时目录"
        fi
        
        # 下载和解压
        if ! wget -O "$tmp_dir/OperatorMono.zip" $fonts; then
            rm -rf "$tmp_dir"
            error_exit "字体下载失败"
        fi
        
        if ! unzip "$tmp_dir/OperatorMono.zip" -d "$tmp_dir"; then
            rm -rf "$tmp_dir"
            error_exit "字体解压失败"
        }
        
        # 移动字体文件
        if ! mv "$tmp_dir/out/"*.otf ~/Library/Fonts/; then
            rm -rf "$tmp_dir"
            error_exit "无法安装字体文件"
        fi
        
        # 清理临时文件
        rm -rf "$tmp_dir"
        success "字体安装完成"
    fi
}
install_operator_mono_nerd_font

# Install pnpm
install_pnpm() {
    if test ! $(which pnpm); then
        echo "正在安装 pnpm..."
        if ! which npm >/dev/null; then
            error_exit "未找到 npm，请先安装 Node.js"
        fi
        
        if ! npm i -g pnpm; then
            error_exit "pnpm 安装失败"
        fi
        
        if ! pnpm setup; then
            error_exit "pnpm 设置失败"
        fi
        
        success "pnpm 安装完成，请重启终端以使用 pnpm"
    fi
}


source ~/.zshrc

success "所有配置已完成！"