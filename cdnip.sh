#!/bin/sh

export LANG=en_US.UTF-8
set -a
. /etc/envfiles/.env
set +a

point="${2:-443}"
client="${3:-false}"

case "$1" in
  "fd")
    case "$Operators" in
      CMCC) subdomain="ydfd$point"; MS="ip.txt"; IP_ADDR="ipv4"; CFST_SL=10;;
      CUCC) subdomain="ltfd$point"; MS="ip.txt"; IP_ADDR="ipv4"; CFST_SL=5;;
    esac
    ;;
  "cf")
    case "$Operators" in
      CMCC) subdomain="ydcf$point"; MS="ipv4.txt"; IP_ADDR="ipv4"; CFST_SL=10;;
      CUCC) subdomain="ltcf$point"; MS="ipv4.txt"; IP_ADDR="ipv4"; CFST_SL=3;;
    esac
    ;;
  "ipv6")
    case "$Operators" in
      CMCC) subdomain="ydcfv6"; MS="ipv6.txt"; IP_ADDR="ipv6"; CFST_SL=2;;	
      CUCC) subdomain="ltcfv6"; MS="ipv6.txt"; IP_ADDR="ipv6"; CFST_SL=2;;
    esac
    ;;
  *)
    case "$Operators" in
      CMCC) subdomain="ydfd$point"; MS="ip.txt"; IP_ADDR="ipv4"; CFST_SL=10;;
      CUCC) subdomain="ltfd$point"; MS="ip.txt"; IP_ADDR="ipv4"; CFST_SL=5;;
    esac
    ;;
esac
hostname=

case $clien in
  "v2raya") CLIEN=v2raya pause=true;;
  "bypass") CLIEN=bypass pause=true;;
  "openclash") CLIEN=openclash pause=true;;
  "nikki") CLIEN=nikki pause=true;;
  "shadowsocksr") CLIEN=shadowsocksr pause=true;;
  "passwall2") CLIEN=passwall2 pause=true;;
  "passwall") CLIEN=passwall pause=true;;
  *) pause=false;;
esac

csv_file='result.csv'
ymoryms=1
token=
sleepTime=30

CFST_URL_R="-url https://testfileorg.netwet.net/500MB-CZIPtestfile.org.zip"

CFST_N=120

CFST_T=10

CFST_DN=10

CFST_TL=200

CFSTv6_TL=250

CFST_CFCOLO=HKG

CFST_TLR=0

CFST_TLL=40

CFST_SPD=""
ymorip=1
domain=homeip.us.eu.org
domain1=cfwork.rr.nu
# 设置 GitHub 上传的文件名
FILE_NAME="${subdomain}_${domain//./_}_ip_list.txt"
# 设置 hosts 文件名
hosts_file_homeip="${subdomain}_${domain//./_}.hosts"
hosts_file_cfwork="${subdomain}_${domain1//./_}.hosts"

# 定义tg机器人推送函数
tgaction(){
if [[ -z ${telegramBotToken} ]]; then
   echo "未配置TG推送";
else
   message_text=$pushmessage
   MODE='HTML'
   URL="https://${tgapi}/bot${telegramBotToken}/sendMessage"
   res=$(timeout 20s curl -s -X POST $URL -d chat_id=${telegramBotUserId} -d parse_mode=${MODE} -d text="${message_text}")
   if [ $? == 124 ];then
      echo 'TG_api请求超时,请检查网络是否重启完成并是否能够访问TG';
    fi
   resSuccess=$(echo "$res" | jq -r ".ok")
   if [[ $resSuccess = "true" ]]; then
      echo "TG推送成功";
      else
      echo "TG推送失败，请检查TG机器人token和ID";
   fi
fi
if [[ -z ${token} ]]; then
   echo "未配置PushPlus推送";
else
   P_message_text=$pushmessage
   res=$(timeout 20s curl -s -X POST "http://www.pushplus.plus/send" -d "token=${token}" -d "title=Cloudflare优选IP推送通知" -d "content=${P_message_text}" -d "template=html")
   if [ $? == 124 ];then
      echo 'PushPlus请求超时，请检查网络是否正常';
    fi
   resCode=$(echo "$res" | jq -r ".code")
   if [[ $resCode = 200 ]]; then
      echo "PushPlus推送成功";
    else
      echo "PushPlus推送失败，请检查PushPlusToken是否填写正确";
    fi
fi
}
# 关闭代理软件
if [ "$pause" == "false" ] ; then
echo "按要求未停止科学上网服务";
else
/etc/init.d/$CLIEN stop;
sleep 60
echo "已停止$CLIEN";
fi
# 判断工作模式

