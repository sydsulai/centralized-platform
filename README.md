# Centralized Platform

This repo talks about centralized platform for platform engineering team to create platform which will handle K8s deployment, Centralized OPA, Centralized ArgoCD Capability etc.,

## App Cluster Details

### App Istio Config

This app includes multi-cluster multi-network service mesh deployed in AWS EKS across region=ap-south-1 in a single account.

## References

- [Istio Multi Cluster Documentation](https://istio.io/latest/docs/setup/install/multicluster/multi-primary/)
- [Istio Certificae Trust Identity](https://istio.io/latest/docs/tasks/security/cert-management/plugin-ca-cert/)
- [Istio Deployment Models](https://istio.io/latest/docs/ops/deployment/deployment-models/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Open Policy Agent (OPA)](https://www.openpolicyagent.org/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Monitoring MultiCluster Istio with Prometheus Federation](https://istio.io/latest/docs/ops/configuration/telemetry/monitoring-multicluster-prometheus/)
- [Hierarchial Federation](https://prometheus.io/docs/prometheus/latest/federation/#hierarchical-federation)

## Issues Found

1. **Error:**

- Error creating: Internal error occurred: failed calling webhook "rev.namespace.sidecar-injector.istio.io": failed to call webhook: Post "https://istiod-default.istio-system.svc:443/inject?timeout=10s": tls: failed to verify certificate: x509: certificate is valid for istio-pilot.istio-system.svc, istiod-remote.istio-system.svc, istiod.istio-system.svc, not istiod-default.istio-system.svc

**Fix:**

- Update `centralized-cluster/cluster-configuration/service-mesh-config/istio-installation-manifests.yaml` so webhook `clientConfig.service.name` points to `istiod` (not `istiod-default`).
- Add an `istiod` Service alias in `istio-system` with the same selector/ports as `istiod-default`.
- Update mesh `discoveryAddress` to `istiod.istio-system.svc:15012` for consistency.
- Apply manifest and restart Istiod.

1. **Error:**

- Error creating: Internal error occurred: failed calling webhook "rev.namespace.sidecar-injector.istio.io": failed to call webhook: the server could not find the requested resource

**Fix:**

- Resource template configmap is failed to mount to the istiod pod and once its mounted its deployed.

1. **Issue: Prometheus metrics missing / Kiali showing no traffic data**

**Error / Symptom:**

- Prometheus was running and scraping successfully, but Istio traffic metrics (`istio_requests_total`, `istio_request_duration_milliseconds`, etc.) were absent. Kiali showed no service graph or traffic telemetry.

**Root Cause:**

- Istio removed the Mixer component in v1.7+. In the new in-proxy telemetry model, metrics are **not emitted by default** — Envoy sidecars must be explicitly told which metrics provider to use via the `Telemetry` API. Without a `Telemetry` resource, proxies expose raw stats but do not report Istio-generated metrics to Prometheus.

**Fix:**

- Added `centralized-cluster/cluster-configuration/service-mesh-config/telemetry.yaml` — a mesh-wide `Telemetry` resource (applied in `istio-system` with no selector) that registers `prometheus` as the metrics provider. This activates the Prometheus metrics pipeline inside every Envoy sidecar across the mesh.
