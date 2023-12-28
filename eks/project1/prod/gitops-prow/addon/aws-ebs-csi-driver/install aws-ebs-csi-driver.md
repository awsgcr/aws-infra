#### 安装 aws-ebs-csi-driver

https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html

```
$ aws eks describe-addon --cluster-name gitops-prow --addon-name aws-ebs-csi-driver --query "addon.addonVersion" --output text
```

```
$ aws eks describe-cluster --name gitops-prow --query "cluster.identity.oidc.issuer" --output text
https://oidc.eks.ap-northeast-1.amazonaws.com/id/3B25B8991969DEE1082497E0792338E9
```

```
$ vim aws-ebs-csi-driver-trust-policy.json
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
          "oidc.eks.ap-northeast-1.amazonaws.com/id/3B25B8991969DEE1082497E0792338E9:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
        }
      }
    }
  ]
}
```

```
$ aws iam create-role --role-name AmazonEKS_EBS_CSI_DriverRole --assume-role-policy-document file://"aws-ebs-csi-driver-trust-policy.json"
{
    "Role": {
        "Path": "/",
        "RoleName": "AmazonEKS_EBS_CSI_DriverRole",
        "RoleId": "AROA36OAG7364J7DBH2MH",
        "Arn": "arn:aws:iam::821278736125:role/AmazonEKS_EBS_CSI_DriverRole",
        "CreateDate": "2023-12-28T04:34:07+00:00",
        "AssumeRolePolicyDocument": {
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
                            "oidc.eks.ap-northeast-1.amazonaws.com/id/3B25B8991969DEE1082497E0792338E9:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
                        }
                    }
                }
            ]
        }
    }
}
```

```
$ aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --role-name AmazonEKS_EBS_CSI_DriverRole
$ aws eks create-addon --cluster-name gitops-prow --addon-name aws-ebs-csi-driver --service-account-role-arn arn:aws:iam::821278736125:role/AmazonEKS_EBS_CSI_DriverRole
{
    "addon": {
        "addonName": "aws-ebs-csi-driver",
        "clusterName": "gitops-prow",
        "status": "CREATING",
        "addonVersion": "v1.26.0-eksbuild.1",
        "health": {
            "issues": []
        },
        "addonArn": "arn:aws:eks:ap-northeast-1:821278736125:addon/gitops-prow/aws-ebs-csi-driver/3cc6575b-144a-f9f2-d98b-8e7c26d1acbc",
        "createdAt": "2023-12-28T04:37:03.060000+00:00",
        "modifiedAt": "2023-12-28T04:37:03.099000+00:00",
        "serviceAccountRoleArn": "arn:aws:iam::821278736125:role/AmazonEKS_EBS_CSI_DriverRole",
        "tags": {}
    }
}
```

#### 确认安装成功

```
$ aws eks describe-addon-versions --addon-name aws-ebs-csi-driver | grep addonName
  "addonName": "aws-ebs-csi-driver"
```

