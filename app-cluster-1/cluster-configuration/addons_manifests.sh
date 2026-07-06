aws eks update-kubeconfig --name app-cluster-01 --region ap-south-1

helm repo add eks https://aws.github.io/eks-charts

helm repo update eks

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=app-cluster-01 \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=ap-south-1 \
  --set vpcId=vpc-09377b639a6c41602 \
  --set image.repository=public.ecr.aws/eks/aws-load-balancer-controller

# VPA
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler/
./hack/vpa-down.sh
./hack/vpa-up.sh

# Cluster Autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"

kubectl label namespace default istio.io/rev=default --overwrite

export APP_CLUSTER=$(kubectl config get-contexts -o name | grep -i app-cluster-01)

# ISTIOCTL configuration setup
istioctl install --context="${APP_CLUSTER}" -f service-mesh-config/istio-config.yaml
istioctl --context="${APP_CLUSTER}" install -y -f service-mesh-config/eastwest-gateway.yaml
kubectl --context="${APP_CLUSTER}" apply -n istio-system -f service-mesh-config/expose-services.yaml
istioctl --context="${APP_CLUSTER}" uninstall -y -f service-mesh-config/istio-config.yaml
istioctl --context="${APP_CLUSTER}" uninstall -y -f service-mesh-config/eastwest-gateway.yaml

# RAW manifests for Istio Control Plane and save it to a file
istioctl manifest generate -f service-mesh-config/istio-config.yaml >> service-mesh-config/istio-installation-manifests.yaml
istioctl create-remote-secret \
    --context="${PLATFORM_CLUSTER}" \
    --name=platform-cluster | \
    kubectl apply -f - --context="${APP_CLUSTER}"
kubectl get secrets istio-remote-secret-platform-cluster  -o yaml -n istio-system --context=${APP_CLUSTER}
# On app-cluster-1 — create a service account for Kiali remote access
kubectl create serviceaccount kiali-remote --context="${APP_CLUSTER}" -n istio-system

# Bind the same ClusterRole that Kiali uses locally
kubectl create clusterrolebinding kiali-remote \
  --clusterrole=kiali \
  --serviceaccount=istio-system:kiali-remote \
  --context="${APP_CLUSTER}"

# Create a long-lived token for the service account
kubectl apply --context="${APP_CLUSTER}" -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: kiali-remote-token
  namespace: istio-system
  annotations:
    kubernetes.io/service-account.name: kiali-remote
type: kubernetes.io/service-account-token
EOF

# Delete all resources in a namespace
kubectl delete $(kubectl api-resources --namespaced=true --verbs=delete -o name | tr "\n" "," | sed 's/,$//') --all -n istio-system
helm uninstall aws-load-balancer-controller -n kube-system

export APP_GATEWAY=$(kubectl get svc istio-eastwestgateway -n istio-system \
  --context=${APP_CLUSTER} \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "App Gateway: $APP_GATEWAY"
kubectl apply -f service-mesh-config/expose-services.yaml --context="${APP_CLUSTER}"