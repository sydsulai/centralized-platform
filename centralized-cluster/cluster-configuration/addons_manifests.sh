aws eks update-kubeconfig --region=ap-south-1 --name=platform-cluster

helm repo add eks https://aws.github.io/eks-charts

helm repo update eks

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=platform-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=ap-south-1 \
  --set vpcId=vpc-04c528469206450a8 \
  --set image.repository=public.ecr.aws/eks/aws-load-balancer-controller

# Istio
# istioctl install --set profile=demo # Create Istio Control PLane Directly in the Cluster

# Create manifests for Istio Control Plane and save it to a file
# istioctl manifest generate --set profile=demo >> app-service-mesh-config/istio-installation-manifests.yaml
kubectl label namespace default istio-injection- && kubectl label namespace default istio.io/rev=default --overwrite

export PLATFORM_CLUSTER=$(kubectl config get-contexts -o name | grep -i platform-cluster)

# ISTIOCTL configuration setup
istioctl install --context="${PLATFORM_CLUSTER}" -f istio-config.yaml
istioctl --context="${PLATFORM_CLUSTER}" install -y -f eastwest-gateway.yaml
kubectl --context="${PLATFORM_CLUSTER}" apply -n istio-system -f expose-services.yaml
istioctl --context="${PLATFORM_CLUSTER}" uninstall -y -f istio-config.yaml
istioctl --context="${PLATFORM_CLUSTER}" uninstall -y -f eastwest-gateway.yaml

# RAW manifests for Istio Control Plane and save it to a file
istioctl manifest generate -f istio-config.yaml >> service-mesh-config/istio-installation-manifests.yaml
kubectl apply -f service-mesh-config/istio-installation-manifests.yaml
kubectl apply -f common-manifests/ingress-class.yaml
kubectl apply -f service-mesh-config/kiali.yaml
kubectl apply -f service-mesh-config/prometheus.yaml
istioctl create-remote-secret \
    --context="${APP_CLUSTER}" \
    --name=app-cluster-01 | \
    kubectl apply -f - --context="${PLATFORM_CLUSTER}"
kubectl label secret istio-remote-secret-app-cluster-01 kiali.io/multiCluster=true \
  -n istio-system \
  --context="${PLATFORM_CLUSTER}"
kubectl get secrets istio-remote-secret-app-cluster-01  -o yaml -n istio-system --context=${PLATFORM_CLUSTER}

istioctl create-remote-secret \
  --context="${APP_CLUSTER}" \
  --name=app-cluster-01 \
  --service-account=kiali-remote \
  --secret-name=kiali-remote-token | \
  kubectl apply -f - --context="${PLATFORM_CLUSTER}"

# istioctl names the output secret as istio-remote-secret-<name>
kubectl label secret istio-remote-secret-app-cluster-01 \
  kiali.io/multiCluster=true \
  -n istio-system --context="${PLATFORM_CLUSTER}" --overwrite

kubectl rollout restart deployment/kiali -n istio-system --context="${PLATFORM_CLUSTER}"

# Delete all resources in a namespace
kubectl delete $(kubectl api-resources --namespaced=true --verbs=delete -o name | tr "\n" "," | sed 's/,$//') --all -n istio-system
helm uninstall aws-load-balancer-controller -n kube-system

export PLATFORM_GATEWAY=$(kubectl get svc istio-eastwestgateway -n istio-system \
  --context=${PLATFORM_CLUSTER} \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Platform Gateway: $PLATFORM_GATEWAY"

kubectl apply -f service-mesh-config/expose-services.yaml --context="${PLATFORM_CLUSTER}"
