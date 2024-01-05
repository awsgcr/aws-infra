#### 安装 eks-pod-identity

```
$ aws eks create-addon \
--cluster-name <EKS_CLUSTER_NAME> \
--addon-name eks-pod-identity-agent \
--addon-version v1.0.0-eksbuild.1

{
    "addon": {
    "addonName": "eks-pod-identity-agent",
    "clusterName": "<CLUSTER_NAME>",
    "status": "CREATING",
    "addonVersion": "v1.0.0-eksbuild.1",
    "health": {
        "issues": []
        },
    "addonArn": "<ARN>",
    "createdAt": 1697734297.597,
    "modifiedAt": 1697734297.612,
    "tags": {}
    }
}
```
创建Pod Role，其中trust relationship是

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
}
```

```
$ aws eks create-pod-identity-association \
  --cluster-name <CLUSTER_NAME> \
  --namespace <NAMESPACE> \
  --service-account <SERVICE_ACCOUNT_NAME> \
  --role-arn <IAM_ROLE_ARN>
```

确认Pod中已经和IAM Role关联成功 (如果Pod之前已经是running状态，需要重启一次Pod或者rollout restart deployment才能生效)

```
spec:
  containers:
  - args:
    env:
    - name: AWS_DEFAULT_REGION
      value: ap-northeast-1
    - name: AWS_REGION
      value: ap-northeast-1
    - name: AWS_CONTAINER_CREDENTIALS_FULL_URI
      value: http://169.254.170.23/v1/credentials
    - name: AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE
      value: /var/run/secrets/pods.eks.amazonaws.com/serviceaccount/eks-pod-identity-token
......
    volumeMounts:
    - mountPath: /usr/local/certificates/
      name: webhook-cert
      readOnly: true
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: kube-api-access-tqtsv
      readOnly: true
    - mountPath: /var/run/secrets/pods.eks.amazonaws.com/serviceaccount
      name: eks-pod-identity-token
      readOnly: true
```
