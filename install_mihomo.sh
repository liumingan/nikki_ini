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

# 启用 Nikki，并进行基本配置
uci batch <<-EOF
set nikki.config.enabled='1'
set nikki.config.mixin='0'
set nikki.config.fast_reload='1'

# 代理模式配置
set nikki.proxy.tcp_mode='tproxy'
set nikki.proxy.udp_mode='tproxy'
set nikki.proxy.ipv6_proxy='1'
set nikki.proxy.bypass_china_mainland_ip='1'
set nikki.proxy.bypass_china_mainland_ip6='1'
set nikki.proxy.router_proxy='1'
set nikki.proxy.ipv4_dns_hijack='1'
set nikki.proxy.ipv6_dns_hijack='1'

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

EOF

# 提交更改并重载配置
uci commit nikki

# 启动 Nikki
/etc/init.d/nikki start
rm -f "$0"
