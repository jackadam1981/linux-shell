#!/bin/sh
# Copyright (C) 2007-2012 OpenWrt.org
#################
#本脚本用于在官方openwrt中安装openclash，含有github加速



opkg update
opkg install jq
opkg install curl

opkg remove dnsmasq
rm -rf /etc/config/dhcp
opkg install luci-compat
opkg install dnsmasq-full
opkg install luci-i18n-base-zh-cn
opkg install luci-i18n-opkg-zh-cn	
opkg install luci-i18n-firewall-zh-cn
opkg install luci-i18n-upnp-zh-cn

# #################
# #openclash
# #################

#版本号
VER=$(curl -s https://api.github.com/repos/vernesong/OpenClash/releases | jq 'first(.[].tag_name)')
trueVER=${VER//\"/}
echo $VER
echo $trueVER
#文件名
FILE=$(curl -s https://api.github.com/repos/vernesong/OpenClash/releases | jq 'first(.[].assets[].name)')
trueFILE=${FILE//\"/}
echo $FILE
echo $trueFILE
#下载地址
URL=$(curl -s https://api.github.com/repos/vernesong/OpenClash/releases | jq 'first(.[].assets[].browser_download_url)')
downURL=${URL//\"/}
echo $URL
echo $downURL
newURL=https://github.jackworkers.workers.dev/$downURL
echo $newURL
curl -O $newURL
opkg install $trueFILE

rm $trueFILE