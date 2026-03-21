# Centralized Platform

This repo talks about centralized platform for platform engineering team to create platform which will handle K8s deployment, Centralized OPA, Centralized ArgoCD Capability etc.,

## App Cluster Details

### App Istio Config

- customresourcedefinition.apiextensions.k8s.io/authorizationpolicies.security.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/destinationrules.networking.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/envoyfilters.networking.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/gateways.networking.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/peerauthentications.security.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/proxyconfigs.networking.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/requestauthentications.security.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/serviceentries.networking.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/sidecars.networking.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/telemetries.telemetry.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/virtualservices.networking.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/wasmplugins.extensions.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/workloadentries.networking.istio.io unchanged
- customresourcedefinition.apiextensions.k8s.io/workloadgroups.networking.istio.io unchanged
- serviceaccount/istio-egressgateway-service-account created
- serviceaccount/istio-ingressgateway-service-account created
- serviceaccount/istio-reader-service-account created
- serviceaccount/istiod created
- clusterrole.rbac.authorization.k8s.io/istio-reader-clusterrole-istio-system unchanged
- clusterrole.rbac.authorization.k8s.io/istiod-clusterrole-istio-system unchanged
- clusterrole.rbac.authorization.k8s.io/istiod-gateway-controller-istio-system unchanged
- clusterrolebinding.rbac.authorization.k8s.io/istio-reader-clusterrole-istio-system unchanged
- clusterrolebinding.rbac.authorization.k8s.io/istiod-clusterrole-istio-system unchanged
- clusterrolebinding.rbac.authorization.k8s.io/istiod-gateway-controller-istio-system unchanged
- validatingwebhookconfiguration.admissionregistration.k8s.io/istio-validator-istio-system configured
- configmap/istio created
- configmap/istio-sidecar-injector created
- configmap/values created
- mutatingwebhookconfiguration.admissionregistration.k8s.io/istio-sidecar-injector configured
- deployment.apps/istio-egressgateway created
- deployment.apps/istio-ingressgateway created
- deployment.apps/istiod created
- role.rbac.authorization.k8s.io/istio-egressgateway-sds created
- role.rbac.authorization.k8s.io/istio-ingressgateway-sds created
- role.rbac.authorization.k8s.io/istiod created
- rolebinding.rbac.authorization.k8s.io/istio-egressgateway-sds created
- rolebinding.rbac.authorization.k8s.io/istio-ingressgateway-sds created
- rolebinding.rbac.authorization.k8s.io/istiod created
- service/istio-egressgateway created
- service/istio-ingressgateway created
- service/istiod created