#!/bin/bash

file="$1"
start="$2"

if [ -z "$file" ] || [ -z "$start" ]; then
    echo "用法: $0 文件.lrc 起始行"
    exit 1
fi

awk -v start="$start" '
NR < start {
    print
    next
}

{
    line[NR-start+1]=$0

    pos=index($0, "]")
    if (pos) {
        time[NR-start+1]=substr($0,1,pos)
        lyric[NR-start+1]=substr($0,pos+1)
    } else {
        time[NR-start+1]=$0
        lyric[NR-start+1]=""
    }

    count=NR-start+1
}

END {
    for(i=1;i<=count;i++){
        if(i<count)
            print time[i] lyric[i+1]
        else
            print time[i]
    }
}
' "$file" > "${file%.lrc}_shifted.lrc"
