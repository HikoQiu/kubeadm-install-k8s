#!/bin/sh

vhost="m01"

for h in $vhost;do 
  echo "Exec sudo kubeadm init for $h"
  ssh kube@$h "sudo kubeadm init  --config kubeadm-config.$h.yaml"
done

