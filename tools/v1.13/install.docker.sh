#!/bin/sh

vhosts="m01 m02 m03 n01 n02 ing01"

for h in $vhosts 
do
    echo "Install Docker for $h"
    ssh kube@$h "sudo yum install -y docker && sudo systemctl enable docker && sudo systemctl start docker"
done
