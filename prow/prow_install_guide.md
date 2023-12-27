# Prow installation

```sh
$ openssl rand -hex 20 > /path/to/hook/secret
$ kubectl create secret generic hmac-token --from-file=hmac=/path/to/hook/secret
$ kubectl create secret generic oauth-token --from-file=oauth=/path/to/oauth/secret
$ openssl rand -out cookie.txt -base64 32
$ kubectl create secret generic github-oauth-config --from-file=secret=<PATH_TO_YOUR_GITHUB_SECRET>
$ kubectl create secret generic cookie --from-file=secret=<PATH_TO_YOUR_COOKIE_KEY_SECRET>
$ https://docs.prow.k8s.io/docs/getting-started-deploy/#deploying-prow
```

#### clone kubernetes test-infra to your local

```
$ git clone https://github.com/kubernetes/test-infra.git
```

#### clone prow sample repo to your local

```
$ git clone https://github.com/gitcpu-io/install-prow.git
```

#### create prow k8s namespace

```
$ kubectl create ns prow
namespace/prow created
```

#### 创建 `hmac-token` 用于 Github webhooks 的认证

```
$ 基于 openssl rand 方法自动生成，生成一个用于 Github Webhook 认证的 hmac 令牌。
$ mkdir prow_secret
$ cd /root/prow_secret
$ openssl rand -hex 20 > hmac-token

$ kubectl -n prow create secret generic hmac-token --from-file=hmac=/root/prow_secret/hmac-token
secret/hmac-token created
```

#### 生产随机 cookie secret

```
$ openssl rand -out cookie.txt -base64 32
$ kubectl -n prow create secret generic cookie --from-file=secret=/root/prow_secret/cookie.txt
secret/cookie created
```

#### 创建 github-oauth-config.yaml

```
$ 需要到 https://github.com/settings/developers 上创建 oauth app 获得
$ vim github-oauth-config.yaml
client_id:123451234567890
client_secret: 12345612345678901234567890123456789012345
redirect_url: https://prow.danrong.io/github-login/redirect
final_redirect_url: https://prow.danrong.io/pr

$ kubectl -n prow create secret generic github-oauth-config --from-file=secret=/root/prow_secret/github-oauth-config.yaml
secret/github-oauth-config created
```

#### 在 Bot 机器人账号中配置 personal-access-token

```
$ 需要 bot 账户创建 personal access token 获得,注意这里不是secret,而是oauth。至少需要包含有 repo:status 和 public_repo 的权限。
$ echo "ghp_8qY123456789123456789123456789123456789" > /root/prow/secret/oauth-token

$ kubectl -n prow create secret generic oauth-token --from-file=oauth=/root/prow_secret/oauth-token
secret/oauth-token created
```

#### 至此，生产4个Secret如下

```

```



#### 部署 ProwJob CRD

```
$ cd /root/aws-infra/prow
$ kubectl apply --server-side=true -f prowjob_customresourcedefinition.yaml
customresourcedefinition.apiextensions.k8s.io/prowjobs.prow.k8s.io serverside-applied
```

#### 自定义 prow_install_starter.yaml, config.yaml, plugins.yaml

```
$ 替换config.yaml中三处域名，和 org/repo 成为你自己的
$ kubectl -n prow delete cm config
$ kubectl -n prow create cm config --from-file=config.yaml
configmap/config created

$ 把plugins.yaml中的组织/仓库替换成你自己的
$ kubectl -n prow delete cm plugins
$ kubectl -n prow create cm plugins --from-file=plugins.yaml
configmap/plugins created
```

#### 安装 Prow

