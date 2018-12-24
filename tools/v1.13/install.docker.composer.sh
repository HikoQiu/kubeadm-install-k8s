#!/bin/sh

vhost="m01 m02 m03"

for h in $vhost
do
  ssh kube@$h "sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose"
  ssh kube@$h "sudo chmod +x /usr/local/bin/docker-compose"
  ssh kube@$h "docker-compose --version"
done
