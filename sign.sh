ssh_gen() {
  if [ -f ~/.ssh/id_ed25519 ]; then
    echo "The SSH key already exists. Do you want to overwrite it?"
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) break;;
        No ) return;;
      esac
    done
  fi
  echo "Generating a new SSH key for GitHub..."
  ssh-keygen -t ed25519 -C "1596355173@qq.com"

  echo "Starting the ssh-agent in the background..."
  eval "$(ssh-agent -s)"

  touch ~/.ssh/config
  echo "Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519" > ~/.ssh/config
  ssh-add --apple-use-keychain ~/.ssh/id_ed25519

  echo "Copying the SSH key to the clipboard..."
  pbcopy < ~/.ssh/id_ed25519.pub

  echo "The SSH key has been copied to the clipboard. Please add it to your GitHub account."
  echo "Opening the GitHub website..."
  open "https://github.com/settings/keys"
  echo "Please press any key to test the SSH connection..."
  read -n 1 -s -r
  ssh -T git@github.com
}

gpg_gen() {
  # 检查 gpg
  if test ! $(which gpg); then
    echo "Please install GPG first."
    open "https://sourceforge.net/p/gpgosx/docu/Download"
    return
  fi
  if [ -f ~/.gnupg/gpg.conf ]; then
    echo "The GPG key already exists. Do you want to continue?"
    select yn in "Yes" "No"; do
      case $yn in
        Yes ) break;;
        No ) return;;
      esac
    done
  fi
  echo "Generating a new GPG key..."
  gpg --full-generate-key

  echo "Listing the GPG keys..."
  gpg --list-secret-keys --keyid-format LONG

  echo "Copying the GPG key..."
  echo "Please enter the GPG key ID:"
  read gpg_key_id
  gpg --armor --export $gpg_key_id | pbcopy

  echo "The GPG key has been copied to the clipboard. Please add it to your GitHub account."
  echo "Opening the GitHub website..."
  open "https://github.com/settings/keys"
}

ssh_gen
gpg_gen