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


备注：由于国内无法访问默认的 tiller 镜像，因此这里使用阿里云提供的国内镜像。

```
helm init -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.12.2 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
```


使用 `helm init` 进行初始化，如下：

```
[kube@m01 helm]$ helm init -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.12.2 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
Creating /home/kube/.helm 
Creating /home/kube/.helm/repository 
Creating /home/kube/.helm/repository/cache 
Creating /home/kube/.helm/repository/local 
Creating /home/kube/.helm/plugins 
Creating /home/kube/.helm/starters 
Creating /home/kube/.helm/cache/archive 
Creating /home/kube/.helm/repository/repositories.yaml 
Adding stable repo with URL: https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
Adding local repo with URL: http://127.0.0.1:8879/charts 
$HELM_HOME has been configured at /home/kube/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
To prevent this, run `helm init` with the --tiller-tls-verify flag.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
```


备注：升级可以使用：`helm init --upgrade -i registry.cn-hangzhou.aliyuncs.com/google_containers/tiller:v2.12.2 --stable-repo-url https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts`

## 3. 验证

`helm version` 将看到 helm 客户端和服务端版本。

```
[kube@m01 ~]$ helm version
Client: &version.Version{SemVer:"v2.12.2", GitCommit:"7d2b0c73d734f6586ed222a567c5d103fed435be", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.12.2", GitCommit:"7d2b0c73d734f6586ed222a567c5d103fed435be", GitTreeState:"clean"}
```

`helm search` 查看相关可用 chart，如：

```
[kube@m01 ~]$ helm search mysql
NAME                            	CHART VERSION	APP VERSION	DESCRIPTION                                                 
stable/mysql                    	0.13.0       	5.7.14     	Fast, reliable, scalable, and easy to use open-source rel...
stable/mysqldump                	2.0.2        	2.0.0      	A Helm chart to help backup MySQL databases using mysqldump 
stable/prometheus-mysql-exporter	0.2.1        	v0.11.0    	A Helm chart for prometheus mysql exporter with cloudsqlp...
stable/percona                  	0.3.4        	5.7.17     	free, fully compatible, enhanced, open source drop-in rep...
stable/percona-xtradb-cluster   	0.6.1        	5.7.19     	free, fully compatible, enhanced, open source drop-in rep...
stable/phpmyadmin               	2.0.3        	4.8.4      	phpMyAdmin is an mysql administration frontend              
stable/gcloud-sqlproxy          	0.6.1        	1.11       	DEPRECATED Google Cloud SQL Proxy                           
stable/mariadb                  	5.4.3        	10.1.37    	Fast, reliable, scalable, and easy to use open-source rel...
```

### 3.1 修改 stable charts 源

由于网络原因，这里讲默认的 stable charts 修改为阿里云提供的 charts，如下：

```
[kube@m01 volumns]$ helm repo list
NAME    URL                                             
stable  https://kubernetes-charts.storage.googleapis.com
local   http://127.0.0.1:8879/charts                    
[kube@m01 volumns]$ helm repo list
NAME    URL                                             
stable  https://kubernetes-charts.storage.googleapis.com
local   http://127.0.0.1:8879/charts                    
[kube@m01 volumns]$ helm repo remove stable
"stable" has been removed from your repositories
[kube@m01 volumns]$ helm repo add stable https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
"stable" has been added to your repositories
[kube@m01 volumns]$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Skip local chart repository
...Successfully got an update from the "stable" chart repository
Update Complete. ⎈ Happy Helming!⎈ 
[kube@m01 volumns]$ helm repo list
NAME    URL                                                   
local   http://127.0.0.1:8879/charts                          
stable  https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts
```

## 4. 问题排查

### 4.1 *** is forbidden

通过 `helm list` 查看集群中安装的 charts，报错：
```
[kube@m01 ~]$ helm list
Error: configmaps is forbidden: User "system:serviceaccount:kube-system:default" cannot list resource "configmaps" in API group "" in the namespace "kube-system"
```

解决方式，参考：https://github.com/helm/helm/issues/3130

自Kubernetes 1.6版本开始，API Server启用了RBAC授权。而目前的Tiller部署没有定义授权的ServiceAccount，这会导致访问API Server时被拒绝。我们可以采用如下方法，明确为Tiller部署添加授权。

```
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
```

## 5. 常用命令

```
# 卸载helm服务端
helm reset 或 helm reset --force

# 查看仓库中所有可用 Helm charts
helm search 

# 更新 charts 列表
helm repo update



```