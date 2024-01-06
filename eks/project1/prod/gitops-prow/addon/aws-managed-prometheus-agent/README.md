#### 安装 aws-managed-prometheus-agent

https://docs.aws.amazon.com/prometheus/latest/userguide/AMP-onboard-ingest-metrics.html

```
$ helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
"prometheus-community" has been added to your repositories

$ helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
"kube-state-metrics" has been added to your repositories

$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "kube-state-metrics" chart repository
...Successfully got an update from the "eks" chart repository
...Successfully got an update from the "prometheus-community" chart repository
Update Complete. ⎈Happy Helming!⎈

$ kubectl create namespace monitoring
namespace/monitoring created
```

### **创建service account**

```
serviceAccounts:
  server:
    name: amp-iamproxy-ingest-service-account
    annotations: 
      eks.amazonaws.com/role-arn: arn:aws:iam::821278736125:role/aws_prod_eks_managed_prometheus_pod_role
server:
  remoteWrite:
    - url: https://aps-workspaces.ap-northeast-1.amazonaws.com/workspaces/ws-ec9d3071-53f1-4c44-9f41-7809f6c6be1d9e/api/v1/remote_write
      sigv4:
        region: ap-northeast-1
      queue_config:
        max_samples_per_send: 1000
        max_shards: 200
        capacity: 2500

```

### **创建prometheus server**

```
helm install aws-managed-prometheus-agent prometheus-community/prometheus -n monitoring \
-f aws-managed-prometheus-agent-service-account.yaml
```

```
NAME: aws-managed-prometheus-agent
LAST DEPLOYED: Fri Jan  5 15:32:02 2024
NAMESPACE: monitoring
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
The Prometheus server can be accessed via port 80 on the following DNS name from within your cluster:
aws-managed-prometheus-agent-server.monitoring.svc.cluster.local


Get the Prometheus server URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=prometheus,app.kubernetes.io/instance=aws-managed-prometheus-agent" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace monitoring port-forward $POD_NAME 9090


The Prometheus alertmanager can be accessed via port 9093 on the following DNS name from within your cluster:
aws-managed-prometheus-agent-alertmanager.monitoring.svc.cluster.local


Get the Alertmanager URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=alertmanager,app.kubernetes.io/instance=aws-managed-prometheus-agent" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace monitoring port-forward $POD_NAME 9093
#################################################################################
######   WARNING: Pod Security Policy has been disabled by default since    #####
######            it deprecated after k8s 1.25+. use                        #####
######            (index .Values "prometheus-node-exporter" "rbac"          #####
###### .          "pspEnabled") with (index .Values                         #####
######            "prometheus-node-exporter" "rbac" "pspAnnotations")       #####
######            in case you still need it.                                #####
#################################################################################


The Prometheus PushGateway can be accessed via port 9091 on the following DNS name from within your cluster:
aws-managed-prometheus-agent-prometheus-pushgateway.monitoring.svc.cluster.local


Get the PushGateway URL by running these commands in the same shell:
  export POD_NAME=$(kubectl get pods --namespace monitoring -l "app=prometheus-pushgateway,component=pushgateway" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace monitoring port-forward $POD_NAME 9091

For more information on running Prometheus, visit:
https://prometheus.io/
```