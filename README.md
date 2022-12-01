# demo_snyk_k8s_integ
Files for demo of snyk K8s integration, using DockerDesktop

Preparation of auto import/delete of projects were not successfuly with k8s of DockerDesktop.

For references,
- [Automatic import/deletion of Kubernetes workloads projects](https://docs.snyk.io/products/snyk-container/kubernetes-workload-and-image-scanning/kubernetes-integration-features/automatic-import-deletion-of-kubernetes-workloads-projects)
- [Advanced use of automatic import/deletion](https://docs.snyk.io/products/snyk-container/kubernetes-workload-and-image-scanning/kubernetes-integration-features/automatic-import-deletion-of-kubernetes-workloads-projects/advanced-use-of-automatic-import-deletion#using-more-than-one-org)

## Requirements
- DockerDesktop
- helm

### more details on requirements
[Snyk Docs on Requirements](https://docs.snyk.io/products/snyk-container/kubernetes-workload-and-image-scanning/installation-page/prerequisite-setting)

## Step 01.
Enable Kubernetes from the settings of DockerDesktop 
<img width="1269" alt="Screenshot 2022-11-30 at 15 14 40" src="https://user-images.githubusercontent.com/93645043/204726042-7618389d-df43-45b0-ac04-a1cb08ef548d.png">

## Step 02.
confirm the version of kubectl after applying changes to the settings
```
√ % kubectl version --output=json
{
  "clientVersion": {
    "major": "1",
    "minor": "25",
    "gitVersion": "v1.25.2",
    "gitCommit": "5835544ca568b757a8ecae5c153f317e5736700e",
    "gitTreeState": "clean",
    "buildDate": "2022-09-21T14:33:49Z",
    "goVersion": "go1.19.1",
    "compiler": "gc",
    "platform": "darwin/amd64"
  },
  "kustomizeVersion": "v4.5.7",
  "serverVersion": {
    "major": "1",
    "minor": "25",
    "gitVersion": "v1.25.2",
    "gitCommit": "5835544ca568b757a8ecae5c153f317e5736700e",
    "gitTreeState": "clean",
    "buildDate": "2022-09-21T14:27:13Z",
    "goVersion": "go1.19.1",
    "compiler": "gc",
    "platform": "linux/amd64"
  }
}
```
And, confirm what are running by default
```
√ % kubectl get svc 
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   14d

√ % kubectl get nodes
NAME             STATUS   ROLES           AGE   VERSION
docker-desktop   Ready    control-plane   14d   v1.25.2
```

## Step 03.
[General guide on installation steps:](https://docs.snyk.io/products/snyk-container/kubernetes-workload-and-image-scanning/installation-page/prerequisite-setting)

From the Snyk Org's settings UI, Enable Kubernetes by clicking on "Connect"
<img width="926" alt="Screenshot 2022-11-30 at 15 33 32" src="https://user-images.githubusercontent.com/93645043/204731639-9229336e-2fff-4aae-8408-60334c0591fa.png">

And, copy the integration ID
<img width="1017" alt="Screenshot 2022-11-30 at 16 18 58" src="https://user-images.githubusercontent.com/93645043/204732269-39dbb0c7-329f-4597-b6df-83eea8c139a6.png">

1. add snyk-monitor to a helm repo
```
√ % helm repo add snyk-charts https://snyk.github.io/kubernetes-monitor --force-update
"snyk-charts" has been added to your repositories
```
2. add K8s namespace 
```
√ % kubectl create namespace snyk-monitor
namespace/snyk-monitor created
```
3. add K8s secret for Snyk Kubernetes integration, specifying the integration ID from Snyk Org's settings UI.
```
√ % kubectl create secret generic snyk-monitor -n snyk-monitor \
        --from-literal=dockercfg.json={} \
        --from-literal=integrationId=d0138106-2e76-4174-980b-xxxxxxxxx
secret/snyk-monitor created
```
4. Either compile or make use of prepared workloads-events policyfiles, and map the file when ready.
```
√ % cat ./demo_workload_events.rego 
package snyk
orgs := ["d0138106-2e76-4174-980b-xxxxxxxxxxx","10f6c201-a59a-4a87-8aa8-xxxxxxxxxxx"]
default workload_events = false
workload_events {
    input.metadata.namespace == "default"
}
```
when ready, map the policy file.
```
√ % kubectl create configmap snyk-monitor-custom-policies \
    -n snyk-monitor \
    --from-file=./demo_workload_events.rego 
configmap/snyk-monitor-custom-policies created
```
5. Install Snyk-Kubernetes integration, using helm
```
√ % helm upgrade --install snyk-monitor snyk-charts/snyk-monitor --namespace default --set clusterName="demo-snyk-k8s-integ" --set workloadPoliciesMap=snyk-monitor-custom-policies --set policyOrgs=d0138106-2e76-4174-980b-xxxxxxxxxxxx
Release "snyk-monitor" does not exist. Installing it now.
W1130 10:20:04.806385   14061 warnings.go:70] spec.template.spec.affinity.nodeAffinity.requiredDuringSchedulingIgnoredDuringExecution.nodeSelectorTerms[0].matchExpressions[1].key: beta.kubernetes.io/arch is deprecated since v1.14; use "kubernetes.io/arch" instead
NAME: snyk-monitor
LAST DEPLOYED: Wed Nov 30 10:20:04 2022
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

### Step 04. Now, apply manifest files to deploy
Sample output from applying one of two manifest files.
```
√ % kubectl apply -f manifest_01_demo_snyk-k8s.yml 
service/grafana created
service/prometheus created
deployment.apps/grafana created
deployment.apps/prometheus created
```
Sample output from applying other manifest file.
```
√ % kubectl apply -f ./manifest_02_demo_snyk-k8s.yml 
service/demo-snyk created
deployment.apps/demo-snyk created
```

### Step 05. Import Kubernetes workloads
For manual guide, please follow steps shared in the SnykDoc
[Manual import guide](https://docs.snyk.io/products/snyk-container/kubernetes-workload-and-image-scanning/kubernetes-integration-features/adding-kubernetes-workloads-for-security-scanning)

### Step 06. When completed with the demo, remove deployed items, using manifest files.
Sample outputs when removing items, using manifest files.
```
√ % kubectl delete -f ./manifest_01_demo_snyk-k8s.yml 
service "grafana" deleted
service "prometheus" deleted
deployment.apps "grafana" deleted
deployment.apps "prometheus" deleted
```

```
√ % kubectl delete -f ./manifest_02_demo_snyk-k8s.yml 
service "demo-snyk" deleted
deployment.apps "demo-snyk" deleted
```
