# # Check if argocd cli installed
# if ! command -v argocd &> /dev/null
# then
#     echo "argocd could not be found"
#     echo "please install argocd cli before running this script"
#     echo "https://argo-cd.readthedocs.io/en/stable/getting_started/"
#     exit 1
# fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found"
    echo "please install kubectl before running this script"
    echo "https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

# Deploy argocd if it's not deployed 
if ! kubectl get pods -n argocd | grep -q "argocd-server"
then
    echo "Deploying argocd to k8s cluster."
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo "sleep 5..."
    sleep 5
fi


echo "Wait for argocd to be ready..."
# # Make sure argocd cli is configured. 
kubectl wait --namespace argocd \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/name=argocd-server \
  --timeout=90s

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