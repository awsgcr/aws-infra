### **安装 aws-load-balancer-controller**

```
cd /root/aws-infra/eks/mainsite/prod/gitops-prow/addon/aws-load-balancer-controller
```

### **创建AWSLoadBalancerControllerIAMPolicy**

```
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.5.4/docs/install/iam_policy.json
```

```
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
eksctl create iamserviceaccount \
  --cluster=gitops-prow \
  --namespace=kube-system \
  --name=aws-load-balancer-controller \
  --role-name AmazonEKSLoadBalancerControllerRole \
  --attach-policy-arn=arn:aws:iam::<aws_account_id>:policy/AWSLoadBalancerControllerIAMPolicy \
  --approve
```

```
oidc_id=$(aws eks describe-cluster --name gitops-prow --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)
```

```
aws iam list-open-id-connect-providers | grep $oidc_id | cut -d "/" -f4
```

3B25B8991969DEE1082497E0792338E9"

```
cat >load-balancer-role-trust-policy.json <<EOF
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
                    "oidc.eks.ap-northeast-1.amazonaws.com/id/3B25B8991969DEE1082497E0792338E9:aud": "sts.amazonaws.com",
                    "oidc.eks.ap-northeast-1.amazonaws.com/id/3B25B8991969DEE1082497E0792338E9:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}
EOF
```

```
aws iam create-role --role-name AmazonEKSLoadBalancerControllerRole --assume-role-policy-document file://"load-balancer-role-trust-policy.json"
```

```
{
    "Role": {
        "Path": "/",
        "RoleName": "AmazonEKSLoadBalancerControllerRole",
        "RoleId": "AROA36OAG736SJZTLDWGL",
        "Arn": "arn:aws:iam::<aws_account_id>:role/AmazonEKSLoadBalancerControllerRole",
        "CreateDate": "2023-12-25T08:26:04+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Federated": "arn:aws:iam::<aws_account_id>:oidc-provider/oidc.eks.ap-northeast-1.amazonaws.com/id/3B25B8991969DEE1082497E0792338E9"
                    },
                    "Action": "sts:AssumeRoleWithWebIdentity",
                    "Condition": {
                        "StringEquals": {
                            "oidc.eks.ap-northeast-1.amazonaws.com/id/3B25B8991969DEE1082497E0792338E9:aud": "sts.amazonaws.com",
                            "oidc.eks.ap-northeast-1.amazonaws.com/id/3B25B8991969DEE1082497E0792338E9:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                        }
                    }
                }
            ]
        }
    }
}
```

```
aws iam attach-role-policy \
  --policy-arn arn:aws:iam::<aws_account_id>:policy/AWSLoadBalancerControllerIAMPolicy \
  --role-name AmazonEKSLoadBalancerControllerRole
```

```
cat >aws-load-balancer-controller-service-account.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::<aws_account_id>:role/AmazonEKSLoadBalancerControllerRole
EOF
```

```
kubectl apply -f aws-load-balancer-controller-service-account.yaml
```

serviceaccount/aws-load-balancer-controller created

### **install helm**

https://docs.aws.amazon.com/eks/latest/userguide/helm.html

```
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
% Total    % Received % Xferd  Average Speed   Time    Time     Time  Current                               Dload  Upload   Total   Spent    Left  Speed
100 11664  100 11664    0     0  41210      0 --:--:-- --:--:-- --:--:-- 41361
ll
total 12
-rw-r--r--. 1 root root 11664 Dec 25 08:38 get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
Downloading https://get.helm.sh/helm-v3.13.1-linux-amd64.tar.gz
Verifying checksum... Done.
Preparing to install helm into /usr/local/bin
helm installed into /usr/local/bin/helm
```

### **check helm version**

```
helm version | cut -d + -f 1
version.BuildInfo{Version:"v3.13.1", GitCommit:"3547a4b5bf5edb5478ce352e18858d8a552a4110", GitTreeState:"clean", GoVersion:"go1.20.8"}
```

### **install aws ingress controller**

```
helm repo add eks https://aws.github.io/eks-charts
"eks" has been added to your repositories
```

```
helm repo update eks

Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "eks" chart repository
Update Complete. ⎈Happy Helming!⎈
```

```
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=gitops-prow \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 
```

```
NAME: aws-load-balancer-controller
LAST DEPLOYED: Mon Dec 25 08:44:40 2023
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
AWS Load Balancer controller installed!
```

### **Verify that the controller is installed.**

```
kubectl get deployment -n kube-system aws-load-balancer-controller
NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller   2/2     2            2           27s
```

