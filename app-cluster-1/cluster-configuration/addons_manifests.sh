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

# Delete all resources in a namespace
kubectl delete $(kubectl api-resources --namespaced=true --verbs=delete -o name | tr "\n" "," | sed 's/,$//') --all -n istio-system
helm uninstall aws-load-balancer-controller -n kube-system