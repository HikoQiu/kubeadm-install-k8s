#!/bin/sh

vhost="m01 m02 m03 n01 n02"

master="m01 m02 m03"
nodes="n01 n02"

## 1. 阿里云 kubernetes 仓库
cat <<EOF > kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

mvCmd="sudo cp ~/kubernetes.repo /etc/yum.repos.d/"
for h in $vhost
do
  echo "Setup kubernetes repository for $h"
  scp ./kubernetes.repo kube@$h:~
  ssh kube@$h $mvCmd
done

## 2. 安装 kubelet kubeadm kubectl
installCmd="sudo yum install -y kubelet kubeadm kubectl && sudo systemctl enable kubelet"
for h in $vhost
do
  echo "Install kubelet kubeadm kubectl for : $h"
  ssh kube@$h $installCmd
done

## 3. 启动 m01 的 kubelet
sudo systemctl start kubelet
