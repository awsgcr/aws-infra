# Prow Install Guide

#### 参考安装手册

```
$ git clone https://github.com/gitcpu-io/install-prow.git
$ git clone https://github.com/awsgcr/aws-infra.git
```

#### 创建AWS EKS集群 

```
参考文档，自行创建EKS集群 
https://github.com/awsgcr/aws-infra/tree/main/aws/project1/prod/ap-northeast-1/eks
```

##### 创建 prow namespace

```
$ kubectl create ns prow
namespace/prow created
```

#### 随机创建 `hmac-token` 用于 Github webhooks 的认证

```
$ 基于 openssl rand 方法自动生成，生成一个用于 Github Webhook 认证的 hmac 令牌。
$ mkdir prow_secret
$ cd /root/prow_secret
$ openssl rand -hex 20 > hmac-token

$ kubectl -n prow create secret generic hmac-token --from-file=hmac=/root/prow_secret/hmac-token
secret/hmac-token created
```

#### 随机创建 `cookie secret`

```
$ openssl rand -out cookie.txt -base64 32
$ kubectl -n prow create secret generic cookie --from-file=secret=/root/prow_secret/cookie.txt
secret/cookie created
```

#### 在 Bot 机器人账号中创建 `github-oauth-config.yaml`

```
$ 在Bot账号中，创建 oauth app
$ vim github-oauth-config.yaml
client_id:123451234567890
client_secret: 1234567890123456789012345678901234567890
redirect_url: https://prow.danrong.io/github-login/redirect
final_redirect_url: https://prow.danrong.io/pr
scopes:
- repo 
```

```
$ kubectl get secret github-oauth-config -n prow -oyaml
确认内容
$ echo 'secret随机数' | base64 -d
```

```
$ kubectl -n prow create secret generic github-oauth-config --from-file=secret=/root/prow_secret/github-oauth-config.yaml
secret/github-oauth-config created
```

#### 在 Bot 机器人账号中配置 `personal-access-token`

```
$ 需要 bot 账户创建 personal access token 获得,注意这里不是secret,而是oauth。至少需要包含有 repo:status 和 public_repo 的权限。
$ echo "ghp_8qY123456789123456789123456789123456789" > /root/prow/secret/oauth-token

$ kubectl -n prow create secret generic oauth-token --from-file=oauth=/root/prow_secret/oauth-token
secret/oauth-token created
```

#### 配置AWS S3 Secret，使得Prow的日志可以存储到S3

```bash
$ cat s3-credentials
{
  "region": "ap-northeast-1"
}
$ kubectl -n prow create secret generic s3-credentials --from-file=service-account.json=s3-credentials
```

#### 至此，生产5个Secret如下

```
kubectl get secret -n prow
NAME                  TYPE     DATA   AGE
cookie                Opaque   1      3d1h
github-oauth-config   Opaque   1      6h4m
hmac-token            Opaque   1      3d1h
oauth-token           Opaque   1      3d1h
s3-credentials        Opaque   1      5h35m
```

#### 部署 ProwJob CRD

```
$ cd /root/aws-infra/prow
$ kubectl apply --server-side=true -f prowjob_customresourcedefinition.yaml
customresourcedefinition.apiextensions.k8s.io/prowjobs.prow.k8s.io serverside-applied

kubectl get crd --all-namespaces
NAME                                         CREATED AT
cninodes.vpcresources.k8s.aws                2023-12-23T15:30:00Z
eniconfigs.crd.k8s.amazonaws.com             2023-12-23T15:29:57Z
ingressclassparams.elbv2.k8s.aws             2023-12-25T08:44:40Z
policyendpoints.networking.k8s.aws           2023-12-23T15:30:01Z
prowjobs.prow.k8s.io                         2023-12-27T09:44:59Z
securitygrouppolicies.vpcresources.k8s.aws   2023-12-23T15:30:00Z
targetgroupbindings.elbv2.k8s.aws            2023-12-25T08:44:40Z
```

#### 创建tide的serviceaccount，用户访问S3 bucket

```
$ vim serviceaccount_tide.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: prow
  name: tide
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::821278736125:role/aws_prod_eks_gitops_prow_pod_role
$ kubectl apply -f serviceaccount_tide.yaml
确认和tide deployment关联成功
$ kubectl describe pod tide-66c79dcd4-znmxg -n prow | grep AWS_ROLE_ARN
      AWS_ROLE_ARN:                 arn:aws:iam::821278736125:role/aws_prod_eks_gitops_prow_pod_role
```

