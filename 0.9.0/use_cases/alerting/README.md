# Intelligent Alerting

## Basic - Connect your data

#### Apply Otel yaml

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/basic/otel.yaml -n mdai
```

#### Mock Data

```bash
kubectl  apply -f ./mock-data/alerting.yaml
```

#### MDAI Hub

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/basic/hub.yaml -n mdai
```

## Static - Static Fields to Get Slack Alerts

### Create Secret

##### Edit with your slack webhook. Follow [this guide](https://api.slack.com/messaging/webhooks) to get a webhook URL.

```bash
kubectl -n mdai create secret generic slack-webhook-secret \
  --from-literal=url='https://hooks.slack.com/services/XXXXX/XXXXX/XXXXX'
```

#### Apply MDAI Hub w/ Slack Webhook

There are 2 different intelligent alert scenarios error rate alert (`anomalous_error_rate`) and attribute based alert (`unmasked_cc_detected`).

There are 2 different alerting serivce options, Slack and Github. For this example, we will use Slack. _See [GH setup](/0.9.0/use_cases/alerting/README.md#apply-mdai-hub-w-github-action-workflow) below_

##### Error Rate Alert

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/static/error_rate_alert/hub.yaml -n mdai
```

##### Disallowed Field Alerting

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/static/disallowed_field_alert/hub.yaml -n mdai
```

#### Apply Otel yaml

##### Error Rate Alert

Converts your string "level" field into OTEL severity fields. Add conditions to connectors for severity level.

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/static/error_rate_alert/otel.yaml -n mdai
```

##### Disallowed Field Alerting

Add conditions to connectors for cc attribute.

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/static/disallowed_field_alert/otel.yaml -n mdai
```

#### Apply Prometheus Metric Scraper - configures prometheus to scrape log counts from collector

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/static/scraper.yaml -n mdai
```

#### Check Slack

In the slack you configured, you should see new messages. Attribute alert will only take a moment and error rate will take 5 minutes.

⚠️ _**Note**: The `anomalous_error_rate` prometheus alert currently requires **at least an hour's worth** of data to trigger._

_To test it sooner, temporarily replace the expression in [hub.yaml](/0.9.0/use_cases/alerting/static/hub.yaml#l15) with the lower-threshold expression below_

Examples:

```
Unmasked credit card data detected in logs (cc attribute). Investigate immediately.
Alert timestamp - 2026-02-02 19:35:22.124 +0000 UTC
mdai_service - user-service
status - firing
alertname - unmasked_cc_detected

Service was >2x expected error rate for five minutes compared to the last hour!
Alert timestamp - 2026-02-02 19:37:22.124 +0000 UTC
mdai_service - payment-service
status - firing
alertname - anomalous_error_rate
```

## Dynamic - Dynamic Variables triggering Alerts

##### Error Rate Alert

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/dynamic/error_rate_alert/hub.yaml -n mdai
```

##### Disallowed Field Alerting

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/dynamic/disallowed_field_alert/hub.yaml -n mdai
```

#### Apply Otel yaml

##### Error Rate Alert

Converts your string "level" field into OTEL severity fields. Add conditions to connectors for severity level.

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/dynamic/error_rate_alert/otel.yaml -n mdai
```

##### Disallowed Field Alerting

Add conditions to connectors for cc attribute.

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/dynamic/disallowed_field_alert/otel.yaml -n mdai
```

#### Apply Prometheus Metric Scraper - configures prometheus to scrape log counts from collector

```bash
kubectl  apply -f ./0.9.0/use_cases/alerting/static/scraper.yaml -n mdai
```

#### Stop the mock data to stop the alert for testing

Skip this step if you skipped ahead to dynamic.

```bash
kubectl scale deployment fluentd -n default --replicas=0
```

#### Port-forward the gateway

```bash
kubectl port-forward -n mdai svc/mdai-gateway 8081:8081
```

#### Set up service tiers

##### Set Tier Lists (required)

These tier variables are `dataType: set`. The gateway expects a **list** payload. Each request replaces the full list for that tier.

```bash
# Tier 1 (set the full list)
curl -sS -X POST \
  -H 'Content-Type: application/json' \
  -d '{"data":["payment-service","auth-service"]}' \
  'http://localhost:8081/variables/hub/mdaihub-aer/var/tier_1_service_list'

# Tier 2–3 (set the full list)
curl -sS -X POST \
  -H 'Content-Type: application/json' \
  -d '{"data":["checkout-service","inventory-service"]}' \
  'http://localhost:8081/variables/hub/mdaihub-aer/var/tier_2_3_service_list'

# Tier 4–7 (set the full list)
curl -sS -X POST \
  -H 'Content-Type: application/json' \
  -d '{"data":["catalog-service","notification-service","shipping-service"]}' \
  'http://localhost:8081/variables/hub/mdaihub-aer/var/tier_4_7_service_list'
```

##### Remove a Service (by overwriting the list)

There is no `remove` operation for set variables via this gateway endpoint. To remove a service, POST the list again without that service.

```bash
# Remove auth-service from Tier 1 by setting Tier 1 to only payment-service
curl -sS -X POST \
  -H 'Content-Type: application/json' \
  -d '{"data":["payment-service"]}' \
  'http://localhost:8081/variables/hub/mdaihub-aer/var/tier_1_service_list'
```

#### Check your configmap (mdaihub-aer-variables) to make sure your variable was updated

```bash
kubectl describe -n mdai configmaps mdaihub-aer-variables
```

#### Reset mock data to run

```bash
kubectl scale deployment fluentd -n default --replicas=1
```

OR run [mock data command](#mock-data) if you skipped ahead to dynamic

---

### Apply MDAI Hub w/ GitHub Action Workflow

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
