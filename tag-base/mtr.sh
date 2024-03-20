# mtr.sh - MainTaineR script
echo "🪄 MTR - @wibus-wee"


echo "⌛️ Update .dotfiles"
cd ~/.dotfiles
git pull
echo "✅ .dotfiles updated"


echo "⌛️ Update & Upgrade brew"
brew update
brew upgrade
echo "✅ brew updated & upgraded"

echo "⌛️ Clean up brew"
brew cleanup --prune=all
brew autoremove
echo "✅ brew cleaned up"