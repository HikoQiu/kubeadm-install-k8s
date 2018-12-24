#!/bin/sh

# 安装 flannel
# wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f ./kube-flannel.yml
