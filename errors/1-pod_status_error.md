Pod 状态为 Error/CrashLoopBackOff
---

##1. 背景

本地 k8s 集群所在的宿主机关机重启后，个别 Pod 状态异常，具体如下：

```
[kube@m01 ~]$ kubectl get pods -n kube-system -owide
NAME                                    READY   STATUS    RESTARTS   AGE     IP              NODE    NOMINATED NODE   READINESS GATES
coredns-6c67f849c7-dkzqf                1/1     Running   1          7d22h   10.244.3.85     n01     <none>           <none>
coredns-6c67f849c7-zgf9h                1/1     Running   1          7d22h   10.244.0.15     m01     <none>           <none>
etcd-m01                                1/1     Running   23         27d     192.168.33.10   m01     <none>           <none>
etcd-m02                                1/1     Running   14         27d     192.168.33.11   m02     <none>           <none>
etcd-m03                                1/1     Running   10         27d     192.168.33.12   m03     <none>           <none>
kube-apiserver-m01                      1/1     Running   26         27d     192.168.33.10   m01     <none>           <none>
kube-apiserver-m02                      1/1     Running   4          27d     192.168.33.11   m02     <none>           <none>
kube-apiserver-m03                      1/1     Running   12         27d     192.168.33.12   m03     <none>           <none>
kube-controller-manager-m01             1/1     Running   8          27d     192.168.33.10   m01     <none>           <none>
kube-controller-manager-m02             1/1     Running   1          27d     192.168.33.11   m02     <none>           <none>
kube-controller-manager-m03             1/1     Running   4          27d     192.168.33.12   m03     <none>           <none>
kube-flannel-ds-amd64-7b86z             1/1     Running   3          27d     192.168.33.10   m01     <none>           <none>
kube-flannel-ds-amd64-98qks             1/1     Running   3          27d     192.168.33.12   m03     <none>           <none>
kube-flannel-ds-amd64-dvgdn             0/1     Error     5          3m22s   192.168.33.21   n02     <none>           <none>
kube-flannel-ds-amd64-ljcdp             1/1     Running   2          27d     192.168.33.11   m02     <none>           <none>
kube-flannel-ds-amd64-s8vzs             1/1     Running   4          26d     192.168.33.20   n01     <none>           <none>
kube-flannel-ds-amd64-v5lkv             0/1     CrashLoopBackOff     9          23d     192.168.33.40   ing01   <none>           <none>
kube-proxy-485hs                        1/1     Running   2          23d     192.168.33.40   ing01   <none>           <none>
kube-proxy-c4j4r                        1/1     Running   2          26d     192.168.33.20   n01     <none>           <none>
kube-proxy-krnjq                        1/1     Running   2          27d     192.168.33.10   m01     <none>           <none>
kube-proxy-n9s8c                        1/1     Running   3          26d     192.168.33.21   n02     <none>           <none>
kube-proxy-scb25                        1/1     Running   2          27d     192.168.33.12   m03     <none>           <none>
kube-proxy-xp4rj                        1/1     Running   1          27d     192.168.33.11   m02     <none>           <none>
kube-scheduler-m01                      1/1     Running   8          27d     192.168.33.10   m01     <none>           <none>
kube-scheduler-m02                      1/1     Running   1          27d     192.168.33.11   m02     <none>           <none>
kube-scheduler-m03                      1/1     Running   2          27d     192.168.33.12   m03     <none>           <none>
kubernetes-dashboard-847f8cb7b8-qdgkk   0/1     CrashLoopBackOff     1          26d     <none>          n02     <none>           <none>
metrics-server-8658466f94-sr479         1/1     Running   2          26d     10.244.3.83     n01     <none>           <none>
tiller-deploy-7d6b75487c-46x8x          1/1     Running   1          7d1h    10.244.3.88     n01     <none>           <none>

```

##2. 问题排查

查看所有节点状态：

