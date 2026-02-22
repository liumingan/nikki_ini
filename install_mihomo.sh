#!/bin/bash
. /etc/envfiles/.env  # 导入系统变量
. /etc/openwrt_release  # 读取 OpenWrt 版本信息

set -e  # 遇到错误立即退出


# 下载函数
DOWNLOAD_Nikki_HS (){
# 只需运行一次
  wget -O - https://github.com/nikkinikki-org/OpenWrt-nikki/raw/main/feed.sh | ash
}

# 在线安装函数
ONLINE_INSTALL_HS (){
  wget -O - https://raw.githubusercontent.com/nikkinikki-org/OpenWrt-nikki/main/install.sh | ash
}

ONLINE_INSTALL_HS || DOWNLOAD_Nikki_HS

# 监控 mihomo 进程
nikki_monitor_HS (){
    cat << 'EOF' > /etc/init.d/nikki_monitor
#!/bin/sh /etc/rc.common

USE_PROCD=1
START=99
LOG_TAG="nikki_monitor"

start_service() {
    procd_open_instance
    procd_set_param command /bin/sh /etc/nikki_monitor.sh
    procd_set_param respawn 5 10 0  # 失败后 5 秒重启，最多尝试 10 次
    procd_close_instance

    logger -t "$LOG_TAG" "Nikki 监控服务已启动"
}

stop_service() {
    logger -t "$LOG_TAG" "Nikki 监控服务已停止"
}

EOF


    cat << 'EOF' > /etc/nikki_monitor.sh
#!/bin/sh

# 监视 mihomo 进程，并动态调整 dnsmasq 的上游 DNS 服务器

default_dns=""  # 运营商默认 DNS，多个 DNS 用空格分隔
mihomo_dns="127.0.0.1#1053 fd00::1#1053"  # 使用本机 DNS 解析
dnsmasq_config="/etc/config/dhcp"

dns_set() {
    local new_dns=$1
    local noresolv_value=$2  # 传入 noresolv 值
    local cachesize_value=$3
	
    uci del dhcp.@dnsmasq[0].server

    # 循环遍历 new_dns 变量中的多个 DNS 地址
    for dns in $new_dns; do
        uci add_list dhcp.@dnsmasq[0].server="$dns"
    done

    # 设置 noresolv 值
    uci set dhcp.@dnsmasq[0].noresolv="$noresolv_value"
    uci set dhcp.@dnsmasq[0].cachesize="$cachesize_value"
    # 提交配置并重启 dnsmasq
    uci commit dhcp
    /etc/init.d/dnsmasq reload
    logger -t DNS切换 "DNS 上游修改为 $new_dns, noresolv=$noresolv_value"
}

check_mihomo() {
    [ "$(ubus call service list '{"name":"nikki"}' | jq -r '."nikki".instances.nikki.running')" = "true" ]
}

prev_status=-1

while true; do
    if check_mihomo; then
        if [ "$prev_status" != "1" ]; then
            dns_set "$mihomo_dns" "1"  "0" # mihomo 运行时，使用本机解析，并禁用外部 DNS
            prev_status=1
        fi
    else
        if [ "$prev_status" != "0" ]; then
            dns_set "$default_dns" "0"  "1000" # mihomo 未运行，恢复默认 DNS
            prev_status=0
        fi
    fi
    sleep 10  # 每 10 秒检查一次
done

EOF
    chmod +x /etc/init.d/nikki_monitor
    chmod +x /etc/nikki_monitor.sh
    /etc/init.d/nikki_monitor enable
    /etc/init.d/nikki_monitor start
}

nikki_monitor_HS

# 启用 Nikki，并进行基本配置
uci batch <<-EOF
set nikki.config.enabled='1'
set nikki.config.mixin='0'
set nikki.config.fast_reload='1'
set nikki.config.profile='subscription:cfg160caa'

# 代理模式配置
set nikki.proxy.tcp_transparent_proxy_mode='tproxy'
set nikki.proxy.udp_transparent_proxy_mode='tproxy'
set nikki.proxy.ipv6_proxy='1'
set nikki.proxy.bypass_china_mainland_ip='1'
set nikki.proxy.access_control_mode='block'
set nikki.proxy.router_proxy='0'
set nikki.proxy.ipv4_dns_hijack='0'
set nikki.proxy.ipv6_dns_hijack='0'
add_list nikki.proxy.acl_mac='2C:B2:1A:55:C2:28'

# 订阅配置
set nikki.subscription.name="${Operators}"
set nikki.subscription.url="https://raw.githubusercontent.com/liumingan/nikki_ini/main/${Operators}.yaml"
set nikki.subscription.user_agent='mihomo'
set nikki.@subscription.prefer='remote'

# Mixin 配置
set nikki.mixin.dns_respect_rules='0'
set nikki.mixin.log_level='silent'
set nikki.mixin.ipv6='1'
set nikki.mixin.socks_port='7891'
set nikki.mixin.redir_port='7893'
set nikki.mixin.tun_stack='mixed'
set nikki.mixin.dns_mode='redir-host'
set nikki.mixin.dns_ipv6='1'
set nikki.mixin.dns_hosts='1'
set nikki.mixin.dns_system_hosts='1'
set nikki.mixin.geosite_url='https://ghfast.top/https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat'

# 认证
add nikki authentication
set nikki.@authentication[-1].enabled='1'
set nikki.@authentication[-1].username='Clash'
set nikki.@authentication[-1].password='aK12&345g678'

# 订阅 - 动态 IP 版本
# add nikki subscription
# set nikki.@subscription[-1].name="$Operators-dynv6"
# set nikki.@subscription[-1].url="https://gitlab.com/api/v4/projects/51311478/repository/files/${Operators}-dynv6.yaml/raw?ref=main&private_token=$gitlab_private_token"
# set nikki.@subscription[-1].user_agent='mihomo'
# set nikki.@subscription[-1].prefer='remote'

# 透明代理白名单（避免影响系统服务）
del nikki.proxy.bypass_user
add_list nikki.proxy.bypass_user='ftp'
add_list nikki.proxy.bypass_user='nobody'
add_list nikki.proxy.bypass_user='ntp'
add_list nikki.proxy.bypass_user='dnsmasq'
add_list nikki.proxy.bypass_user='logd'
add_list nikki.proxy.bypass_user='ubus'
add_list nikki.proxy.bypass_user='aria2'

del nikki.proxy.bypass_group
add_list nikki.proxy.bypass_group='ftp'
add_list nikki.proxy.bypass_group='nogroup'
add_list nikki.proxy.bypass_group='ntp'
add_list nikki.proxy.bypass_group='dnsmasq'
add_list nikki.proxy.bypass_group='logd'
add_list nikki.proxy.bypass_group='ubus'
add_list nikki.proxy.bypass_group='aria2'
EOF

# 提交更改并重载配置
uci commit nikki

# 启动 Nikki
/etc/init.d/nikki start
rm -f "$0"
