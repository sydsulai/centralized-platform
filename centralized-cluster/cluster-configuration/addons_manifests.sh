helm repo add eks https://aws.github.io/eks-charts

helm repo update eks

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=platform-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=ap-south-1 \
  --set vpcId=vpc-0f4aee78ed43774ab \
  --set image.repository=public.ecr.aws/eks/aws-load-balancer-controller

# Istio
# istioctl install --set profile=demo # Create Istio Control PLane Directly in the Cluster

# Create manifests for Istio Control Plane and save it to a file
# istioctl manifest generate --set profile=demo >> app-service-mesh-config/istio-installation-manifests.yaml
kubectl label namespace default istio-injection=enabled --overwrite


export PLATFORM_CLUSTER=$(kubectl config get-contexts -o name | grep -i platform-cluster)

# ISTIOCTL configuration setup
istioctl install --context="${PLATFORM_CLUSTER}" -f istio-config.yaml
istioctl --context="${PLATFORM_CLUSTER}" install -y -f eastwest-gateway.yaml
kubectl --context="${PLATFORM_CLUSTER}" apply -n istio-system -f expose-services.yaml
istioctl --context="${PLATFORM_CLUSTER}" uninstall -y -f istio-config.yaml
istioctl --context="${PLATFORM_CLUSTER}" uninstall -y -f eastwest-gateway.yaml

# RAW manifests for Istio Control Plane and save it to a file
istioctl manifest generate -f istio-config.yaml >> istio-installation-manifests.yaml

# Delete all resources in a namespace
kubectl delete $(kubectl api-resources --namespaced=true --verbs=delete -o name | tr "\n" "," | sed 's/,$//') --all -n istio-system