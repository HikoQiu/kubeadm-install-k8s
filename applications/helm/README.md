Helm
---

- [helm 官网](https://helm.sh/)
- [官方 Helm 下载和安装](https://docs.helm.sh/using_helm/#installing-helm)

可以从官方文档中查看 helm 安装方式，下面演示具体操作：

## 1. 下载和安装 helm

这里使用的是 [helm-v2.12.2-linux-amd64.tar.gz](https://storage.googleapis.com/kubernetes-helm/helm-v2.12.2-linux-amd64.tar.gz) 这个版本的压缩包。

将压缩包下载到 m01 机器，解压并将 helm 可执行文件复制到 `/usr/local/bin` 目录，详细操作如下：

```

# 下载 helm 压缩包
[kube@m01 helm]$ wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.2-linux-amd64.tar.gz
--2019-01-10 11:06:16--  https://storage.googleapis.com/kubernetes-helm/helm-v2.12.2-linux-amd64.tar.gz
Resolving storage.googleapis.com (storage.googleapis.com)... 172.217.163.240, 2404:6800:4005:803::2010
Connecting to storage.googleapis.com (storage.googleapis.com)|172.217.163.240|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 22724805 (22M) [application/x-tar]
Saving to: ‘helm-v2.12.2-linux-amd64.tar.gz’

100%[===============================================================================================================>] 22,724,805   470KB/s   in 67s    

2019-01-10 11:07:28 (332 KB/s) - ‘helm-v2.12.2-linux-amd64.tar.gz’ saved [22724805/22724805]


# 解压 helm 压缩包
[kube@m01 helm]$ tar zxvf helm-v2.12.2-linux-amd64.tar.gz 
linux-amd64/
linux-amd64/tiller
linux-amd64/README.md
linux-amd64/helm
linux-amd64/LICENSE


# 将 helm 可执行文件复制到 /usr/local/bin
[kube@m01 helm]$ sudo cp linux-amd64/helm /usr/local/bin/


# 验证
[kube@m01 helm]$ helm help
The Kubernetes package manager

To begin working with Helm, run the 'helm init' command:

	$ helm init

...
...

```

到这里 helm 就安装完成，为了让 helm 能正常工作，需要安装 tiller 和初始化。

## 2. 安装 tiller


在 kubernetes 集群里安装 tiller 很简单，helm 官方提供 `helm init` 进行 helm 初始化。`helm init` 主要做以下几个事情：

- i. 验证 helm 的本地环境是否配置正确
- ii. 像 kubectl 连接集群的方式连接到 kubernetes 集群
- iii. 当连接成功，安装 tiller 到 kubernetes 集群的 kube-system 命名空间下。

`helm init` 进行初始化，如下：

```
[kube@m01 helm]$ helm init
Creating /home/kube/.helm 
Creating /home/kube/.helm/repository 
Creating /home/kube/.helm/repository/cache 
Creating /home/kube/.helm/repository/local 
Creating /home/kube/.helm/plugins 
Creating /home/kube/.helm/starters 
Creating /home/kube/.helm/cache/archive 
Creating /home/kube/.helm/repository/repositories.yaml 
Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com
Adding local repo with URL: http://127.0.0.1:8879/charts 
$HELM_HOME has been configured at /home/kube/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
```

