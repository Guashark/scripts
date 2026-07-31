#!/usr/bin/env bash

[ "$EUID" -ne 0 ] && echo -e "\033[31m[错误] 请使用 sudo 运行此脚本。\033[0m" && exit 1

BIN_DIR="/usr/bin"

# 1. 扫描版本：匹配 pythonX.Y 或 pythonX.Y.Z (忽略后缀字母如 m)
PY_BINARIES=($(find "$BIN_DIR" -maxdepth 1 -type f -o -type l | \
  grep -E '^/usr/bin/python[0-9]+\.[0-9]+(\.[0-9]+)?m?$' | sed 's|.*/||' | sort -V))

[ ${#PY_BINARIES[@]} -eq 0 ] && echo "[错误] 未找到具体的 Python 版本。" && exit 1

# 2. TUI 菜单交互
idx=0
total=${#PY_BINARIES[@]}
tput civis; trap 'tput cnorm; echo ""; exit' INT TERM EXIT

draw() {
    tput cuu $total 2>/dev/null || true
    for i in "${!PY_BINARIES[@]}"; do
        tput el
        if [ "$i" -eq "$idx" ]; then
            echo -e " \033[1;32m> \033[7m ${PY_BINARIES[$i]} \033[0m"
        else
            echo -e "   ${PY_BINARIES[$i]}"
        fi
    done
}

echo -e "\033[1;36m=== 选择 Global Python 版本 (↑/↓ 切换，Enter 确认，Esc 退出) ===\033[0m"
for ((i=0; i<total; i++)); do echo ""; done; draw

while true; do
    read -rsn1 k
    if [[ $k == $'\x1b' ]]; then
        read -rsn2 -t 0.1 sk
        [ "$sk" == "[A" ] && ((idx=(idx-1+total)%total))
        [ "$sk" == "[B" ] && ((idx=(idx+1)%total))
        [ -z "$sk" ] && { tput cnorm; echo -e "\n[退出] 未作改变。"; exit 0; }
        draw
    elif [[ $k == "" ]]; then
        break
    fi
done

tput cnorm
sel="${PY_BINARIES[$idx]}"
echo -e "\n\033[1;34m[已选择] $sel\033[0m"

# 3. 执行软链接更新
link_pair() {
    local target="$1" link_name="$2"
    [ -e "$target" ] && ln -sf "$target" "$BIN_DIR/$link_name" && echo "  ✓ $link_name -> $(basename "$target")"
}

# 提取主版本号（例如从 python3.10.12 中提取 3）
major=$(echo "$sel" | sed -E 's/python([0-9]+).*/\1/')

# 创建主链接
link_pair "$BIN_DIR/$sel" "python"
link_pair "$BIN_DIR/${sel}-config" "python-config"

# 依主版本号（2或3）创建专项链接
link_pair "$BIN_DIR/$sel" "python${major}"
link_pair "$BIN_DIR/${sel}-config" "python${major}-config"

echo -e "\033[1;32m[完成] 当前 python 版本：\033[0m"
python --version