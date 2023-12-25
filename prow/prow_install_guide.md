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

#### generate hmac-token secret

```
$ 基于 openssl rand 方法自动生成，生成一个用于 Github Webhook 认证的 hmac 令牌。
$ mkdir prow_secret
$ cd /root/prow_secret
$ openssl rand -hex 20 > hmac-token

$ kubectl -n prow create secret generic hmac-token --from-file=hmac=/root/prow_secret/hmac-token
secret/hmac-token created
```

#### prepare start.yaml, config.yaml, plugins.yaml

```
$ 把config.yaml的三处域名，一个组织/仓库替换成你自己的
$ kubectl -n prow delete cm config
$ kubectl -n prow create cm config --from-file=config.yaml

$ 把plugins.yaml中的组织/仓库替换成你自己的
$ kubectl -n prow delete cm plugins
$ kubectl -n prow create cm plugins --from-file=plugins.yaml

$ 把starter.yaml中 prow.gitcpu.io 替换成你自己的本机域名，或是公有云域名
$ Optionally, you can update the cert-manager.io/cluster-issuer: annotation if you use cert-manager
```

#### prepare ProwJob CRD

```
cp ~/app/test-infra/config/prow/cluster/prowjob_customresourcedefinition.yaml ./
kubectl apply --server-side=true -f prowjob_customresourcedefinition.yaml
```

#### install Prow

```
$ kubectl apply -f starter.yaml
```

#### check all pod status

```
kubectl get pods -n prow
```

#### install GitHub App to your repo with GitHub console

在github->组织-> settings页面 -> installed Github Apps -> 操作你建立的github app -> Configure -> 选择仓库





#### config github oauth appgenerate OAuth-token secret

```
$ 需要 bot 账户创建 access token 获得,注意这里不是secret,而是oauth
$ echo "ghp_8qY123456789123456789123456789123456789" > /root/prow/secret/oauth-token

$ kubectl -n prow create secret generic oauth-token --from-file=oauth=/root/prow/secret/oauth-token
secret/oauth-token created
```

#### generate github-oauth-config

```
$ 需要到 github 上创建 oauth app 获得
$ vim github-oauth-config.yaml
client_id:364021234567890
client_secret: 294f05a12345678901234567890123456789012345
redirect_url: https://prow.danrong.io/github-login/redirect
final_redirect_url: https://prow.danrong.io/pr

$ kubectl -n prow create secret generic github-oauth-config --from-file=secret=/root/prow/secret/github-oauth-config.yaml
```

#### generate cookie secret

```
$ openssl rand -out cookie.txt -base64 32
$ kubectl -n prow create secret generic cookie --from-file=secret=/root/prow/secret/cookie/cookie.txt
secret/cookie created
```

prepare personal access token for your oauth-token