```
[kube@m01 ~]$ kubectl get nodes
NAME    STATUS     ROLES    AGE   VERSION
ing01   Ready      <none>   23d   v1.13.1
m01     Ready      master   28d   v1.13.1
m02     NotReady   master   27d   v1.13.1
m03     Ready      master   27d   v1.13.1
n01     Ready      <none>   26d   v1.13.1
n02     Ready      <none>   26d   v1.13.1
```


通过 `kubectl describe pod` 查看具体 Pod 信息：

查看 kube-flannel：

```
[kube@m01 ~]$ kubectl describe pod  kube-flannel-ds-amd64-dvgdn -n kube-system
Name:               kube-flannel-ds-amd64-dvgdn
Namespace:          kube-system
Priority:           0
PriorityClassName:  <none>
Node:               n02/192.168.33.21
Start Time:         Fri, 18 Jan 2019 02:55:54 +0000
Labels:             app=flannel
                    controller-revision-hash=6688cccc54
                    pod-template-generation=1
                    tier=node
Annotations:        <none>

...

Events:
  Type     Reason     Age                    From               Message
  ----     ------     ----                   ----               -------
  Normal   Scheduled  7m22s                  default-scheduler  Successfully assigned kube-system/kube-flannel-ds-amd64-dvgdn to n02
  Normal   Pulled     7m21s                  kubelet, n02       Container image "quay.io/coreos/flannel:v0.10.0-amd64" already present on machine
  Normal   Created    7m21s                  kubelet, n02       Created container
  Normal   Started    7m21s                  kubelet, n02       Started container
  Normal   Created    6m34s (x4 over 7m20s)  kubelet, n02       Created container
  Normal   Started    6m34s (x4 over 7m20s)  kubelet, n02       Started container
  Normal   Pulled     5m45s (x5 over 7m20s)  kubelet, n02       Container image "quay.io/coreos/flannel:v0.10.0-amd64" already present on machine
  Warning  BackOff    2m8s (x26 over 7m17s)  kubelet, n02       Back-off restarting failed container
```


启动日志
```
[kube@m01 ~]$ kubectl logs  kube-flannel-ds-amd64-dvgdn -n kube-system 
I0118 03:32:44.520004       1 main.go:488] Using interface with name eth1 and address 192.168.33.21
I0118 03:32:44.520061       1 main.go:505] Defaulting external address to interface address (192.168.33.21)
E0118 03:32:44.521067       1 main.go:232] Failed to create SubnetManager: error retrieving pod spec for 'kube-system/kube-flannel-ds-amd64-dvgdn': Get https://10.96.0.1:443/api/v1/namespaces/kube-system/pods/kube-flannel-ds-amd64-dvgdn: dial tcp 10.96.0.1:443: connect: network is unreachable
```

查看 dashboard：

