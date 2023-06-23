# Gen3 Helm - GitOps exmample

Instructions to bootstrap a gen3 cluster using ArgoCD and KIND (Kubernetes in docker) using GitOps. 

This will deploy cluster level resources for observability, security and orchestration as well as configure and deploy gen3. 

Secrets mangement is TBD, do not commit secrets to Git! 

## Install Docker or similar. 

I personally have been LOVING OrbStack lately, works insanely well with M1. I can run Docker/k8s all the time without seeing any slowdown of my computer.

But any docker runtime will work. 

- OrbStack: https://orbstack.dev 
- Rancher Desktop: https://rancherdesktop.io
- Docker Desktop: https://www.docker.com/products/docker-desktop/


## Install kind (Kubernetes in Docker)

https://kind.sigs.k8s.io/docs/user/quick-start/#installation

## Create Kind cluster

We want to expose port 80/443 so we can get ingress working. Run the following command.

```bash
cat <<EOF | kind create cluster --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
```

## Bootstrap cluster resources, and deploy gen3 

This will deploy ArgoCD and then deploy the following resources: 

Cluster Resources:
- Istio
- Jaeger
- Kiali
- Argo Workflows
- Kong Ingress
- Prometheus

Gen3 Resources:
- PostgreSQL
- ElasticSearch
- Gen3 (Configuration in git)

```bash
bash ./bootstrap.sh
```

## Edit your /etc/hosts file

```bash
sudo vi /etc/hosts
```

Add in the following line:

```bash
127.0.0.1 qureshi.planx-pla.net
```

Visit https://qureshi.planx-pla.net 

## View in ArgoCD UI

Get the password like this:

```bash
kubectl get secrets -n argocd argocd-initial-admin-secret -o yaml | yq -r .data.password | base64 -d | xargs echo
```

Port forward to the UI and browse to http://localhost:8080 to log in to track all the deployments

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

## Teardown

```bash
kind delete cluster
```

## GitOps Configration of your environment

TBD

## App of apps pattern

TBD