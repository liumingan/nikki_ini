#!/bin/ash
. /etc/envfiles/.env  # 导入系统变量
. /etc/openwrt_release  # 读取 OpenWrt 版本信息

# 添加计划任务
touch /etc/crontabs/root

if [ "$DeviceModel" = "liaohui_r5s" ] || [ "$DeviceModel" = "syk3" ]; then
    cat <<EOF > /etc/crontabs/root
# 每天2点15分优选ydcf ip
20 */6 * * * cd /etc/cfipopw/ && ./cdnip.sh cf 2053
45 */6 * * * cd /etc/cfipopw/ && ./cdnip.sh fd 443
# 每天6点重启DDNS
0 6 * * * /etc/init.d/ddns restart
15 5 * * * /etc/init.d/nikki restart #nikki
EOF
else
    cat <<EOF > /etc/crontabs/root
# 每天6点重启DDNS
0 6 * * * /etc/init.d/ddns restart
EOF
fi

# 根据设备型号选择测速软件
case "$DeviceModel" in
    liaohui_r5s)
        cfst_s="cfst_r5s.tar.gz"
        ;;
    rqk2p | syk2p)  # 使用 | 作为 "或" 的符号，避免语法错误
        cfst_s="cfst.tgz"
        ;;
    syk3)
        cfst_s="cloudflarest_armv5.tgz.gz"
        ;;
    *)
        echo "未知设备型号，退出脚本。"
        exit 1
        ;;
esac

# 下载测速软件的函数，重试5次
download_speedtest() {
    local retries=5
    local count=0
    local success=0

    while [ $count -lt $retries ]; do
        # 下载并解压测速软件
        wget -qO "/tmp/$cfst_s" "https://raw.githubusercontent.com/liumingan/nikki_ini/main/$cfst_s" \
            && tar -zxf "/tmp/$cfst_s" -C /etc/cfipopw/ \
            && rm -f "/tmp/$cfst_s"

        # 检查是否成功解压
        if [ $? -eq 0 ]; then
            success=1
            echo "测速软件下载并解压成功。"
            break
        else
            echo "下载或解压失败，重试中... ($((count + 1))/$retries)"
            count=$((count + 1))
            sleep 2  # 重试前等待2秒
        fi
    done

    if [ $success -eq 0 ]; then
        echo "测速软件下载失败，退出脚本。"
        exit 1  # 如果最终失败，则退出脚本
    fi
}

# 下载测速脚本的函数，重试5次
download_speedtest_script() {
    local retries=5
    local count=0
    local success=0

    while [ $count -lt $retries ]; do
        # 下载测速脚本
        wget -qO "/etc/cfipopw/cdnip.sh" "https://raw.githubusercontent.com/liumingan/nikki_ini/main/cdnip.sh" \
            && chmod +x /etc/cfipopw/cdnip.sh

        # 检查是否成功下载并赋权
        if [ $? -eq 0 ]; then
            success=1
            echo "测速脚本下载并赋权成功。"
            break
        else
            echo "下载测速脚本失败，重试中... ($((count + 1))/$retries)"
            count=$((count + 1))
            sleep 2  # 重试前等待2秒
        fi
    done

    if [ $success -eq 0 ]; then
        echo "测速脚本下载失败，退出脚本。"
        exit 1  # 如果最终失败，则退出脚本
    fi
}

# 调用函数进行下载测速软件和测速脚本
download_speedtest
download_speedtest_script

chmod 600 /etc/crontabs/root

# 重启计划任务
/etc/init.d/cron restart

# 等待2秒确保任务生效
sleep 2

# 删除自身脚本，但不影响当前执行
rm -f -- "$0"

exit 0
