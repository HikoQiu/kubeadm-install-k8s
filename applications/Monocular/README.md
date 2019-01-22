Monocular： Helm charts 仓库管理  WEB UI 工具
---

- [helm/monocular](https://github.com/helm/monocular)

## 1. 安装步骤

### 1.1 前置要求

- 已安装 Helm 和 Tiller
- 已安装 Nginx Ingress Controller

### 1.2 安装 Monocular

```
helm repo add monocular https://helm.github.io/monocular
helm install monocular/monocular
```

```
api:
  config:
    repos:
      - name: stable
        url: https://aliacs-app-catalog.oss-cn-hangzhou.aliyuncs.com/charts
        source: https://github.com/kubernetes/charts/tree/master/stable
      - name: incubator
        url: https://aliacs-app-catalog.oss-cn-hangzhou.aliyuncs.com/charts-incubator
        source: https://github.com/kubernetes/charts/tree/master/incubator
      - name: monocular
        url: https://kubernetes-helm.github.io/monocular
        source: https://github.com/kubernetes-helm/monocular/tree/master/charts
```