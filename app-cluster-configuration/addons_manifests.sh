
# AWS Load Balancer Controller
# curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.14.1/docs/install/iam_policy.json

# aws iam create-policy \
#     --policy-name AWSLoadBalancerControllerIAMPolicy \
#     --policy-document file://iam_policy.json

# eksctl create iamserviceaccount \
#     --cluster=app-cluster-01 \
#     --namespace=kube-system \
#     --name=aws-load-balancer-controller \
#     --attach-policy-arn=arn:aws:iam::829007908826:policy/AWSLoadBalancerControllerIAMPolicy \
#     --override-existing-serviceaccounts \
#     --region ap-south-1 \
#     --approve

helm repo add eks https://aws.github.io/eks-charts

helm repo update eks

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=app-cluster-01 \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=ap-south-1 \
  --set vpcId=vpc-0389f3c94ce5dc2f4 \
  --set image.repository=public.ecr.aws/eks/aws-load-balancer-controller

# VPA
git clone https://github.com/kubernetes/autoscaler.git
cd autoscaler/vertical-pod-autoscaler/
./hack/vpa-down.sh
./hack/vpa-up.sh

# Cluster Autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
kubectl -n kube-system annotate deployment.apps/cluster-autoscaler cluster-autoscaler.kubernetes.io/safe-to-evict="false"

# Istio
istioctl install --set profile=demo # Create Istio Control PLane Directly in the Cluster

# Create manifests for Istio Control Plane and save it to a file
istioctl manifest generate --set profile=demo >> app-service-mesh-config/istio-installation-manifests.yaml
kubectl apply -f app-service-mesh-config/istio-installation-manifests.yaml