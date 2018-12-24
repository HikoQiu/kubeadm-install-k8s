#!/bin/sh

## 1. 配置参数 
## vhost 主机名和 vhostIP IP 一一对应
vhost=(m01 m02 m03)
vhostIP=(192.168.33.10 192.168.33.11 192.168.33.12)

domain=api.k8s.hiko.im

## etcd 初始化 m01 m02 m03 集群配置
etcdInitCluster=(
m01=https://192.168.33.10:2380
m01=https://192.168.33.10:2380,m02=https://192.168.33.11:2380
m01=https://192.168.33.10:2380,m02=https://192.168.33.11:2380,m03=https://192.168.33.12:2380
)

## etcd 初始化时，m01 m02 m03 分别的初始化集群状态
initClusterStatus=(
new
existing
existing
)


## 2.遍历 master 主机名和对应 IP
## 生成对应的 kubeadmn 配置文件 
for i in `seq 0 $((${#vhost[*]}-1))`
do

h=${vhost[${i}]} 
ip=${vhostIP[${i}]}

echo "--> $h - $ip"
  
## 生成 kubeadm 配置模板
cat <<EOF > kubeadm-config.$h.yaml
apiVersion: kubeadm.k8s.io/v1beta1
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: $ip
  bindPort: 6443
---
apiVersion: kubeadm.k8s.io/v1beta1
kind: ClusterConfiguration
kubernetesVersion: v1.13.1

# 指定阿里云镜像仓库
imageRepository: registry.aliyuncs.com/google_containers

# apiServerCertSANs 填所有的 masterip、lbip、其它可能需要通过它访问 apiserver 的地址、域名或主机名等，
# 如阿里fip，证书中会允许这些ip
# 这里填一个自定义的域名
apiServer:
  certSANs:
  - "$domain"
controlPlaneEndpoint: "$domain:6443"

## Etcd 配置
etcd:
  local:
    extraArgs:
      listen-client-urls: "https://127.0.0.1:2379,https://$ip:2379"
      advertise-client-urls: "https://$ip:2379"
      listen-peer-urls: "https://$ip:2380"
      initial-advertise-peer-urls: "https://$ip:2380"
      initial-cluster: "${etcdInitCluster[${i}]}"
      initial-cluster-state: ${initClusterStatus[${i}]}
    serverCertSANs:
      - $h
      - $ip
    peerCertSANs:
      - $h
      - $ip
networking:
  podSubnet: "10.244.0.0/16"

EOF

echo "kubeadm-config.$h.yaml created ... ok"

## 3. 分发到其他 master 机器 
scp kubeadm-config.$h.yaml kube@$h:~
echo "scp kubeadm-config.$h.yaml ... ok"

done
