ssh_manage() {
  echo "SSH密钥管理工具"
  echo "1. 列出所有SSH密钥"
  echo "2. 删除SSH密钥"
  echo "3. 测试SSH连接"
  echo "4. 查看公钥内容"
  echo "q. 退出"
  
  read -p "请选择操作 [1-4/q]: " choice
  
  case $choice in
    1)
      echo "\n当前的SSH密钥列表："
      ls -l ~/.ssh | grep -E "id_.*$" | grep -v ".pub$"
      echo "\n密钥备注信息："
      grep "# Comment:" ~/.ssh/config 2>/dev/null
      ;;
    2)
      echo "\n可删除的SSH密钥："
      select key in $(ls ~/.ssh | grep -E "id_.*$" | grep -v ".pub$") "取消"; do
        if [ "$key" = "取消" ]; then
          break
        fi
        read -p "确定要删除 $key 吗？(y/n) " confirm
        if [ "$confirm" = "y" ]; then
          rm ~/.ssh/$key ~/.ssh/$key.pub
          sed -i '' "/# Comment:.*$key/d" ~/.ssh/config
          sed -i '' "/IdentityFile.*$key/d" ~/.ssh/config
          ssh-add -d ~/.ssh/$key 2>/dev/null
          echo "已删除 $key"
        fi
        break
      done
      ;;
    3)
      echo "\n选择要测试的服务："
      echo "1. GitHub (git@github.com)"
      echo "2. GitLab (git@gitlab.com)"
      echo "3. 自定义"
      read -p "请选择 [1-3]: " service
      case $service in
        1) ssh -T git@github.com;;
        2) ssh -T git@gitlab.com;;
        3)
          read -p "请输入要测试的SSH地址: " custom_host
          ssh -T $custom_host
          ;;
      esac
      ;;
    4)
      echo "\n选择要查看的公钥："
      select key in $(ls ~/.ssh | grep -E "id_.*\.pub$") "取消"; do
        if [ "$key" = "取消" ]; then
          break
        fi
        echo "\n=== $key 的内容 ==="
        comment=$(grep "# Comment:.*${key%.pub}" ~/.ssh/config 2>/dev/null)
        if [ ! -z "$comment" ]; then
          echo "备注: ${comment#*: }"
        fi
        cat ~/.ssh/$key
        echo "\n"
        read -p "是否要添加/修改备注？(y/n) " add_comment
        if [ "$add_comment" = "y" ]; then
          read -p "请输入备注: " comment_text
          sed -i '' "/# Comment:.*${key%.pub}/d" ~/.ssh/config
          echo " # Comment: ${key%.pub} - $comment_text" >> ~/.ssh/config
          echo "备注已更新"
        fi
        read -p "是否复制到剪贴板？(y/n) " copy
        if [ "$copy" = "y" ]; then
          cat ~/.ssh/$key | pbcopy
          echo "已复制到剪贴板"
        fi
        break
      done
      ;;
    q)
      return
      ;;
    *)
      echo "无效的选择"
      ;;
  esac
}

gpg_manage() {
  echo "GPG 密钥管理工具"
  echo "1. 列出所有 GPG 密钥"
  echo "2. 删除 GPG 密钥"
  echo "3. 导出公钥"
  echo "4. 添加/修改备注"
  echo "q. 退出"

  read -p "请选择操作 [1-4/q]: " choice

  case $choice in
    1)
      echo "\n当前的 GPG 密钥列表："
      gpg --list-secret-keys --keyid-format LONG
      echo "\n密钥备注信息："
      cat ~/.gnupg/comments 2>/dev/null
      ;;
    2)
      echo "\n可删除的 GPG 密钥："
      gpg --list-secret-keys --keyid-format LONG
      read -p "请输入要删除的密钥 ID: " key_id
      read -p "确定要删除 $key_id 吗？(y/n) " confirm
      if [ "$confirm" = "y" ]; then
        gpg --delete-secret-keys $key_id
        gpg --delete-keys $key_id
        sed -i '' "/# GPG Comment:.*$key_id/d" ~/.gnupg/comments 2>/dev/null
        echo "已删除密钥 $key_id"
      fi
      ;;
    3)
      echo "\n选择要导出的密钥："
      gpg --list-secret-keys --keyid-format LONG
      read -p "请输入密钥 ID: " key_id
      gpg --armor --export $key_id | pbcopy
      echo "公钥已复制到剪贴板"
      ;;
    4)
      echo "\n当前的 GPG 密钥："
      gpg --list-secret-keys --keyid-format LONG
      read -p "请输入要添加/修改备注的密钥 ID: " key_id
      read -p "请输入备注: " comment_text
      sed -i '' "/# GPG Comment:.*$key_id/d" ~/.gnupg/comments 2>/dev/null
      echo "# GPG Comment: $key_id - $comment_text" >> ~/.gnupg/comments
      echo "备注已更新"
      ;;
    q)
      return
      ;;
    *)
      echo "无效的选择"
      ;;
  esac
}

ssh_manage
gpg_manage