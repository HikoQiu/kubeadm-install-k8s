#!/bin/sh

# m01 的 IP
masterIp=192.168.33.10

vhost=(m02 m03)
vhostIP=(192.168.33.11 192.168.33.12)

## 遍历其他 master 主机名和对应 IP
## 执行启动 kubelet、将 etcd 加入集群、启动kube-apiserver、kube-controller-manager、kube-scheduler
for i in `seq 0 $((${#vhost[*]}-1))`
do

  h=${vhost[${i}]} 
  ip=${vhostIP[${i}]}


  # 1. 启动 kubelet
  ssh kube@$h "sudo kubeadm init phase certs all --config kubeadm-config.${h}.yaml"
  ssh kube@$h "sudo kubeadm init phase etcd local --config kubeadm-config.${h}.yaml"
  ssh kube@$h "sudo kubeadm init phase kubeconfig kubelet --config kubeadm-config.${h}.yaml"
  ssh kube@$h "sudo kubeadm init phase kubelet-start --config kubeadm-config.${h}.yaml"

  # 2. 将该节点的 etcd 加入集群
  ssh kube@$h "kubectl exec -n kube-system etcd-m01 -- etcdctl --ca-file /etc/kubernetes/pki/etcd/ca.crt --cert-file /etc/kubernetes/pki/etcd/peer.crt --key-file /etc/kubernetes/pki/etcd/peer.key --endpoints=https://${masterIp}:2379 member add $h https://${ip}:2380"

  # 3. 启动其他 kube-apiserver、kube-controller-manager、kube-scheduler
  ssh kube@$h "sudo kubeadm init phase kubeconfig all --config kubeadm-config.${h}.yaml"
  ssh kube@$h "sudo kubeadm init phase control-plane all --config kubeadm-config.${h}.yaml"

  # 4. 将该节点标记为 master 节点
  ssh kube@$h "sudo kubeadm init phase mark-control-plane --config kubeadm-config.${h}.yaml"

done

