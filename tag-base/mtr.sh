# mtr.sh - MainTaineR script
echo "🪄 MTR - @wibus-wee"


echo "⌛️ Update .dotfiles"
cd ~/.dotfiles
git fetch
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse @{u})
if [ $LOCAL != $REMOTE ]; then
    git pull
    if [ $? -ne 0 ]; then
      echo "✅ .dotfiles updated"
      echo "🔄 Restarting mtr command"
      mtr
      exit 0
    else
      echo "❌ .dotfiles update failed"
    fi
else
    echo "♾️ .dotfiles is up to date"
fi



echo "⌛️ Update & Upgrade brew"
brew update
brew upgrade
echo "✅ brew updated & upgraded"

echo "⌛️ Clean up brew"
brew cleanup --prune=all
brew autoremove
echo "✅ brew cleaned up"

echo "⌛️ Update & Upgrade Spicetify"
spicetify update
spicetify backup apply