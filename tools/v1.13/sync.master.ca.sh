#!/bin/sh

vhost="m02 m03"
usr=root

who=`whoami`
if [[ "$who" != "$usr" ]];then
  echo "请使用 root 用户执行, 或者 sudo ./sync.master.ca.sh"
  exit 1
fi

echo $who

# 需要从 m01 拷贝的 ca 文件
caFiles=(
/etc/kubernetes/pki/ca.crt
/etc/kubernetes/pki/ca.key
/etc/kubernetes/pki/sa.key
/etc/kubernetes/pki/sa.pub
/etc/kubernetes/pki/front-proxy-ca.crt
/etc/kubernetes/pki/front-proxy-ca.key
/etc/kubernetes/pki/etcd/ca.crt
/etc/kubernetes/pki/etcd/ca.key
/etc/kubernetes/admin.conf
)

pkiDir=/etc/kubernetes/pki/etcd
for h in $vhost 
do

  ssh ${usr}@$h "mkdir -p $pkiDir"
  
  echo "Dirs for ca scp created, start to scp..."

  # scp 文件到目标机
  for f in ${caFiles[@]}
  do 
    echo "scp $f ${usr}@$h:$f"
    scp $f ${usr}@$h:$f
  done

  echo "Ca files transfered for $h ... ok"
done
