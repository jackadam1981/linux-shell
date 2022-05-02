#/!bin/sh

####################
##脚本用于fedora，red-hat系列linux，自动安装最新版本docker，docker-compose,设置docker存储路径，开启2375.
##计划添加开启2376tls认证接口。
####################

DOCKER_PATH="/storage/docker"
JSON_PATH="/etc/docker"
JSON_FILE="$JSON_PATH/daemon.json"


function create_json {
echo 创建配置文件
cat >$1<<EOF # 开始
{
}
EOF
}


function check_json {
#如果配置文件不存在，就创建一个只有{}的空配置模板
echo 检查配置目录$JSON_PATH
check_path $JSON_PATH
echo 检查配置目录$JSON_PATH完成

if [ ! -f $1 ];then
	echo 没有配置文件
	create_json $1
else 
	line=$(cat $1 |wc -l)
	
	if [ $line -eq 0 ];then
	echo 配置文件共有$line行
	create_json $1
	fi
fi
echo 展示配置文件
cat $1
}


function check_path {
echo 检查$1目录
if [ ! -d $1 ];then
mkdir -p $1
fi
echo 目录$1检查完成
}



function add_json {
echo 增加配置
# echo $1 $2 $3
check_json $1
FIND_FILE=$1
FIND_STR=$2
SET_STR=$3
echo $1 $2 $3
# 判断匹配函数，匹配函数不为0，则包含给定字符
	if [ `grep -c "$FIND_STR" $FIND_FILE` -ne '0' ];then
		echo "修改配置"
		# echo /$FIND_STR/d $FIND_FILE
		sed -i /$FIND_STR/d $FIND_FILE
		
	else
		echo "增加配置" $FIND_FILE
		line=$(cat $FIND_FILE |wc -l)
		echo 配置文件共$line行
		
		if [ $line -gt 2 ];then
			echo "添加小尾巴"
			sed -i "/^}/i," $FIND_FILE
		fi
	fi
echo 倒数第二行增加配置
sed -i "/^}/i\"$FIND_STR\": $SET_STR" $FIND_FILE 
# cat $FIND_FILE
cat $FIND_FILE |jq > temp.json
rm -rf $FIND_FILE
cp  temp.json $FIND_FILE
rm temp.json
echo 最终展示配置文件
cat $FIND_FILE
echo 最终展示配置文件完成
}
# sed -i '/data-root/d' /etc/docker/daemon.json
# line=$(cat /etc/docker/daemon.json |wc -l)
# cp -f temp.json /etc/docker/daemon.json




function install_docker {
echo install_docker
dnf remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine \
                  docker-compose-plugin
echo  安装镜像管理工具
dnf -y install dnf-plugins-core

echo 配置docker-ce官方镜像
dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo

echo 安装docker
dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo 安装docker_compose
echo 删除旧版本docker_compose
if [ ! -f /usr/libexec/docker/cli-plugins/docker-compose ];then
  rm -rf /usr/libexec/docker/cli-plugins/docker-compose
fi
VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
URL=https://github.jackworkers.workers.dev/https://github.com/docker/compose/releases/download/${VER}/docker-compose-linux-x86_64
curl -SL ${URL} -o /usr/libexec/docker/cli-plugins/docker-compose
chmod +x /usr/libexec/docker/cli-plugins/docker-compose
rm -rf /usr/bin/docker-compose
ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose
}

function set_storage {
echo set_storage
echo "请设置docker存储路径。"
echo "直接回车设为$DOCKER_PATH"
read INPUT
if [ -z $INPUT ];then
	echo 默认值$DOCKER_PATH
else
	echo 输入值$INPUT
	DOCKER_PATH=$INPUT
fi
echo 您选择的docker存储路径为$DOCKER_PATH
add_json $JSON_FILE "data-root" "\"$DOCKER_PATH\""
}


function set_2375 {
  echo 增加配置docker2375
  add_json $JSON_FILE "hosts" [\"tcp://0.0.0.0:2375\"\,\ \"unix:///var/run/docker.sock\"]
  sed -i '/ExecStart=/cExecStart=/usr/bin/dockerd' /usr/lib/systemd/system/docker.service
  systemctl daemon-reload
  systemctl restart docker
  # ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
  echo 增加防火墙配置
  firewall-cmd --permanent --new-service=docker2375
  firewall-cmd --permanent --service=docker2375 --add-port=2375/tcp
  firewall-cmd --permanent --add-service=docker2375
  firewall-cmd --reload 
  echo 防火墙配置完成
}

function set_2376 {
echo "set_2376"
}


function remove {
echo remove
dnf remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-selinux \
                  docker-engine-selinux \
                  docker-engine \
                  docker-compose-plugin
}

function menu {
 echo
 echo -e "\t\t\tdocker安装工具\n"
 echo -e "\t1. 安装docker"
 echo -e "\t2. 配置存储路径"
 echo -e "\t3. 配置打开2375"
 echo -e "\t4. 配置2376证书"
 echo -e "\t5. 删除docker"
 echo -e "\t6. test"
 echo -e "\t0. 退出\n\n"
 echo -en "\t\t请选择: "
 read -n 1 option
}





while [ 1 ]
do
	menu
	case $option in
	0)
	 break ;;
	1)
	 install_docker ;;
	2)
	 set_storage ;;
	3)
	 set_2375 ;;
	4)
	 set_2376 ;;
	5)
	 remove ;;
	6)
	 test_function ;;
	*)
	 clear
	 echo "Sorry, wrong selection";;
	esac
done
clear

