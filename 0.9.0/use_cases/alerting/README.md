# Threshold Based Eventing use case

### Manual Install

```bash
kind create cluster --name mdai-labs
```

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

kubectl wait --for=condition=Established crd/certificates.cert-manager.io --timeout=60s

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=60s

kubectl wait --for=condition=Available=True deploy -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=60s
```

```bash
helm upgrade --install \
    mdai oci://ghcr.io/decisiveai/mdai-hub \
    --namespace mdai \
    --create-namespace \
    --version 0.9.0 \
    --values values/overrides_0.9.0-partial.yaml \
    --cleanup-on-fail
```

## Intelligent Alerting setup

#### Otel & Prometheus Scraper

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/otel.yaml -n mdai
```

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/scraper.yaml -n mdai
```

Note: The `anomalous_error_rate` prometheus alert currently requires at least an hour's worth of data to trigger.  
To test it sooner, temporarily replace the expression in [hub.yaml](/0.9.0/use_cases/alerting/hub.yaml#l15) with the lower-threshold expression below

#### Mock Data

```bash
kubectl  apply -f ./mock-data/alerting.yaml
```

Note: This is order dependant, otherwise fluentd will run into errors. Must run otel and prom scraper first.

---

### Create Secret

```bash
kubectl -n mdai create secret generic slack-webhook-secret \
  --from-literal=url='https://hooks.slack.com/services/XXXXX/XXXXX/XXXXX'
```

#### Apply MDAI Hub w/ Slack Webhook

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/hub.yaml -n mdai
```

#### GitHub Webhook Example on [hub.yaml](/0.9.0/use_cases/alerting/hub.yaml#l63)