```
$ 部署 prow_install_starter.yaml
$ kubectl apply -f prow_install_starter.yaml
Warning: resource namespaces/prow is missing the kubectl.kubernetes.io/last-applied-configuration annotation which is required by kubectl apply. kubectl apply should only be used on resources created declaratively by either kubectl create --save-config or kubectl apply. The missing annotation will be patched automatically.
namespace/prow configured
deployment.apps/hook created
service/hook created
deployment.apps/sinker created
deployment.apps/deck created
service/deck created
deployment.apps/horologium created
deployment.apps/tide created
service/tide created
deployment.apps/statusreconciler created
namespace/test-pods created
serviceaccount/deck created
rolebinding.rbac.authorization.k8s.io/deck created
rolebinding.rbac.authorization.k8s.io/deck created
role.rbac.authorization.k8s.io/deck created
role.rbac.authorization.k8s.io/deck created
serviceaccount/horologium created
role.rbac.authorization.k8s.io/horologium created
rolebinding.rbac.authorization.k8s.io/horologium created
serviceaccount/sinker created
role.rbac.authorization.k8s.io/sinker created
role.rbac.authorization.k8s.io/sinker created
rolebinding.rbac.authorization.k8s.io/sinker created
rolebinding.rbac.authorization.k8s.io/sinker created
serviceaccount/hook created
role.rbac.authorization.k8s.io/hook created
rolebinding.rbac.authorization.k8s.io/hook created
serviceaccount/tide created
role.rbac.authorization.k8s.io/tide created
rolebinding.rbac.authorization.k8s.io/tide created
serviceaccount/statusreconciler created
role.rbac.authorization.k8s.io/statusreconciler created
rolebinding.rbac.authorization.k8s.io/statusreconciler created
persistentvolumeclaim/ghproxy created
deployment.apps/ghproxy created
service/ghproxy created
deployment.apps/prow-controller-manager created
serviceaccount/prow-controller-manager created
role.rbac.authorization.k8s.io/prow-controller-manager created
role.rbac.authorization.k8s.io/prow-controller-manager created
rolebinding.rbac.authorization.k8s.io/prow-controller-manager created
rolebinding.rbac.authorization.k8s.io/prow-controller-manager created
deployment.apps/crier created
serviceaccount/crier created
role.rbac.authorization.k8s.io/crier created
role.rbac.authorization.k8s.io/crier created
rolebinding.rbac.authorization.k8s.io/crier created
rolebinding.rbac.authorization.k8s.io/crier created
secret/s3-credentials created
secret/s3-credentials created
deployment.apps/minio created
service/minio created
service/minio-console created

如果pod没有完全启动成功，可以自行排查原因。
]# kubectl get po -n prow
NAME                                       READY   STATUS              RESTARTS        AGE
crier-67b67f4546-cc8rl                     0/1     ContainerCreating   0               9m28s
deck-ddb46b9bd-khkwb                       0/1     ContainerCreating   0               9m29s
ghproxy-5bbbd5f5f-hn9fd                    0/1     Pending             0               9m28s
hook-fcdb6b5d8-9fwxj                       0/1     ContainerCreating   0               9m28s
horologium-6d8d657c48-flq4g                0/1     CrashLoopBackOff    6 (3m55s ago)   9m29s
minio-fd9f495d6-r56d8                      1/1     Running             0               9m27s
prow-controller-manager-749ddfd9f9-5gmdm   0/1     ContainerCreating   0               9m28s
sinker-564b4fc557-9mtqp                    0/1     CrashLoopBackOff    6 (3m45s ago)   9m28s
statusreconciler-867c49d959-v6rlj          0/1     ContainerCreating   0               9m28s
tide-7b89d47589-rl275                      0/1     ContainerCreating   0               9m28s
$ kubectl describe pod crier-67b67f4546-cc8rl -n prow
得到有用的信息
  Normal   Scheduled    8m17s                default-scheduler  Successfully assigned prow/crier-67b67f4546-cc8rl to ip-10-80-17-90.ap-northeast-1.compute.internal
  Warning  FailedMount  99s (x3 over 6m14s)  kubelet            Unable to attach or mount volumes: unmounted volumes=[github-token], unattached volumes=[], failed to process volumes=[]: timed out waiting for the condition
  Warning  FailedMount  2s (x12 over 8m16s)  kubelet            MountVolume.SetUp failed for volume "github-token" : secret "github-token" not found
  
  Normal   Scheduled    11m                   default-scheduler  Successfully assigned prow/deck-ddb46b9bd-khkwb to ip-10-80-17-90.ap-northeast-1.compute.internal
  Warning  FailedMount  11m                   kubelet            MountVolume.SetUp failed for volume "s3-credentials" : secret "s3-credentials" not found
  Warning  FailedMount  10m (x8 over 11m)     kubelet            MountVolume.SetUp failed for volume "oauth-token" : secret "oauth-token" not found
  Warning  FailedMount  5m19s (x11 over 11m)  kubelet            MountVolume.SetUp failed for volume "cookie-secret" : secret "cookie" not found
  Warning  FailedMount  74s (x13 over 11m)    kubelet            MountVolume.SetUp failed for volume "oauth-config" : secret "github-oauth-config" not found
```

#### check all pod status

```
kubectl get pods -n prow
```

#### install GitHub App to your repo with GitHub console

在github->组织-> settings页面 -> installed Github Apps -> 操作你建立的github app -> Configure -> 选择仓库





#### 

```

```

#### 