```

[kube@m01 ~]$ kubectl describe pod kubernetes-dashboard-847f8cb7b8-qdgkk -n kube-system
Name:               kubernetes-dashboard-847f8cb7b8-qdgkk
Namespace:          kube-system
Priority:           0
PriorityClassName:  <none>
Node:               n02/192.168.33.21
Start Time:         Sun, 23 Dec 2018 17:35:49 +0000
Labels:             k8s-app=kubernetes-dashboard
                    pod-template-hash=847f8cb7b8

...

Events:
  Type     Reason                  Age                   From          Message
  ----     ------                  ----                  ----          -------
  Warning  FailedCreatePodSandBox  21m                   kubelet, n02  Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "08da675dd1383279956350886ba2187344f7d081cf16985b82659952a8ac8015" network for pod "kubernetes-dashboard-847f8cb7b8-qdgkk": NetworkPlugin cni failed to set up pod "kubernetes-dashboard-847f8cb7b8-qdgkk_kube-system" network: open /run/flannel/subnet.env: no such file or directory
  Warning  FailedCreatePodSandBox  21m                   kubelet, n02  Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "0e2b632f026c842d10f7d30cfaaac239c179de43c2d1ef5bc5dbc90693d31c09" network for pod "kubernetes-dashboard-847f8cb7b8-qdgkk": NetworkPlugin cni failed to set up pod "kubernetes-dashboard-847f8cb7b8-qdgkk_kube-system" network: open /run/flannel/subnet.env: no such file or directory
  Warning  FailedCreatePodSandBox  21m                   kubelet, n02  Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "4ebd76003f1a27514c8c7b0cde24f737efef808f56c28f3df323f3447d331266" network for pod "kubernetes-dashboard-847f8cb7b8-qdgkk": NetworkPlugin cni failed to set up pod "kubernetes-dashboard-847f8cb7b8-qdgkk_kube-system" network: open /run/flannel/subnet.env: no such file or directory
  Warning  FailedCreatePodSandBox  21m                   kubelet, n02  Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "7ee7082a899b32148fa937865e1ab20d18dfde8cef9394505526c2bec6c2c961" network for pod "kubernetes-dashboard-847f8cb7b8-qdgkk": NetworkPlugin cni failed to set up pod "kubernetes-dashboard-847f8cb7b8-qdgkk_kube-system" network: open /run/flannel/subnet.env: no such file or directory
  Warning  FailedCreatePodSandBox  21m                   kubelet, n02  Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "58feb9af9d51f450ec789ed9f2aabb441333377bb83dd854137165efb6bc424d" network for pod "kubernetes-dashboard-847f8cb7b8-qdgkk": NetworkPlugin cni failed to set up pod "kubernetes-dashboard-847f8cb7b8-qdgkk_kube-system" network: open /run/flannel/subnet.env: no such file or directory
  Warning  FailedCreatePodSandBox  21m                   kubelet, n02  Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "10a1eead86999d3339d36381bbd36d3ecab1ba1399874201761430560fde937d" network for pod "kubernetes-dashboard-847f8cb7b8-qdgkk": NetworkPlugin cni failed to set up pod "kubernetes-dashboard-847f8cb7b8-qdgkk_kube-system" network: open /run/flannel/subnet.env: no such file or directory
  Warning  FailedCreatePodSandBox  21m                   kubelet, n02  Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "2e99d5e688656a5e2cbf93e4f5bedd06c342e1cc9d4e30363f2e56b881ab137c" network for pod "kubernetes-dashboard-847f8cb7b8-qdgkk": NetworkPlugin cni failed to set up pod "kubernetes-dashboard-847f8cb7b8-qdgkk_kube-system" network: open /run/flannel/subnet.env: no such file or directory
  Warning  FailedCreatePodSandBox  21m                   kubelet, n02  Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "b6b50ec3aae2722e895ed9759e7c0d6f99c35c48683ce441efb52d6029042030" network for pod "kubernetes-dashboard-847f8cb7b8-qdgkk": NetworkPlugin cni failed to set up pod "kubernetes-dashboard-847f8cb7b8-qdgkk_kube-system" network: open /run/flannel/subnet.env: no such file or directory
  Warning  FailedCreatePodSandBox  21m                   kubelet, n02  Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "f21ff1077d158f2d67e4a503534e926d60a76e0dea8563502c088d549b43f222" network for pod "kubernetes-dashboard-847f8cb7b8-qdgkk": NetworkPlugin cni failed to set up pod "kubernetes-dashboard-847f8cb7b8-qdgkk_kube-system" network: open /run/flannel/subnet.env: no such file or directory
  Warning  FailedCreatePodSandBox  16m (x253 over 21m)   kubelet, n02  (combined from similar events): Failed create pod sandbox: rpc error: code = Unknown desc = failed to set up sandbox container "bef7144ab016d761d3cd7ed60793967a8e379e1e3b5a097e2e3d775acd71d21e" network for pod "kubernetes-dashboard-847f8cb7b8-qdgkk": NetworkPlugin cni failed to set up pod "kubernetes-dashboard-847f8cb7b8-qdgkk_kube-system" network: open /run/flannel/subnet.env: no such file or directory
  Normal   SandboxChanged          75s (x1005 over 22m)  kubelet, n02  Pod sandbox changed, it will be killed and re-created.
```

##3. 思考


###3.1 猜测问题出在 docker

