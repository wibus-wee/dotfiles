# mtr.sh - MainTaineR script
echo "MainTaineR script - @wibus-wee"

## Update & Upgrade brew
echo "Update & Upgrade brew"
brew update
brew upgrade

## Clean up brew
echo "Clean up brew"
brew cleanup --prune=all
brew autoremove