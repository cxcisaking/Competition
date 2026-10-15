#!/bin/bash
IMAGES_NUM=$1
if [ -z "$IMAGES_NUM" ] || [ "$IMAGES_NUM" -eq 0 ];then
    echo "err!!! usage: ./image_get.sh num"
    exit 1
fi
((FRAM_NUM = (IMAGES_NUM - 1) * 2))

rm -f /tmp/csi.log
rm -f test.yuv
rm -f *.png
# 1. 启动命令，并将输出写入临时文件（后台运行）
LOGFILE="/tmp/csi.log"
# 启动 csi-test 并记录 PID
stdbuf -oL -eL csi-test -d video-evs0 -w 640 -v 480 -x 640 -z 480 -p 1 -m $IMAGES_NUM -k 2 -f test.yuv > "$LOGFILE" 2>&1 &
PID=$!
echo "Started csi-test with PID $PID, waiting for trigger..."
# 2. 轮询日志文件是否包含特定关键字
while true; do
    if grep -q "save frm "$FRAM_NUM"" "$LOGFILE"; then
        echo "Detected '[::CameraFrameCome]  save frm "$FRAM_NUM"', sending SIGINT to PID $PID..."
        kill $PID  
        break
    fi
    sleep 2
done
echo "csi-test stopped."
echo "start ffmpeg..."
./ffmpeg-7.0.2-arm64-static/ffmpeg -s 640x480 -pix_fmt yuyv422 -i test.yuv -frames:v $IMAGES_NUM test%02d.png