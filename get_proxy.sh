#!/bin/bash

# 检查 config.yaml 文件是否存在
if [[ ! -f config.yaml ]]; then
    echo "未找到 config.yaml 文件，脚本终止。"
    exit -1
else
    echo "现在将 config.yaml 移动到 mihomo 文件夹中。"
    # 移动 config.yaml 文件到 mihomo 文件夹
    mkdir -p mihomo
    mv config.yaml mihomo/
fi

# 获取最新版本号的函数
get_latest_release() {
    repo_url=$1
    api_url="${repo_url/github.com/api.github.com\/repos}/releases/latest"
    response=$(curl -s $api_url)
    if echo $response | grep -q '"message": "Not Found"'; then
        echo "无法获取最新版本信息"
        return 1
    else
        latest_version=$(echo $response | grep -oP '"tag_name": "\K[^"]+')
        echo $latest_version
        return 0
    fi
}

# 指定仓库 URL
mihomo_repo_url="https://github.com/MetaCubeX/mihomo"
maxmind_repo_url="https://github.com/Dreamacro/maxmind-geoip"

# 获取最新版本号
mihomo_latest_version=$(get_latest_release $mihomo_repo_url)
maxmind_latest_version=$(get_latest_release $maxmind_repo_url)

if [[ -z $mihomo_latest_version || -z $maxmind_latest_version ]]; then
    echo "无法获取最新版本信息，脚本终止"
    exit 1
fi

# 进入 mihomo 目录
cd mihomo

# 下载并解压 mihomo 文件
wget "https://mirror.ghproxy.com/https://github.com/MetaCubeX/mihomo/releases/download/$mihomo_latest_version/mihomo-linux-amd64-$mihomo_latest_version.gz"
gzip -d "mihomo-linux-amd64-$mihomo_latest_version.gz"

# 下载 maxmind geoip 数据库文件
wget "https://mirror.ghproxy.com/https://github.com/Dreamacro/maxmind-geoip/releases/download/$maxmind_latest_version/Country.mmdb"

# 授予执行权限
chmod +x "mihomo-linux-amd64-$mihomo_latest_version"

# 在后台运行 mihomo
./mihomo-linux-amd64-$mihomo_latest_version -d . &


# 从 config.yaml 文件中读取 mixed-port 值
mixed_port=$(grep "mixed-port:" config.yaml | awk '{print $2}')

# 检查是否成功读取 mixed-port 值
if [[ -z $mixed_port ]]; then
    echo "未能从 config.yaml 中读取 mixed-port 值。"
    exit 1
fi

# 创建新的 Bash 脚本文件并写入环境变量配置
cat <<EOL > set_proxy.sh
#!/bin/bash
export https_proxy=http://127.0.0.1:$mixed_port/
export http_proxy=http://127.0.0.1:$mixed_port/
EOL

# 设置新脚本文件的可执行权限
chmod +x set_proxy.sh

# 提示完成
echo "*********************************"
echo "*********************************"
echo "*********************************"
echo "*********************************"
echo "*********************************"
echo "set_proxy.sh 已创建，包含 mixed-port: $mixed_port"


# 提示用户进入 mihomo 文件夹设置代理
echo "*********************************"
echo "请进入 mihomo 文件夹后执行以下操作："
echo "*********************************"
echo "运行 'source set_proxy.sh' 或 '. set_proxy.sh' 以设置代理环境变量。"
echo "*********************************"
echo "*********************************"
echo "*********************************"
echo "*********************************"
echo "*********************************"

