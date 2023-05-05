#!/system/bin/sh

Log(){
    log -p d -t cqa $1
}

Log "copy cqa files begin"

RET=$(getprop ro.build.smt.ver)
if [ "$RET" == "1" ]; then
    if [ ! -d "/data/media/0/CQATest/" ];then
        mkdir /data/media/0/CQATest
    else
        Log "CQATest dir is exist"
    fi
    cp /system/bin/CQATest/CQA_commands.sh /data/media/0/CQATest/
    chmod 777 /data/media/0/CQATest/CQA_commands.sh
    Log "current version is smt"
else
    Log "current version is not smt"
fi

Log "copy cqa files end"
