#!/bin/bash

# 检查是否输入目录
if [[ -z "$1" ]]; then
    echo "用法: $0 <音乐文件夹>"
    echo "示例: $0 ~/Music/MySongs"
    exit 1
fi

# 获取目标目录绝对路径
DIR="$1"

# 检查目录是否存在
if [[ ! -d "$DIR" ]]; then
    echo "错误: 文件夹不存在: $DIR"
    exit 1
fi

echo "处理目录: $DIR"
echo

cd "$DIR" || exit 1

for mp3 in *.mp3; do

    # 防止没有 mp3 时循环异常
    [[ -e "$mp3" ]] || continue

    base="${mp3%.mp3}"

    lrc="$base.lrc"
    png="$base.png"

    echo "正在处理: $base"

    # =====================
    # 处理 LRC
    # =====================
    if [[ -f "$lrc" ]]; then

        # 删除第一行包含“广告”的内容
        sed -i '1{/欢迎来访爱听音乐网/d;}' "$lrc"

        # 如果删除后为空，写入纯音乐提示
        if [[ ! -s "$lrc" ]]; then
            printf '[00:00.00]此歌曲为没有填词的纯音乐，请您欣赏\n' > "$lrc"
        fi

        echo "  ✓ LRC完成"
    fi


    # =====================
    # 写入封面
    # =====================
    if [[ -f "$png" ]]; then

        ffmpeg -hide_banner -loglevel error \
            -i "$mp3" \
            -i "$png" \
            -map 0:a \
            -map 1:v \
            -c:a copy \
            -c:v mjpeg \
            -id3v2_version 3 \
            -metadata:s:v title="Album cover" \
            -metadata:s:v comment="Cover (front)" \
            "$base.tmp.mp3"

        if [[ $? -eq 0 ]]; then
            mv "$base.tmp.mp3" "$mp3"
            echo "  ✓ 封面完成"
        else
            echo "  ✗ 封面失败"
            rm -f "$base.tmp.mp3"
        fi
    fi

    echo

done

echo "全部处理完成"
