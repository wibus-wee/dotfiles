#!/bin/bash

# 定义颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 错误处理函数
error_exit() {
    echo "${RED}错误：$1${NC}" >&2
    exit 1
}

# 警告函数
warning() {
    echo "${YELLOW}警告：$1${NC}"
}

# 成功提示
success() {
    echo "${GREEN}成功：$1${NC}"
}

ssh_gen() {
    local key_name=${1:-"id_ed25519"}  # 默认名称为id_ed25519
    local comment=${2:-"1596355173@qq.com"}  # 默认邮箱
    local key_path="$HOME/.ssh/$key_name"

    # 检查 .ssh 目录是否存在
    if [ ! -d "$HOME/.ssh" ]; then
        mkdir -p "$HOME/.ssh" || error_exit "无法创建 .ssh 目录"
        chmod 700 "$HOME/.ssh" || warning "无法设置 .ssh 目录权限"
    fi

    if [ -f "$key_path" ]; then
        warning "SSH密钥 $key_name 已存在"
        echo "是否要覆盖？"
        select yn in "y/是" "n/否"; do
            case $yn in
                "y/是" ) break;;
                "n/否" ) return;;
                * ) echo "请选择 1 或 2";;
            esac
        done
    fi
  
    echo "正在生成新的SSH密钥 $key_name..."
    if ! ssh-keygen -t ed25519 -C "$comment" -f "$key_path"; then
        error_exit "SSH密钥生成失败"
    fi

    echo "正在启动 ssh-agent..."
    if ! eval "$(ssh-agent -s)"; then
        error_exit "ssh-agent 启动失败"
    fi

    # 创建或更新 SSH 配置
    if [ ! -f ~/.ssh/config ]; then
        touch ~/.ssh/config || error_exit "无法创建 SSH 配置文件"
        chmod 600 ~/.ssh/config || warning "无法设置 SSH 配置文件权限"
    fi

    # 检查配置是否已存在
    if ! grep -q "Host \*" ~/.ssh/config; then
        echo "Host *
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile $key_path" >> ~/.ssh/config || error_exit "无法更新 SSH 配置"
    fi

    if ! ssh-add --apple-use-keychain "$key_path" 2>/dev/null; then
        warning "无法添加密钥到 keychain，尝试不使用 keychain..."
        if ! ssh-add "$key_path"; then
            error_exit "无法添加 SSH 密钥"
        fi
    fi

    if ! pbcopy < "$key_path.pub"; then
        warning "无法复制 SSH 公钥到剪贴板"
        echo "请手动复制公钥内容："
        cat "$key_path.pub"
    else
        success "SSH 公钥已复制到剪贴板"
    fi

    echo "正在打开 GitHub SSH 密钥设置页面..."
    if ! open "https://github.com/settings/keys"; then
        warning "无法自动打开浏览器，请手动访问 https://github.com/settings/keys"
    fi

    echo "请按任意键测试 SSH 连接..."
    read -n 1 -s -r
    if ! ssh -T git@github.com; then
        warning "SSH 连接测试失败，请检查配置"
    else
        success "SSH 配置成功！"
    fi
}

gpg_gen() {
    local comment=${1:-""}  # 添加备注参数
  
    # 检查 GPG 是否已安装
    if ! command -v gpg &> /dev/null; then
        error_exit "GPG 未安装，请先安装 GPG"
    fi

    echo "正在生成新的 GPG 密钥..."
    if ! gpg --full-generate-key; then
        error_exit "GPG 密钥生成失败"
    fi

    # 获取最新生成的密钥 ID
    local key_id=$(gpg --list-secret-keys --keyid-format LONG | grep sec | tail -n 1 | awk '{print $2}' | cut -d'/' -f2)
    
    if [ -z "$key_id" ]; then
        error_exit "无法获取 GPG 密钥 ID"
    fi
    
    # 确保 .gnupg 目录存在
    if [ ! -d ~/.gnupg ]; then
        mkdir -p ~/.gnupg || error_exit "无法创建 .gnupg 目录"
        chmod 700 ~/.gnupg || warning "无法设置 .gnupg 目录权限"
    fi

    # 如果提供了备注，保存到配置文件
    if [ ! -z "$comment" ]; then
        echo "# GPG Comment: $key_id - $comment" >> ~/.gnupg/comments || warning "无法保存 GPG 备注"
    fi

    success "密钥 ID: $key_id 已生成"
    
    if ! gpg --armor --export $key_id | pbcopy; then
        warning "无法复制 GPG 公钥到剪贴板"
        echo "请手动复制以下公钥内容："
        gpg --armor --export $key_id
    else
        success "GPG 公钥已复制到剪贴板"
    fi
}