#### 其中pod role的trust relationship如下

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::821278736125:oidc-provider/oidc.eks.ap-northeast-1.amazonaws.com/id/3B25B8991969DEE1082497E0792338E9"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.ap-northeast-1.amazonaws.com/id/3B25B8991969DEE1082497E0792338E9:sub": [
                        "system:serviceaccount:prow:tide",
                        "system:serviceaccount:prow:crier",
                        "system:serviceaccount:prow:deck"
                    ],
                    "oidc.eks.ap-northeast-1.amazonaws.com/id/3B25B8991969DEE1082497E0792338E9:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}
```

#### 同理创建crier, deck的serviceaccount

```bash
$ vim serviceaccount_crier.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: prow
  name: crier
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::821278736125:role/aws_prod_eks_gitops_prow_pod_role

$ vim serviceaccount_deck.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  namespace: prow
  name: deck
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::821278736125:role/aws_prod_eks_gitops_prow_pod_role
```

#### 自定义 `prow_install_starter.yaml, config.yaml, plugins.yaml`

```bash
$ 替换config.yaml中三处域名，和 org/repo 成为你自己的
$ kubectl -n prow delete cm config
$ kubectl -n prow create cm config --from-file=config.yaml
configmap/config created

$ 把plugins.yaml中的组织/仓库替换成你自己的
$ kubectl -n prow delete cm plugins
$ kubectl -n prow create cm plugins --from-file=plugins.yaml
configmap/plugins created

$ 把jobs文件夹里面的内容创建成一个configmap，这样可以把prowjob放在一个单独的文件夹里，而不是config.yaml里面。
$ kubectl create configmap job-config --from-file=./prow/jobs
```

#### 安装 Prow

```bash
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
得到有用的信息，比如
  Normal   Scheduled    8m17s                default-scheduler  Successfully assigned prow/crier-67b67f4546-cc8rl to ip-10-80-17-90.ap-northeast-1.compute.internal
  Warning  FailedMount  99s (x3 over 6m14s)  kubelet            Unable to attach or mount volumes: unmounted volumes=[github-token], unattached volumes=[], failed to process volumes=[]: timed out waiting for the condition
  Warning  FailedMount  2s (x12 over 8m16s)  kubelet            MountVolume.SetUp failed for volume "github-token" : secret "github-token" not found
  
  Normal   Scheduled    11m                   default-scheduler  Successfully assigned prow/deck-ddb46b9bd-khkwb to ip-10-80-17-90.ap-northeast-1.compute.internal
  Warning  FailedMount  11m                   kubelet            MountVolume.SetUp failed for volume "s3-credentials" : secret "s3-credentials" not found
  Warning  FailedMount  10m (x8 over 11m)     kubelet            MountVolume.SetUp failed for volume "oauth-token" : secret "oauth-token" not found
  Warning  FailedMount  5m19s (x11 over 11m)  kubelet            MountVolume.SetUp failed for volume "cookie-secret" : secret "cookie" not found
  Warning  FailedMount  74s (x13 over 11m)    kubelet            MountVolume.SetUp failed for volume "oauth-config" : secret "github-oauth-config" not found
  
比如发现ghproxy-5bbbd5f5f-6f72l一直在pending，没有启动成功
$ kubectl get po -n prow
NAME                                       READY   STATUS             RESTARTS        AGE
crier-67994f588-456j7                      1/1     Running            7 (10h ago)     10h
deck-68c6ff47d6-qr8hq                      1/1     Running            0               10h
ghproxy-5bbbd5f5f-6f72l                    0/1     Pending            0               10h
hook-866d9bc6dc-pd85r                      1/1     Running            0               10h
horologium-6bd4767d46-xv4kp                1/1     Running            0               10h
prow-controller-manager-64cf8b5947-sd8sk   1/1     Running            0               10h
sinker-7f6979bd86-scp5p                    1/1     Running            0               10h
statusreconciler-7975d69b4f-xl2sv          1/1     Running            0               10h
tide-66c79dcd4-znmxg                       0/1     CrashLoopBackOff   120 (49s ago)   9h
$ kubectl -n prow describe pod ghproxy-5bbbd5f5f-6f72l
running PreBind plugin "VolumeBinding": binding volumes: timed out waiting for the condition
$ aws eks describe-addon --cluster-name gitops-prow --addon-name aws-ebs-csi-driver --query "addon.addonVersion" --output text
An error occurred (ResourceNotFoundException) when calling the DescribeAddon operation: No addon: aws-ebs-csi-driver found in cluster: gitops-prow
至此发现没有安装aws-ebs-csi-driver

