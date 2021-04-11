#!/bin/bash

# 去掉windows换行符
strip_file_r(){
    filename=$1
    if [ ! -f "${filename}" ];then
        echo "找不到文件 $filename"
        exit 2
    fi
    # 去掉windows的\r
    cat ${filename} | tr -d '\r' > "./tmp.env"
    mv "./tmp.env" ${filename}
}


FILE_NAME=$1
HAS_WIN_R=`grep $'\r' $FILE_NAME`
if [ ! -z "$HAS_WIN_R" ];then
    echo "文件 $FILE_NAME 存在windows换行符，执行脚本去掉文件中的\r"
    strip_file_r $FILE_NAME
fi