export_keys() {
    local export_dir=${1:-"$HOME/key_backup"}
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="$export_dir/keys_backup_$timestamp"

    # 创建备份目录
    mkdir -p "$backup_dir" || error_exit "无法创建备份目录"
    chmod 700 "$backup_dir" || warning "无法设置备份目录权限"

    echo "=== 开始导出密钥 ==="
    
    # 导出 SSH 密钥
    if [ -d "$HOME/.ssh" ]; then
        echo "正在导出 SSH 密钥..."
        mkdir -p "$backup_dir/ssh"
        # 导出所有 SSH 密钥和配置
        cp -r "$HOME/.ssh/"* "$backup_dir/ssh/" || warning "SSH 密钥导出可能不完整"
        chmod 600 "$backup_dir/ssh/"* 2>/dev/null
        success "SSH 密钥已导出"
    fi

    # 导出 GPG 密钥
    if command -v gpg &> /dev/null; then
        echo "正在导出 GPG 密钥..."
        mkdir -p "$backup_dir/gpg"
        
        # 导出公钥
        gpg --armor --export > "$backup_dir/gpg/public_keys.asc" || warning "GPG 公钥导出失败"
        
        # 导出私钥
        gpg --armor --export-secret-keys > "$backup_dir/gpg/private_keys.asc" || warning "GPG 私钥导出失败"
        
        # 导出信任数据库
        gpg --export-ownertrust > "$backup_dir/gpg/trust_db.txt" || warning "GPG 信任数据库导出失败"
        
        chmod 600 "$backup_dir/gpg/"*
        success "GPG 密钥已导出"
    fi

    # 创建说明文件
    cat > "$backup_dir/README.txt" << EOF
密钥备份说明
============
备份时间: $(date)

SSH 密钥位置: ./ssh/
GPG 密钥位置: ./gpg/

导入说明:
1. SSH 密钥: 将 ssh 目录下的文件复制到 ~/.ssh/ 目录
2. GPG 密钥:
   - 导入公钥: gpg --import ./gpg/public_keys.asc
   - 导入私钥: gpg --import ./gpg/private_keys.asc
   - 导入信任: gpg --import-ownertrust ./gpg/trust_db.txt
EOF

    # 创建压缩包
    local archive_name="keys_backup_$timestamp.tar.gz"
    tar -czf "$export_dir/$archive_name" -C "$export_dir" "keys_backup_$timestamp" || error_exit "创建备份压缩包失败"
    
    # 设置压缩包权限
    chmod 600 "$export_dir/$archive_name" || warning "无法设置备份文件权限"
    
    # 清理临时文件
    rm -rf "$backup_dir"
    
    success "密钥已导出到: $export_dir/$archive_name"
}

import_keys() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        error_exit "请指定备份文件路径"
    fi
    
    if [ ! -f "$backup_file" ]; then
        error_exit "备份文件不存在"
    fi

    echo "=== 开始导入密钥 ==="
    
    # 创建临时目录
    local tmp_dir=$(mktemp -d)
    trap 'rm -rf "$tmp_dir"' EXIT
    
    # 解压备份文件
    tar -xzf "$backup_file" -C "$tmp_dir" || error_exit "解压备份文件失败"
    
    # 获取解压后的目录名
    local backup_dir=$(find "$tmp_dir" -maxdepth 1 -type d -name "keys_backup_*" | head -n1)
    
    if [ -z "$backup_dir" ]; then
        error_exit "无效的备份文件格式"
    fi

    # 导入 SSH 密钥
    if [ -d "$backup_dir/ssh" ]; then
        echo "正在导入 SSH 密钥..."
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        
        # 备份现有的 SSH 配置
        if [ -d "$HOME/.ssh" ]; then
            local ssh_backup="$HOME/.ssh_backup_$(date +%Y%m%d_%H%M%S)"
            mv "$HOME/.ssh" "$ssh_backup" || warning "无法备份现有 SSH 配置"
            success "已备份现有 SSH 配置到: $ssh_backup"
        fi
        
        # 复制新的 SSH 密钥
        cp -r "$backup_dir/ssh/"* "$HOME/.ssh/" || error_exit "SSH 密钥导入失败"
        chmod 600 "$HOME/.ssh/"* 2>/dev/null
        chmod 700 "$HOME/.ssh"
        success "SSH 密钥已导入"
    fi

    # 导入 GPG 密钥
    if [ -d "$backup_dir/gpg" ]; then
        echo "正在导入 GPG 密钥..."
        
        # 导入公钥
        if [ -f "$backup_dir/gpg/public_keys.asc" ]; then
            gpg --import "$backup_dir/gpg/public_keys.asc" || warning "GPG 公钥导入失败"
        fi
        
        # 导入私钥
        if [ -f "$backup_dir/gpg/private_keys.asc" ]; then
            gpg --import "$backup_dir/gpg/private_keys.asc" || warning "GPG 私钥导入失败"
        fi
        
        # 导入信任数据库
        if [ -f "$backup_dir/gpg/trust_db.txt" ]; then
            gpg --import-ownertrust "$backup_dir/gpg/trust_db.txt" || warning "GPG 信任数据库导入失败"
        fi
        
        success "GPG 密钥已导入"

        # 测试 GPG 密钥
        gpg --list-secret-keys
        gpg --list-public-keys
        echo "Test" | gpg --clearsign > test.asc
        gpg --verify test.asc
    fi

    success "密钥导入完成！"
}

# 在主程序部分添加新的选项
echo "请选择操作："
select operation in "生成新密钥" "导出密钥" "导入密钥" "退出"; do
    case $operation in
        "生成新密钥")
            echo "=== 开始配置 SSH 密钥 ==="
            ssh_gen
            echo "\n=== 开始配置 GPG 密钥 ==="
            read -p "请输入 GPG 密钥备注（可选）: " comment
            gpg_gen "$comment"
            break
            ;;
        "导出密钥")
            read -p "请输入导出目录（默认为 ~/key_backup）: " export_dir
            export_keys "${export_dir:-$HOME/key_backup}"
            break
            ;;
        "导入密钥")
            read -p "请输入备份文件路径: " backup_file
            import_keys "$backup_file"
            break
            ;;
        "退出")
            exit 0
            ;;
        *)
            echo "无效的选择"
            ;;
    esac
done