function createKind() {
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
}


if ! docker ps 
then
    echo "ERROR: docker could not be found, or returned an error."
    echo "please install docker before running this script"
    echo "https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if KIND cluster is running, if not create kind cluster. If kind isn't installed error out. 
if ! kind get clusters | grep -q "kind"
then
    if ! createKind
    then 
        echo "Installing kind..."
        # Check if uname == Darwin
        if [ $(uname) = Darwin ]
        then
            # For AMD64 / x86_64
            [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
            # For ARM64
            [ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-arm64
            chmod +x ./kind
            sudo mv ./kind /usr/local/bin/kind
        fi

        # Check if uname == Linux
        if [ $(uname) = Linux ]
        then
            # For AMD64 / x86_64
            [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
            # For ARM64
            [ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-arm64
            chmod +x ./kind
            sudo mv ./kind /usr/local/bin/kind
        fi
        createKind
    else
        createKind
    fi
fi

# Check if kubectl is installed
if ! kubectl get pods
then
    # install kubectl check if darwin or linux etc etc 
    echo "Installing kubectl..."
    # Check if uname == Darwin
    if [ $(uname) = Darwin ]
    then
        # For AMD64 / x86_64
        [ $(uname -m) = x86_64 ] && curl -Lo ./kubectl https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/darwin/amd64/kubectl
        # For ARM64
        [ $(uname -m) = aarch64 ] && curl -Lo ./kubectl https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/darwin/arm64/kubectl
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
    fi

    # Check if uname == Linux
    if [ $(uname) = Linux ]
    then
        # For AMD64 / x86_64
        [ $(uname -m) = x86_64 ] && curl -Lo ./kubectl https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl
        # For ARM64
        [ $(uname -m) = aarch64 ] && curl -Lo ./kubectl https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/arm64/kubectl
        chmod +x ./kubectl
        sudo mv ./kubectl /usr/local/bin/kubectl
    fi
fi

# # Check if k9s installed, if not isntall it for mac or linux 
# if ! k9s
# then
#     echo "Installing k9s..."
#     # Check if uname == Darwin
#     if [ $(uname) = Darwin ]
#     then
#         # For AMD64 / x86_64
#         [ $(uname -m) = x86_64 ] && curl -Lo ./k9s https://github.com/derailed/k9s/releases/download/v0.28.0/k9s_Darwin_amd64.tar.gz
#         # For ARM64
#         [ $(uname -m) = aarch64 ] && curl -Lo ./k9s https://github.com/derailed/k9s/releases/download/v0.28.0/k9s_Darwin_arm64.tar.gz
#         tar -xvf k9s_Darwin_amd64.tar.gz
#         chmod +x ./k9s


# Deploy argocd if it's not deployed 
if ! kubectl get pods -n argocd | grep -q "argocd-server"
then
    echo "Deploying argocd to k8s cluster."
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo "sleep 5..."
    sleep 15
fi


echo "Waiting for all argocd pods to be ready..."
kubectl wait --namespace argocd --for=condition=ready pod --all

echo "Apply cluster resources..."
# apply cluster resources
kubectl apply -f ./bootstrap/cluster.yaml

echo "Deploying gen3 to k8s cluster using argocd"
# deploy gen3
kubectl apply -f ./bootstrap/gen3.yaml

echo "View argocd UI by running the following commands:" 

echo "Print out the argocd password:"
PASSWORD=$(kubectl get secrets -n argocd argocd-initial-admin-secret -o yaml | yq -r .data.password | base64 -d | xargs echo)
echo "kubectl get secrets -n argocd argocd-initial-admin-secret -o yaml | yq -r .data.password | base64 -d | xargs echo"

echo "Port forward and access ArgoCD ui at http://localhost:8080. Use username admin and password (from above): $PASSWORD"

echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
kubectl port-forward svc/argocd-server -n argocd 8080:443 &