参考手册安装aws-ebs-csi-driver，再次确认发现ghproxy已经running了。
$ kubectl get po -n prow
NAME                                       READY   STATUS             RESTARTS         AGE
crier-67994f588-456j7                      1/1     Running            7 (11h ago)      11h
deck-68c6ff47d6-qr8hq                      1/1     Running            0                11h
ghproxy-5bbbd5f5f-6f72l                    1/1     Running            0                11h
```

#### 安装 `prow_pushgateway.yaml`

```bash
$ cd ~/aws-infra/prow
$ kubectl apply -f prow_install_pushgateway.yaml
deployment.apps/pushgateway created
service/pushgateway created
configmap/pushgateway-proxy-config created
deployment.apps/pushgateway-proxy created
service/pushgateway-external created
确保pushgateway启动成功
$ kubectl get pod --all-namespaces | grep gatewayå
prow            pushgateway-69fb5cb89d-6twv2                    1/1     Running            0               107s
prow            pushgateway-proxy-5f49754768-2lf44              1/1     Running            0               107s
```

#### 创建labels config，使提交PR时颜色分明

```bash
$ cd /aws-infra/prow/config/label-config
$ kubectl -n prow create cm label-config --from-file=labels.yaml
configmap/label-config created
$ kubectl get cm -n prow | grep label
label-config                          1      42s
$ kubectl apply -f label_sync_job.yaml
job.batch/label-sync created
$ kubectl -n prow get job
NAME         COMPLETIONS   DURATION   AGE
label-sync   0/1           2m53s      2m53s
$ kubectl apply -f label_sync_cron_job.yaml
cronjob.batch/label-sync created
$ kubectl -n prow get cronjob
NAME         SCHEDULE     SUSPEND   ACTIVE   LAST SCHEDULE   AGE
label-sync   17 * * * *   False     0        <none>          2m50s
```

#### 安装 nginx-ingress

```bash
$ kubectl apply -f ingress-nginx.yaml
serviceaccount/ingress-nginx created
configmap/ingress-nginx-controller created
clusterrole.rbac.authorization.k8s.io/ingress-nginx created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx created
role.rbac.authorization.k8s.io/ingress-nginx created
rolebinding.rbac.authorization.k8s.io/ingress-nginx created
service/ingress-nginx-controller-admission created
service/ingress-nginx-controller created
deployment.apps/ingress-nginx-controller created
ingressclass.networking.k8s.io/nginx created
validatingwebhookconfiguration.admissionregistration.k8s.io/ingress-nginx-admission created
serviceaccount/ingress-nginx-admission created
clusterrole.rbac.authorization.k8s.io/ingress-nginx-admission created
clusterrolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
role.rbac.authorization.k8s.io/ingress-nginx-admission created
rolebinding.rbac.authorization.k8s.io/ingress-nginx-admission created
job.batch/ingress-nginx-admission-create created
job.batch/ingress-nginx-admission-patch created

确认部署状态
$ kubectl -n ingress-nginx get all
NAME                                            READY   STATUS      RESTARTS   AGE
pod/ingress-nginx-admission-create-5cg6x        0/1     Completed   0          40s
pod/ingress-nginx-admission-patch-sgqcm         0/1     Completed   1          40s
pod/ingress-nginx-controller-7c744c9d7f-6dz4k   1/1     Running     0          40s

NAME                                         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
service/ingress-nginx-controller             NodePort    172.20.197.28   <none>        80:31676/TCP,443:30579/TCP   40s
service/ingress-nginx-controller-admission   ClusterIP   172.20.73.244   <none>        443/TCP                      40s

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ingress-nginx-controller   1/1     1            1           40s

NAME                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/ingress-nginx-controller-7c744c9d7f   1         1         1       40s

NAME                                       COMPLETIONS   DURATION   AGE
job.batch/ingress-nginx-admission-create   1/1           7s         40s

确保处理running的状态
$ kubectl get po -n ingress-nginx
NAME                                        READY   STATUS      RESTARTS   AGE
ingress-nginx-admission-create-5cg6x        0/1     Completed   0          4m15s
ingress-nginx-admission-patch-sgqcm         0/1     Completed   1          4m15s
ingress-nginx-controller-7c744c9d7f-6dz4k   1/1     Running     0          4m15s
```