从 kube-flannel 的错误信息（如下）中猜测，问题可能跟 docker 服务有关系（因为提示容器启动失败，容器启动是跟 docker 有关的）。

```
  Warning  BackOff    2m8s (x26 over 7m17s)  kubelet, n02       Back-off restarting failed container

```

接着去到对应的虚拟机，查看 docker 的状态和日志：

docker 状态：正常

```
[kube@n02 ~]$ sudo systemctl status docker
● docker.service - Docker Application Container Engine
   Loaded: loaded (/usr/lib/systemd/system/docker.service; enabled; vendor preset: disabled)
   Active: active (running) since Fri 2019-01-18 03:15:18 UTC; 6min ago
     Docs: http://docs.docker.com
 Main PID: 17057 (dockerd-current)
   CGroup: /system.slice/docker.service
           ├─10743 /usr/bin/docker-containerd-shim-current 18ae9a0097061645324d0677bc25d028de1ce55d61e1fe0cc9b5319770a2f257 /var/run/docker/libcontain...
           ├─10798 /usr/bin/docker-containerd-shim-current 3b0cda36376bd06f4e10a948e99a321ef70546d5738ea84f46a0e3bf6c57e669 /var/run/docker/libcontain...
           ├─10919 /usr/libexec/docker/docker-runc-current --systemd-cgroup=true kill --all 18ae9a0097061645324d0677bc25d028de1ce55d61e1fe0cc9b5319770...
           ├─10925 /usr/bin/docker-containerd-current -l unix:///var/run/docker/libcontainerd/docker-containerd.sock --metrics-interval=0 --start-time...
           ├─17057 /usr/bin/dockerd-current --add-runtime docker-runc=/usr/libexec/docker/docker-runc-current --default-runtime=docker-runc --exec-opt...
           ├─17062 /usr/bin/docker-containerd-current -l unix:///var/run/docker/libcontainerd/docker-containerd.sock --metrics-interval=0 --start-time...
           ├─17157 /usr/bin/docker-containerd-shim-current 9f8be01f0a1e540ba53c5cdd7864f6579513fabe719c034034075cefa499ab1b /var/run/docker/libcontain...
           ├─17179 /usr/bin/docker-containerd-shim-current d9db4238d634b77ee22a98f2a88a873b87017617e8bbe926e63f7707dec82135 /var/run/docker/libcontain...
           ├─17180 /usr/bin/docker-containerd-shim-current 1b63ed04989c441a9d97b9096bc81aee78ea1ecf06917afd4eef417ab69d12d7 /var/run/docker/libcontain...
           ├─17272 /usr/bin/docker-containerd-shim-current c22f257e887c537c4d2ea12cf63a3f2b7ee9839f6a61d84953082dd7c324ed23 /var/run/docker/libcontain...
           └─17320 /usr/bin/docker-containerd-shim-current 862764360d3d2f1eecda1cf41380ad45f3467aa4401dd94ca553749c2b1c7a07 /var/run/docker/libcontain...

```


docker 日志：有一些错误日志

