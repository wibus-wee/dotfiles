ssh_gen() {
  local key_name=${1:-"id_ed25519"}  # 默认名称为id_ed25519
  local comment=${2:-"1596355173@qq.com"}  # 默认邮箱
  local key_path="$HOME/.ssh/$key_name"

  if [ -f "$key_path" ]; then
    echo "SSH密钥 $key_name 已存在。是否要覆盖？"
    select yn in "y/是" "n/否"; do
      case $yn in
        "y/是" ) break;;
        "n/否" ) return;;
        * ) echo "请选择 1 或 2";;
      esac
    done
  fi
  
  echo "正在生成新的SSH密钥 $key_name..."
  ssh-keygen -t ed25519 -C "$comment" -f "$key_path"

  echo "Starting the ssh-agent in the background..."
  eval "$(ssh-agent -s)"

  touch ~/.ssh/config
  echo "Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile $key_path" >> ~/.ssh/config
  ssh-add --apple-use-keychain "$key_path"

  echo "Copying the SSH key to the clipboard..."
  pbcopy < "$key_path.pub"

  echo "The SSH key has been copied to the clipboard. Please add it to your GitHub account."
  echo "Opening the GitHub website..."
  open "https://github.com/settings/keys"
  echo "Please press any key to test the SSH connection..."
  read -n 1 -s -r
  ssh -T git@github.com
}

gpg_gen() {
  local comment=${1:-""}  # 添加备注参数
  
  echo "正在生成新的 GPG 密钥..."
  gpg --full-generate-key

  # 获取最新生成的密钥 ID
  local key_id=$(gpg --list-secret-keys --keyid-format LONG | grep sec | tail -n 1 | awk '{print $2}' | cut -d'/' -f2)
  
  # 如果提供了备注，保存到配置文件
  if [ ! -z "$comment" ]; then
    echo "# GPG Comment: $key_id - $comment" >> ~/.gnupg/comments
  fi

  echo "密钥 ID: $key_id 已生成"
  gpg --armor --export $key_id | pbcopy
  echo "公钥已复制到剪贴板"
}

ssh_gen

read -p "请输入 GPG 密钥备注（可选）: " comment
gpg_gen "$comment"