if [ "$MS" == "ip.txt" ]; then
      echo "当前工作模式为ipv4,反代模式，正在更新反代IP库";
      wget -O "/tmp/txt.zip" "https://gitlab.com/api/v4/projects/51320840/repository/files/cdnip%2Ftxt.zip/raw?ref=main&private_token=$gitlab_private_token" && unzip -q -d /tmp/txt/ /tmp/txt.zip;
#      cat /tmp/txt/*-"$point".txt > /tmp/ip.txt;
	cat /tmp/txt/*-"$point".txt | sed 's/$/\/32/' > /tmp/ip.txt;
      rm -r /tmp/txt /tmp/txt.zip;
  elif [ "$MS" == "ipv4.txt" ]; then
      echo "当前工作模式为ipv4,CF官方模式,正在下载更新CF官方IPv4库";
      curl -o "/tmp/ipv4.txt" "https://gitlab.com/api/v4/projects/51320840/repository/files/cdnip%2Fipv4.txt/raw?ref=main&private_token=$gitlab_private_token";
  elif [ "$IP_ADDR" == "ipv6" ] ; then
      echo "当前工作模式为ipv6，正在下载CF官方IPv6库";
      curl -o "/tmp/ipv6.txt" "https://gitlab.com/api/v4/projects/51320840/repository/files/cdnip%2Fipv6.txt/raw?ref=main&private_token=$gitlab_private_token";
 fi
 
#定义测速函数
CloudflareSTyx(){
if [ "$IP_ADDR" == "ipv6" ] ; then
    ./CloudflareST -tp $point $CFST_URL_R -t $CFST_T -n $CFST_N -dn $CFST_DN -p $CFST_DN -tl $CFSTv6_TL -tlr $CFST_TLR -tll $CFST_TLL -sl $CFST_SL -f "/tmp/ipv6.txt" $CFST_SPD;
  elif [ "$IP_ADDR" == "ipv4" ] ; then
    ./CloudflareST -tp $point $CFST_URL_R -t $CFST_T -n $CFST_N -dn $CFST_DN -p $CFST_DN -tl $CFST_TL -tlr $CFST_TLR -tll $CFST_TLL -sl $CFST_SL -f "/tmp/$MS" $CFST_SPD;
 fi	
}
# 定义重启代理软件函数
porxy_restart(){
if [ "$pause" == "false" ] ; then
		echo "按要求未重启科学上网服务";
		sleep 3;
   else
		/etc/init.d/$CLIEN restart;
		echo "已重启$CLIEN";
		echo "请稍等$sleepTime秒";
		sleep $sleepTime;
fi
}

#定义登录cloudflare函数
Cloudflare_login(){
if [ "$ymorip" == "1" ]; then
  proxy="false";
  max_retries=5
  for i in $(seq 1 $max_retries); do
    res=$(curl -sm10 -X GET "https://api.cloudflare.com/client/v4/zones/${zone_id}" -H "X-Auth-Email:$x_email" -H "X-Auth-Key:$api_key" -H "Content-Type:application/json")
    resSuccess=$(echo "$res" | jq -r ".success")
    if [[ $resSuccess == "true" ]]; then
        echo "Cloudflare账号登陆成功!";
        break
     elif [ "$i" -eq $max_retries ]; then
        echo "尝试5次登陆CF失败，检查CF邮箱、区域ID、API Key，这三者信息是否填写正确，或者查下当前代理的网络能否打开Cloudflare官网？";
        pushmessage="尝试5次登陆CF失败，检查CF邮箱、区域ID、API Key，这三者信息是否填写正确，或者查下当前代理的网络能否打开Cloudflare官网？";
        tgaction
		porxy_restart
        exit
     else
        echo "Cloudflare账号登陆失败，尝试重连 ($i/$max_retries)...";
        sleep 3
   fi
   done
   if [ ! "$ymoryms" == "1" ]; then
      num=${#hostname[*]};
    if [ "$CFST_DN" -le $num ] ; then
       CFST_DN=$num;
     fi
   fi
fi
}

# 定义检查是否存在 result.csv 文件函数，检测测速结果
Check_out_file(){
num=$CFST_DN
new_num=$((num + 1))
max_recfst=1
if [ -f "./result.csv" ]; then
    second_line=$(sed -n '2p' ./result.csv | tr -d '[:space:]')

    if [ -z "$second_line" ]; then
        echo "优选IP失败，正在重新执行(1/$max_recfst)..." && sleep 3
        pushmessage="优选IP失败，正在重新执行一次"
        tgaction
        
        for i in $(seq 0 $max_recfst); do
            if [ "$i" -eq "$max_recfst" ]; then
                echo "优选失败停止优选"
                pushmessage="优选失败停止优选"
                tgaction
                porxy_restart
                exit
            else
                CloudflareSTyx
            fi
        done  
    else
        awk -F, 'NR > 1 && $6 != 0' ./result.csv > ./non_zero_result.csv
		awk -F '[ ,]+' '$6 > 4' ./non_zero_result.csv > ./new_result.csv


        non_zero_ip_count=$(wc -l < ./non_zero_result.csv | xargs)
        if [[ "$non_zero_ip_count" -eq 0 ]]; then
            echo "所有IP测速均为0或没有有效IP，取消更新"
            pushmessage="所有IP测速均为0或没有有效IP，取消更新"
            tgaction
            porxy_restart
            exit
        fi

        if [[ -s ./new_result.csv ]]; then
            ip_count=$(wc -l < ./new_result.csv | xargs)
            echo "已找到 $ip_count 个测速大于4的IP，保留所有这些IP"
            cp ./new_result.csv ./result.csv && rm ./new_result.csv
        else
            echo "测速大于4的IP数量不超过1个，保留其中最快的2个IP"
            (head -n 1 ./non_zero_result.csv && sort -t, -k6 -nr ./non_zero_result.csv | sed -n '2,3p') > ./result.csv
        fi
    fi
else
    echo "优选IP中断，未生成result.csv文件，正在重新执行(1/$max_recfst)..." && sleep 3
    pushmessage="优选IP中断，未生成result.csv文件，正在重新执行"
    tgaction

    for i in $(seq 0 $max_recfst); do
        if [ "$i" -eq "$max_recfst" ]; then
            echo "优选失败停止优选"
            pushmessage="优选失败停止优选"
            tgaction
            porxy_restart
            exit
        else
            CloudflareSTyx
        fi
    done  
fi
}

# 定义多个优选IP解析到一个域名函数
ymonly(){
echo "正在更新解析：多个优选IP解析到一个域名。请稍后...";
url="https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records";
params="name=${subdomain}.${domain}&type=A,AAAA"
response=$(curl -sm10 -X GET "$url?$params" -H "X-Auth-Email: $x_email" -H "X-Auth-Key: $api_key")
if [[ $(echo "$response" | jq -r '.success') == "true" ]]; then
    records=$(echo "$response" | jq -r '.result')
    if [[ $(echo "$records" | jq 'length') -gt 0 ]]; then
        for record in $(echo "$records" | jq -c '.[]'); do
            record_id=$(echo "$record" | jq -r '.id')
            delete_url="$url/$record_id"
            delete_response=$(curl -sm10 -X DELETE "$delete_url" -H "X-Auth-Email: $x_email" -H "X-Auth-Key: $api_key")
            if [[ $(echo "$delete_response" | jq -r '.success') == "true" ]]; then
                echo "成功删除 DNS 记录：$(echo "$record" | jq -r '.name')";
            else
                echo "删除 DNS 记录失败";
            fi
        done
    else
        echo "没有找到指定的 DNS 记录";
    fi
else
    echo "获取 DNS 记录失败";
fi

if [[ -f $csv_file ]]; then
    # 读取 CSV 文件的第一列（IP 地址），包括标题行
    ips=$(awk -F ',' '{print $1}' "$csv_file")

    for ip in $ips; do
        url="https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records"
        if [[ "$ip" =~ ":" ]]; then
            record_type="AAAA"
        else
            record_type="A"
        fi
        data='{
            "type": "'"$record_type"'",
            "name": "'"$subdomain.$domain"'",
            "content": "'"$ip"'",
            "ttl": 60,
            "proxied": false
        }'
        response=$(curl -s -X POST "$url" -H "X-Auth-Email: $x_email" -H "X-Auth-Key: $api_key" -H "Content-Type: application/json" -d "$data")

        if [[ $(echo "$response" | jq -r '.success') == "true" ]]; then
            echo "IP地址 $ip 成功解析到 ${subdomain}.${domain}"
        else
            echo "导入IP地址 $ip 失败"
            echo "导入IP地址 $ip 失败" >> /tmp/informlog
        fi
        sleep 1
    done
else
    echo "CSV文件 $csv_file 不存在"
fi
}

# 定义每个优选IP解析到每个域名函数
ym(){
echo "正在更新解析：每个优选IP解析到每个域名。请稍后...";
ipv4Regex="((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])";
x=0;
while [[ ${x} -lt $num ]]; do
    CDNhostname=${hostname[$x]};
    ipAddr=$(awk -F ',' 'NR > 1 && $6 > 0 {print $1}' result.csv | head -n 2 | sed -n "$((x + 1))p");
    if [ -z "$ipAddr" ]; then
        echo "没有足够的有效IP可更新";
        break;
    fi
    echo "开始更新第$((x + 1))个---$ipAddr";
    if [[ $ipAddr =~ $ipv4Regex ]]; then
        recordType="A";
    else
        recordType="AAAA";
     fi
    listDnsApi="https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?type=${recordType}&name=${CDNhostname}";
    createDnsApi="https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records";
    res=$(curl -s -X GET "$listDnsApi" -H "X-Auth-Email:$x_email" -H "X-Auth-Key:$api_key" -H "Content-Type:application/json");
    sleep 1
    recordId=$(echo "$res" | jq -r ".result[0].id");
    recordIp=$(echo "$res" | jq -r ".result[0].content");

    if [[ $recordIp == "$ipAddr" ]]; then
        echo "更新失败，获取最快的IP与云端相同";
        resSuccess=false;
       elif [[ $recordId = "null" ]]; then
        res=$(curl -s -X POST "$createDnsApi" -H "X-Auth-Email:$x_email" -H "X-Auth-Key:$api_key" -H "Content-Type:application/json" --data "{\"type\":\"$recordType\",\"name\":\"$CDNhostname\",\"content\":\"$ipAddr\",\"proxied\":$proxy}");
        resSuccess=$(echo "$res" | jq -r ".success");
       else
        updateDnsApi="https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${recordId}";
        res=$(curl -s -X PUT "$updateDnsApi"  -H "X-Auth-Email:$x_email" -H "X-Auth-Key:$api_key" -H "Content-Type:application/json" --data "{\"type\":\"$recordType\",\"name\":\"$CDNhostname\",\"content\":\"$ipAddr\",\"proxied\":$proxy}");
        resSuccess=$(echo "$res" | jq -r ".success");
     fi

    if [[ $resSuccess == "true" ]]; then
        echo "$CDNhostname更新成功";
      else
        echo "$CDNhostname更新失败";
     fi
    x=$((x + 1));
    sleep 3;
done > /tmp/informlog
}

# 定义更新DNS记录函数
Update_DNS_records(){
if [ "$ymorip" == "1" ]; then
  if [ "$ymoryms" == "1" ]; then
      ymonly
    else
      ym
   fi
  else
    echo "优选IP排名如下" > /tmp/informlog;
    awk -F ',' '{print $1}' "$csv_file" >> /tmp/informlog;
 fi
}

# 使用ip-api查询国家地区函数
Use_ipapi_check(){
echo  "正在进行国家地区识别........";
awk -F ',' '{print $1}' "$csv_file" > /tmp/a.csv
while read ip_address; do
    url="http://ip-api.com/json/${ip_address}?fields=continent,country,regionName,city"
    response=$(curl -s "$url") || break;
    country=$(echo "$response" | jq -r '.country')
    region=$(echo "$response" | jq -r '.regionName')
    city=$(echo "$response" | jq -r '.city')
    echo "${ip_address}: ${country}, 成功解析到 ${subdomain}.${domain}" | tee -a "/tmp/informlog"
 done < /tmp/a.csv;
# 生成最终解析到 Cloudflare 的 IP 列表
grep "成功解析到" /tmp/informlog | awk -F ': ' '{print $1}' | tr '\n' ',' | sed 's/,$//' > "$FILE_NAME"

# 确保文件不为空
if [ ! -s "$FILE_NAME" ]; then
    echo "Cloudflare IP 更新失败，未找到有效 IP"
    exit 1
fi 
# 推送消息
pushmessage="$(cat '/tmp/informlog')";
}

#定义使用ipinfo查询函数
Use_ipinfo_check(){
echo  "正在进行国家地区识别........";
while read -r ip_address; do
    url="http://ipinfo.io/${ip_address}/?fields=country,city,org"
    response=$(curl -s --fail "$url") || break;
    country=$(echo "$response" | jq -r '.country')
    region=$(echo "$response" | jq -r '.region')
    city=$(echo "$response" | jq -r '.city')
    org=$(echo "$response" | jq -r '.org')
    echo "${ip_address}: ${country}, 成功解析到 ${subdomain}.${domain}" | tee -a "/tmp/informlog"
 done < /tmp/a.csv;
# 生成最终解析到 Cloudflare 的 IP 列表
grep "成功解析到" /tmp/informlog | awk -F ': ' '{print $1}' | tr '\n' ',' | sed 's/,$//' > "$FILE_NAME"

# 确保文件不为空
if [ ! -s "$FILE_NAME" ]; then
    echo "Cloudflare IP 更新失败，未找到有效 IP"
    exit 1
fi 
# 推送消息
pushmessage="$(cat '/tmp/informlog')";
}

#定义更新hosts函数
update_hosts_function(){
# 创建一个临时文件用于存储检查过的 IP 地址
temp_file_homeip=$(mktemp)
temp_file_cfwork=$(mktemp)
# 读取文件内容并处理每个 IP 地址
line=$(cat "$FILE_NAME")
# 处理每个 IP 地址
for ip in $(echo "$line" | tr ',' ' '); do
    echo "$ip  ${subdomain}.${domain}" >> "$temp_file_homeip"
    echo "$ip  ${subdomain}.${domain1}" >> "$temp_file_cfwork"
done
# 将临时文件内容移动到最终的 hosts 文件
mv "$temp_file_homeip" "/etc/hosts.d/$hosts_file_homeip"
mv "$temp_file_cfwork" "/etc/hosts.d/$hosts_file_cfwork"
/etc/init.d/dnsmasq reload

# 设置权限
chmod 644 "/etc/hosts.d/$hosts_file_homeip" "/etc/hosts.d/$hosts_file_cfwork"
echo "Hosts 文件已生成并更新：$hosts_file_homeip, $hosts_file_cfwork"
}

#定义上传到github函数
upload_to_GitHub_function() {
  # 获取 GitHub 上文件的 SHA 值（如果存在）
  SHA=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$FILE_NAME" | jq -r .sha)

  # 使用 OpenSSL 进行 Base64 编码（适用于 OpenWrt）
  ENCODED_CONTENT=$(openssl base64 -A < "$FILE_NAME" | tr -d '\n')

  # 生成 JSON 数据
  if [ "$SHA" = "null" ]; then
    JSON="{\"message\": \"Add $FILE_NAME\", \"content\": \"$ENCODED_CONTENT\", \"branch\": \"$GITHUB_BRANCH\"}"
  else
    JSON="{\"message\": \"Update $FILE_NAME\", \"content\": \"$ENCODED_CONTENT\", \"sha\": \"$SHA\", \"branch\": \"$GITHUB_BRANCH\"}"
  fi

  # 上传到 GitHub，并将输出重定向到 /dev/null
  curl -s -X PUT -H "Authorization: token $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    -d "$JSON" "https://api.github.com/repos/$GITHUB_USER/$GITHUB_REPO/contents/$FILE_NAME" > /dev/null 2>&1

echo "$FILE_NAME 已上传到 GitHub"
}

#运行测速
CloudflareSTyx;
Check_out_file
Cloudflare_login 
Update_DNS_records
Use_ipapi_check
tgaction;
update_hosts_function
upload_to_GitHub_function

# 删除临时文件
rm -f /tmp/ip.txt /tmp/ipv4.txt /tmp/ipv6.txt /tmp/a.csv /tmp/informlog ./result.csv ./new_result.csv ./non_zero_result.csv ./$FILE_NAME;

porxy_restart

exit 0

