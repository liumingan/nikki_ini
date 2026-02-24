#!/bin/bash
. /etc/envfiles/.env  # 导入系统变量
. /etc/openwrt_release  # 读取 OpenWrt 版本信息

set -e  # 遇到错误立即退出
uci set luci.main.check_for_newer_firmwares='0'
uci commit luci
/etc/init.d/rpcd restart

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
set nikki.'config'.enabled='1'
set nikki.'config'.start_delay='10'
set nikki.'config'.scheduled_restart='0'
set nikki.'config'.cron_expression='0 4 * * *'
set nikki.'config'.test_profile='1'
set nikki.'config'.core_only='1'

# 订阅配置
set nikki.'subscription'.name="${Operators}"
set nikki.'subscription'.url="https://raw.githubusercontent.com/liumingan/nikki_ini/main/${Operators}.yaml"
set nikki.'subscription'.user_agent='mihomo'
set nikki.'subscription'.prefer='remote'

# Mixin 配置
set nikki.mixin.log_level='silent'
set nikki.'mixin'.mode='rule'
set nikki.'mixin'.match_process='off'
set nikki.'mixin'.ipv6='1'
set nikki.'mixin'.ui_url='https://github.com/Zephyruso/zashboard/releases/latest/download/dist-cdn-fonts.zip'
set nikki.'mixin'.api_listen='[::]:9090'
set nikki.'mixin'.selection_cache='1'
set nikki.'mixin'.allow_lan='1'
set nikki.'mixin'.http_port='8080'
set nikki.'mixin'.socks_port='7891'
set nikki.'mixin'.mixed_port='7890'
set nikki.'mixin'.redir_port='7893'
set nikki.'mixin'.tproxy_port='7892'
set nikki.'mixin'.authentication='1'
set nikki.'mixin'.tun_device='nikki'
set nikki.'mixin'.tun_stack='system'
set nikki.'mixin'.tun_dns_hijack='1'
add_list nikki.'mixin'.tun_dns_hijacks='tcp://any:53'
add_list nikki.'mixin'.tun_dns_hijacks='udp://any:53'
set nikki.'mixin'.dns_listen='[::]:1053'
set nikki.'mixin'.dns_ipv6='1'
set nikki.'mixin'.dns_mode='redir-host'
set nikki.'mixin'.fake_ip_range='198.18.0.1/16'
set nikki.'mixin'.fake_ip_filter='0'
add_list nikki.'mixin'.fake_ip_filters='+.lan'
add_list nikki.'mixin'.fake_ip_filters='+.local'
set nikki.'mixin'.fake_ip_cache='1'
set nikki.'mixin'.hosts='0'
set nikki.'mixin'.dns_nameserver='0'
set nikki.'mixin'.dns_nameserver_policy='0'
set nikki.'mixin'.sniffer_force_domain_name='0'
set nikki.'mixin'.sniffer_ignore_domain_name='0'
set nikki.'mixin'.sniffer_sniff='0'
set nikki.'mixin'.rule='0'
set nikki.'mixin'.rule_provider='0'
set nikki.'mixin'.mixin_file_content='0'
set nikki.'mixin'.ui_path='ui'
set nikki.'mixin'.dns_enabled='1'
set nikki.'mixin'.tun_enabled='1'

# 代理模式配置
set nikki.'proxy'.enabled='1'
set nikki.'proxy'.tcp_mode='tproxy'
set nikki.'proxy'.udp_mode='tproxy'
set nikki.'proxy'.ipv4_dns_hijack='1'
set nikki.'proxy'.ipv6_dns_hijack='1'
set nikki.'proxy'.ipv4_proxy='1'
set nikki.'proxy'.ipv6_proxy='1'
set nikki.'proxy'.fake_ip_ping_hijack='1'
set nikki.'proxy'.router_proxy='1'
set nikki.'proxy'.lan_proxy='1'
set nikki.'proxy'.bypass_china_mainland_ip='0'
set nikki.'proxy'.bypass_china_mainland_ip6='0'

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