```

[kube@n02 ~]$ sudo journalctl -exu docker | tail
Jan 18 03:29:43 n02 dockerd-current[17057]: time="2019-01-18T03:29:43.901008403Z" level=error msg="Handler for POST /v1.26/containers/55ef25f7e156ee4c0ca2c49a5a842411c9f39583097054437918d10931e9ac32/stop returned error: Container 55ef25f7e156ee4c0ca2c49a5a842411c9f39583097054437918d10931e9ac32 is already stopped"
Jan 18 03:29:43 n02 dockerd-current[17057]: time="2019-01-18T03:29:43.901256502Z" level=error msg="Handler for POST /v1.26/containers/2250b8dab37e347c545371d8b468da38e5c44231fc69ac3b0577d7baad79583c/stop returned error: Container 2250b8dab37e347c545371d8b468da38e5c44231fc69ac3b0577d7baad79583c is already stopped"
Jan 18 03:29:43 n02 dockerd-current[17057]: time="2019-01-18T03:29:43.902458062Z" level=error msg="Handler for POST /v1.26/containers/e2df7730326b9373e35ec533f755d615d4c6a654c266a43dc748a52b3df13a36/stop returned error: Container e2df7730326b9373e35ec533f755d615d4c6a654c266a43dc748a52b3df13a36 is already stopped"
Jan 18 03:29:43 n02 dockerd-current[17057]: time="2019-01-18T03:29:43.902711399Z" level=error msg="Handler for POST /v1.26/containers/2a58240e9542de339ee6cd2a81bfec298d362214088c012517cc20a75906c069/stop returned error: Container 2a58240e9542de339ee6cd2a81bfec298d362214088c012517cc20a75906c069 is already stopped"
Jan 18 03:29:43 n02 dockerd-current[17057]: time="2019-01-18T03:29:43.905909305Z" level=error msg="Handler for POST /v1.26/containers/c280a53c9a86133b3ae6ed5f6f4f35082ec4a3c2064cd716750c589ca233a22a/stop returned error: Container c280a53c9a86133b3ae6ed5f6f4f35082ec4a3c2064cd716750c589ca233a22a is already stopped"
Jan 18 03:29:43 n02 dockerd-current[17057]: time="2019-01-18T03:29:43.911192335Z" level=error msg="Handler for POST /v1.26/containers/3d8919a8bdde3a6036624081f2b288664d8feed63d80f364c394dc3ea2721f02/stop returned error: Container 3d8919a8bdde3a6036624081f2b288664d8feed63d80f364c394dc3ea2721f02 is already stopped"
Jan 18 03:29:43 n02 dockerd-current[17057]: time="2019-01-18T03:29:43.912749444Z" level=error msg="Handler for POST /v1.26/containers/1b7cd279a61dca5aeb9f2bc4e3970c199f8dcd8d8fc7301c91d35dfec4170b3a/stop returned error: Container 1b7cd279a61dca5aeb9f2bc4e3970c199f8dcd8d8fc7301c91d35dfec4170b3a is already stopped"
Jan 18 03:29:43 n02 dockerd-current[17057]: time="2019-01-18T03:29:43.914244025Z" level=error msg="Handler for POST /v1.26/containers/0fca1a5ae1dd4e2a7868a2fd01c14a3d8cdff7c7886235597cc44c085d108f20/stop returned error: Container 0fca1a5ae1dd4e2a7868a2fd01c14a3d8cdff7c7886235597cc44c085d108f20 is already stopped"
Jan 18 03:29:43 n02 dockerd-current[17057]: time="2019-01-18T03:29:43.915657895Z" level=error msg="Handler for POST /v1.26/containers/2c81b5992374f6117a9aa1d416fbda534135fdcee83eea1d1a82b0fe101d0660/stop returned error: Container 2c81b5992374f6117a9aa1d416fbda534135fdcee83eea1d1a82b0fe101d0660 is already stopped"
Jan 18 03:29:43 n02 dockerd-current[17057]: time="2019-01-18T03:29:43.918133242Z" level=error msg="Handler for POST /v1.26/containers/8b99252253f16d0a1ef393ea8fa4d4307c5239cfc3e38f6a8ac1fb0d8d7e4816/stop returned error: Container 8b99252253f16d0a1ef393ea8fa4d4307c5239cfc3e38f6a8ac1fb0d8d7e4816 is already stopped"
Jan 18 03:19:20 n02 oci-systemd-hook[26622]: systemdhook <debug>: be2596bf7571: Skipping as container command is /pause, not init or systemd
```

上面的错误日志主要是由于：

1. kebelet 请求 dockerd 对某个容器进行操作(/stop)。
2. dockerd 无法/操作容器失败，返回错误
3. dockerd 过小段时间重试
4. kebelet 重试操作，重复步骤 1


