#!/bin/sh

vhost="m01 m02 m03"

for h in $vhost;do 
  echo "Pull image for $h -- begings"
  sudo kubeadm config images pull --config kubeadm-config.$h.yaml
done

