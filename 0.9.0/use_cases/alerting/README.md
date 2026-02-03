<!-- ### Manual Install

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
``` -->

# Intelligent Alerting

## Basic Set up - Connect your data

#### Apply Otel yaml

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/basic/otel.yaml -n mdai
```

#### Apply Prometheus Metric Scraper - configures prometheus to scrape log counts from collector

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/basic/scraper.yaml -n mdai
```

#### Mock Data

```bash
kubectl  apply -f ./mock-data/alerting.yaml
```

#### MDAI Hub

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/basic/hub.yaml -n mdai
```

<!-- End Basic -->

### Static Set Up - Static Fields to Get Slack Alerts

### Create Secret

##### Edit with your slack webhook. Follow [this guide](https://api.slack.com/messaging/webhooks) to get a webhook URL.

```bash
kubectl -n mdai create secret generic slack-webhook-secret \
  --from-literal=url='https://hooks.slack.com/services/XXXXX/XXXXX/XXXXX'
```

#### Apply MDAI Hub w/ Slack Webhook

There are 2 different intelligent alert scenarios error rate alert (`anomalous_error_rate`) and attribute based alert (`unmasked_cc_detected`).

There are 2 different alerting serivce options, Slack and Github. For this example, we will use Slack. _See [GH setup](/0.9.0/use_cases/alerting/README.md#apply-mdai-hub-w-github-action-workflow) below_

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/static/hub.yaml -n mdai
```

⚠️ _**Note**: The `anomalous_error_rate` prometheus alert currently requires **at least an hour's worth** of data to trigger._

_To test it sooner, temporarily replace the expression in [hub.yaml](/0.9.0/use_cases/alerting/static/hub.yaml#l15) with the lower-threshold expression below_

#### Apply Otel yaml

Converts your string "level" field into OTEL severity fields. Add conditions to connectors for [severity level](0.9.0/use_cases/alerting/static/otel.yaml#l56) and [cc attribute ](0.9.0/use_cases/alerting/static/otel.yaml#l65).

```bash
kubectl  apply -f ./0.9.0/use_cases/static/basic/otel.yaml -n mdai
```

---

#### Apply MDAI Hub w/ GitHub Action Workflow

You can trigger a GitHub repository workflow that supports workflow_dispatch.

- Use [example_workflow.yaml](/0.9.0/use_cases/alerting/github-template/example_workflow.yaml) to set this workflow up in your repo.

- Use a fine-grained PAT (or classic PAT) with Read and Write access to Actions for the target repo.

**Store it as a bearer value in a Secret (same namespace as the Hub CR):**

```shell
kubectl -n mdai create secret generic github-token \
  --from-literal=authorization="Bearer github_pat_********_*********"
```

Update on `hub.yaml` with following:

```yaml
rules:
- name: anomalous_error_rate
      when:
        alertName: anomalous_error_rate
        status: firing
      then:
        - callWebhook:
          # replace OWNER/REPO with your repo:
          url: https://api.github.com/repos/OWNER/REPO/actions/workflows/deploy.yml/dispatches
          method: POST
          templateRef: jsonTemplate
          payloadTemplate:
            value: |-
              {
                "ref": "${template:ref:-main}",
                "inputs": {
                  "env": "${template:env:-prod}",
                  "build_id": "${trigger:id}"
                }
              }
          templateValues:
            ref: main
            env: uat
          headersFrom:
            Authorization:
              secretKeyRef:
                name: github-token
                key: authorization
          headers:
            Accept: application/vnd.github+json
            X-GitHub-Api-Version: "2022-11-28"
            Content-Type: application/json
```