查看 n02 （kube-flannel 启动失败的虚拟机）上的 kubelet 的日志，过滤出 kube-flannel 的日志：
```
[kube@n02 ~]$ sudo journalctl -exu kubelet | tail -n1000 | grep -5 kube-flannel-ds-amd64-dvgdn
Jan 18 03:50:45 n02 kubelet[27151]: E0118 03:50:45.175182   27151 pod_workers.go:190] Error syncing pod 94bbe7f2-1acc-11e9-87c4-5254008481d5 ("kube-flannel-ds-amd64-dvgdn_kube-system(94bbe7f2-1acc-11e9-87c4-5254008481d5)"), skipping: failed to "StartContainer" for "kube-flannel" with CrashLoopBackOff: "Back-off 5m0s restarting failed container=kube-flannel pod=kube-flannel-ds-amd64-dvgdn_kube-system(94bbe7f2-1acc-11e9-87c4-5254008481d5)"
Jan 18 03:50:54 n02 kubelet[27151]: E0118 03:50:54.306705   27151 summary_sys_containers.go:45] Failed to get system container stats for "/system.slice/kubelet.service": failed to get cgroup stats for "/system.slice/kubelet.service": failed to get container info for "/system.slice/kubelet.service": unknown container "/system.slice/kubelet.service"
Jan 18 03:50:54 n02 kubelet[27151]: E0118 03:50:54.306726   27151 summary_sys_containers.go:45] Failed to get system container stats for "/system.slice/docker.service": failed to get cgroup stats for "/system.slice/docker.service": failed to get container info for "/system.slice/docker.service": unknown container "/system.slice/docker.service"
Jan 18 03:50:59 n02 kubelet[27151]: E0118 03:50:59.176183   27151 pod_workers.go:190] Error syncing pod 94bbe7f2-1acc-11e9-87c4-5254008481d5 ("kube-flannel-ds-amd64-dvgdn_kube-system(94bbe7f2-1acc-11e9-87c4-5254008481d5)"), skipping: failed to "StartContainer" for "kube-flannel" with CrashLoopBackOff: "Back-off 5m0s restarting failed container=kube-flannel pod=kube-flannel-ds-amd64-dvgdn_kube-system(94bbe7f2-1acc-11e9-87c4-5254008481d5)"
Jan 18 03:51:02 n02 kubelet[27151]: E0118 03:51:02.278816   27151 summary_sys_containers.go:45] Failed to get system container stats for "/system.slice/kubelet.service": failed to get cgroup stats for "/system.slice/kubelet.service": failed to get container info for "/system.slice/kubelet.service": unknown container "/system.slice/kubelet.service"
Jan 18 03:51:02 n02 kubelet[27151]: E0118 03:51:02.278836   27151 summary_sys_containers.go:45] Failed to get system container stats for "/system.slice/docker.service": failed to get cgroup stats for "/system.slice/docker.service": failed to get container info for "/system.slice/docker.service": unknown container "/system.slice/docker.service"
Jan 18 03:51:04 n02 kubelet[27151]: E0118 03:51:04.310172   27151 summary_sys_containers.go:45] Failed to get system container stats for "/system.slice/kubelet.service": failed to get cgroup stats for "/system.slice/kubelet.service": failed to get container info for "/system.slice/kubelet.service": unknown container "/system.slice/kubelet.service"
Jan 18 03:51:04 n02 kubelet[27151]: E0118 03:51:04.310188   27151 summary_sys_containers.go:45] Failed to get system container stats for "/system.slice/docker.service": failed to get cgroup stats for "/system.slice/docker.service": failed to get container info for "/system.slice/docker.service": unknown container "/system.slice/docker.service"
Jan 18 03:51:11 n02 kubelet[27151]: E0118 03:51:11.181258   27151 pod_workers.go:190] Error syncing pod 94bbe7f2-1acc-11e9-87c4-5254008481d5 ("kube-flannel-ds-amd64-dvgdn_kube-system(94bbe7f2-1acc-11e9-87c4-5254008481d5)"), skipping: failed to "StartContainer" for "kube-flannel" with CrashLoopBackOff: "Back-off 5m0s restarting failed container=kube-flannel pod=kube-flannel-ds-amd64-dvgdn_kube-system(94bbe7f2-1acc-11e9-87c4-5254008481d5)"
Jan 18 03:51:14 n02 kubelet[27151]: E0118 03:51:14.319367   27151 summary_sys_containers.go:45] Failed to get system container stats for "/system.slice/kubelet.service": failed to get cgroup stats for "/system.slice/kubelet.service": failed to get container info for "/system.slice/kubelet.service": unknown container "/system.slice/kubelet.service"
Jan 18 03:51:14 n02 kubelet[27151]: E0118 03:51:14.319387   27151 summary_sys_containers.go:45] Failed to get system container stats for "/system.slice/docker.service": failed to get cgroup stats for "/system.slice/docker.service": failed to get container info for "/system.slice/docker.service": unknown container "/system.slice/docker.service"

```

