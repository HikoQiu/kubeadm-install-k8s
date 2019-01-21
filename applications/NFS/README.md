NFS： Network File System
---

NFS（Network File System）即网络文件系统，是FreeBSD支持的文件系统中的一种，它允许网络中的计算机之间通过TCP/IP网络共享资源。

为了后面操作 k8s 配置 PV 和 PVC，这里搭建一个供测试的 NFS 服务器。

## 1. 环境

操作系统：Centos 7  
安装： nfs-utils 和 rpcbind
服务器：nfs01（NFS 服务器）和 ing01（挂载 NFS 目录的客户端所在服务器）


查看本地是否已安装

```
[kube@nfs01 ~]$ rpm -qa nfs-utils
nfs-utils-1.3.0-0.61.el7.x86_64

[kube@nfs01 ~]$ rpm -qa rpcbind
rpcbind-0.2.0-47.el7.x86_64

```

如果未安装，执行以下命令安装：

```
sudo yum install -y nfs-utils

sudo yum install -y rpcbind
```

## 2. 启动服务

### 2.1 rpcbind 

默认情况 rpcbind 服务是已经启动的（端口：111），如下：

```
[kube@nfs01 ~]$ ss -an| grep 111
udp    UNCONN     0      0         *:111                   *:*                  
udp    UNCONN     0      0        :::111                  :::*                  
tcp    LISTEN     0      128       *:111                   *:*                  
tcp    LISTEN     0      128      :::111                  :::* 
```

添加开机启动 rpcbind：`sudo systemctl enable rpcbind`

### 2.2 nfs 服务

通过 `sudo systemctl start nfs` 启动 nfs 服务，如下：
```
[kube@nfs01 ~]$ sudo systemctl start nfs
[kube@nfs01 ~]$ sudo systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; disabled; vendor preset: disabled)
   Active: active (exited) since Mon 2019-01-21 03:32:14 UTC; 2min 48s ago
  Process: 5318 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl restart gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 5302 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 5301 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 5302 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

Jan 21 03:32:14 nfs01 systemd[1]: Starting NFS server and services...
Jan 21 03:32:14 nfs01 systemd[1]: Started NFS server and services.

```

添加开机启动 nfs：`sudo systemctl enable nfs`

### 2.3 验证

通过 `rpcinfo -p {IP}` 查看

```
[kube@nfs01 ~]$ rpcinfo -p 192.168.33.50  | grep nfs
    100003    3   tcp   2049  nfs
    100003    4   tcp   2049  nfs
    100227    3   tcp   2049  nfs_acl
    100003    3   udp   2049  nfs
    100003    4   udp   2049  nfs
    100227    3   udp   2049  nfs_acl
```

服务正常运行。


## 3. 使用 NFS 挂载

### 3.1 服务端添加共享目录

编辑 /etc/exports，添加以下配置，如下：

```
[kube@nfs01 ~]$ cat /etc/exports
/data 192.168.33.0/24(rw,async)
```

备注，/etc/exports 格式，如下：

```  

格式：[共享的目录] [主机名或IP(参数,参数)]

当将同一目录共享给多个客户机，但对每个客户机提供的权限不同时，可以如下配置： 

[共享的目录] [主机名1或IP1(参数1,参数2)] [主机名2或IP2(参数3,参数4)]

第一列：共享的目录，也就是想共享到网络中的文件系统；

第二列：可访问网络/主机

可以是 IP、主机名（域名）、网段、通配符等，如下：
192.168.152.13 指定 IP 地址的主机 
nfsclient.test.com 指定域名的主机 
192.168.1.0/24 指定网段中的所有主机 
*.test.com        指定域下的所有主机 
*                       所有主机 

第三列：共享参数

下面是一些NFS共享的常用参数： 
 ro                只读访问 
 rw                读写访问 
 sync              所有数据在请求时写入共享 
 async             NFS在写入数据前可以相应请求 
 secure            NFS通过1024以下的安全TCP/IP端口发送 
 insecure          NFS通过1024以上的端口发送 
 wdelay            如果多个用户要写入NFS目录，则归组写入（默认） 
 no_wdelay         如果多个用户要写入NFS目录，则立即写入，当使用async时，无需此设置。 
 Hide              在NFS共享目录中不共享其子目录 
 no_hide           共享NFS目录的子目录 
 subtree_check     如果共享/usr/bin之类的子目录时，强制NFS检查父目录的权限（默认） 
 no_subtree_check  和上面相对，不检查父目录权限 
 all_squash        共享文件的UID和GID映射匿名用户anonymous，适合公用目录。 
 no_all_squash     保留共享文件的UID和GID（默认） 
 root_squash       root 用户的所有请求映射成如 anonymous 用户一样的权限（默认） 
 no_root_squas     root 用户具有根目录的完全管理访问权限 
 anonuid=xxx       指定NFS服务器/etc/passwd文件中匿名用户的UID 

例如可以编辑/etc/exports为： 
/tmp　　　　　*(rw,no_root_squash) 
/home/public　192.168.0.*(rw)　　 *(ro) 
/home/test　　192.168.0.100(rw) 
/home/linux　 *.the9.com(rw,all_squash,anonuid=40,anongid=40)

```


创建 /data 目录，如下

```
[kube@nfs01 ~]$ sudo mkdir -p /data
[kube@nfs01 ~]$ sudo chown -R nfsnobody.nfsnobody /data

```

重启 nfs 服务，如下：

```
[kube@nfs01 ~]$ sudo systemctl restart nfs
[kube@nfs01 ~]$ showmount -e localhost
Export list for localhost:
/data 192.168.33.0/24
```

通过 showmount -e localhost 查看生效的配置。


### 3.2 客户端挂载 NFS 目录

客户端选择的虚拟机是: ing01

```
[kube@ing01 ~]$ showmount -e 192.168.33.50
Export list for 192.168.33.50:
/data 192.168.33.0/24

[kube@ing01 nfs01]$ sudo mkdir -p /mnt/nfs01

[kube@ing01 nfs01]$ sudo mount -t nfs 192.168.33.50:/data /mnt/nfs01

```

### 3.3 验证

在 nfs 服务器（nfs01）的 /data 目录下 新建 hello.txt 文件，然后到客户端所在服务器（ing01）验证挂载的 NFS 目录是否有 hello.txt


nfs 服务器上的 /data 目录：
```
[kube@nfs01 data]$ hostname
nfs01
[kube@nfs01 data]$ pwd
/data
[kube@nfs01 data]$ ls
hello.txt
```

客户端上的 /mnt/nfs-01 目录：
```
[kube@ing01 mnt]$ hostname
ing01
[kube@ing01 mnt]$ pwd
/mnt
[kube@ing01 mnt]$ ls
nfs01
```

到这里，配置已经完成。