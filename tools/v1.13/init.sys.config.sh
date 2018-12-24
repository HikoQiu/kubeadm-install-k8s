#!/bin/sh

vhost="m01 m02 m03 n01 n02"


# 新建 iptable 配置修改文件
cat <<EOF >  net.iptables.k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

for h in $vhost
do

  echo "--> $h"

  # 1. 关闭 swap 分区
  # kubelet 不关闭，kubelet 无法启动
  # 也可以通过将参数 --fail-swap-on 设置为 false 来忽略 swap on
  ssh kube@$h "sudo swapoff -a"
  echo "sudo swapoff -a -- ok"

  # 防止开机自动挂载 swap 分区，注释掉配置
  ssh kube@$h "sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab"
  echo "Comment swap config file modified -- ok"
  

  # 2. 关闭 SELinux
  # 否则后续 k8s 挂载目录时可能报错：Permission Denied
  ssh kube@$h "sudo setenforce 0"
  echo "sudo setenforce 0 -- ok"

  # 防止开机启动开启，修改 SELINUX 配置
  ssh kube@$h "sudo sed -i s'/SELINUX=enforcing/SELINUX=disabled'/g /etc/selinux/config"
  echo "Disabled selinux -- ok"

  # 3. 配置 iptables
  scp net.iptables.k8s.conf kube@$h:~
  ssh kube@$h "sudo mv net.iptables.k8s.conf /etc/sysctl.d/ && sudo sysctl --system"

  
  # 安装 wget 
  ssh kube@$h "sudo yum install -y wget"

done
