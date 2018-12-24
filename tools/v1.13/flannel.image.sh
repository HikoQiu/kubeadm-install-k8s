#!/bin/sh

vhost="m01 m02 m03 n01 n02"

for h in $vhost
do

echo "---> $h"

# 安装 Pod 网络插件
# 这里选择的是 flannel v0.10.0 版本
# 如果想用其他版本，可以替换url

# 备注：kube-flannel.yml(下面配置的 yaml)中指定的是 quay.io 的镜像。
# 因为国内无法拉 quay.io 的镜像，所以这里从 docker hub 拉去相同镜像，
# 然后打 tag 为 kube-flannel.yml 中指定的 quay.io/coreos/flannel:v0.10.0-amd64
# 再备注：flannel 是所有节点(master 和 node)都需要的网络组件，所以后面其他节点也可以通过相同方式安装

sudo docker pull jmgao1983/flannel:v0.10.0-amd64
sudo docker tag jmgao1983/flannel:v0.10.0-amd64 quay.io/coreos/flannel:v0.10.0-amd64


done
