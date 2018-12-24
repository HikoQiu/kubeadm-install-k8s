#!/bin/sh

vhost="m01 m02 m03"

for h in $vhost;do 
  echo "Exec sudo kubeadm reset for $h"
  ssh kube@$h "sudo kubeadm reset --force"
done

