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