后来发现，有异常的虚拟机的网口信息和正常的其他节点存在较大差异，主要就是缺少 eth0 、 flannel、 cni 网络信息等：

有问题的节点：
```
[kube@n02 ~]$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN group default qlen 1000
    link/ether 52:54:00:84:81:d5 brd ff:ff:ff:ff:ff:ff
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:03:93:5b brd ff:ff:ff:ff:ff:ff
    inet 192.168.33.21/24 brd 192.168.33.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe03:935b/64 scope link 
       valid_lft forever preferred_lft forever
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:e4:77:bd:6c brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 scope global docker0
       valid_lft forever preferred_lft forever

```

正常的节点：
```
[kube@n01 ~]$ ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 52:54:00:84:81:d5 brd ff:ff:ff:ff:ff:ff
    inet 10.0.2.15/24 brd 10.0.2.255 scope global noprefixroute dynamic eth0
       valid_lft 71601sec preferred_lft 71601sec
    inet6 fe80::5054:ff:fe84:81d5/64 scope link 
       valid_lft forever preferred_lft forever
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:62:9b:79 brd ff:ff:ff:ff:ff:ff
    inet 192.168.33.20/24 brd 192.168.33.255 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fe62:9b79/64 scope link 
       valid_lft forever preferred_lft forever
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:61:22:a2:e1 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 scope global docker0
       valid_lft forever preferred_lft forever
5: flannel.1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UNKNOWN group default 
    link/ether c6:c8:6b:c9:ce:60 brd ff:ff:ff:ff:ff:ff
    inet 10.244.3.0/32 scope global flannel.1
       valid_lft forever preferred_lft forever
    inet6 fe80::c4c8:6bff:fec9:ce60/64 scope link 
       valid_lft forever preferred_lft forever
6: cni0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
    link/ether 0a:58:0a:f4:03:01 brd ff:ff:ff:ff:ff:ff
    inet 10.244.3.1/24 scope global cni0
       valid_lft forever preferred_lft forever
    inet6 fe80::2c40:1eff:fe63:b02b/64 scope link 
       valid_lft forever preferred_lft forever
7: veth780a2dff@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP group default 
    link/ether 26:a6:38:18:ba:87 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::24a6:38ff:fe18:ba87/64 scope link 
       valid_lft forever preferred_lft forever
8: veth63f08a2e@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP group default 
    link/ether 32:df:db:fe:1c:bf brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::30df:dbff:fefe:1cbf/64 scope link 
       valid_lft forever preferred_lft forever
12: veth4aab872e@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP group default 
    link/ether 86:75:90:31:d8:82 brd ff:ff:ff:ff:ff:ff link-netnsid 5
    inet6 fe80::8475:90ff:fe31:d882/64 scope link 
       valid_lft forever preferred_lft forever
13: veth01c2c6f8@if3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue master cni0 state UP group default 
    link/ether 1a:12:82:18:8a:b2 brd ff:ff:ff:ff:ff:ff link-netnsid 2
    inet6 fe80::1812:82ff:fe18:8ab2/64 scope link 
       valid_lft forever preferred_lft forever
```


根据以往的经验，问题出在 vagrant 启动虚拟机时，个别网络启动失败导致。


重启虚拟机解决。