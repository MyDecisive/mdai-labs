<!-- BASIC FLOW WITHOUT BREAKDOWN -->
<!-- Manual Install

kind create cluster --name mdai-labs

-----------

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

kubectl wait --for=condition=Established crd/certificates.cert-manager.io --timeout=60s

kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=60s

kubectl wait --for=condition=Available=True deploy -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=60s

------------

helm upgrade --install mdai oci://ghcr.io/decisiveai/mdai-hub --namespace mdai --create-namespace --version 0.9.0 --values values/overrides_0.9.0-partial.yaml --cleanup-on-fail

----- OR -----

helm upgrade --install \
    mdai oci://ghcr.io/decisiveai/mdai-hub \
    --namespace mdai \
    --create-namespace \
    --version 0.9.0 \
    --values values/overrides_0.9.0-partial.yaml \
    --cleanup-on-fail

Intelligent Alerting setup
---- IA otel & mock-data/fluentd ----

<!-- There is an issue HERE -->
<!--
helm upgrade --install --repo https://fluent.github.io/helm-charts fluent fluentd -f ./mock-data/alerting.yaml


kubectl  apply -f ./0.9.0/use_cases/alerting/otel.yaml -n mdai
kubectl  apply -f ./0.9.0/use_cases/alerting/scraper.yaml -n mdai

------ create secret -------

kubectl -n mdai create secret generic slack-webhook-secret \
  --from-literal=url='https://hooks.slack.com/services/XXXXX/XXXXX/XXXXX'

------ slack webhook -------

kubectl  apply -f ./0.9.0/use_cases/alerting/hub.yaml -n mdai

------ GH webhook ----------

kubectl create secret generic github-webhook-url \
  --from-env-file=.env \
  -n mdai

  -->

# Threshold Based Eventing use case

#### Prereqs

- MDAI Hub custom resource (CR) deployed
  - To test, (recommended) 0.9.0 Intelligent LogStream use-case
- You know the namespace of that CR (examples below use mdai).
- `kubectl` pointed at the correct cluster/namespace
- Any Secrets referenced by actions must live in the same namespace as the Hub CR.

### How to set up webhook actions

Two common webhook patterns for MDAI Hub actions:

1. Slack message
2. GitHub Actions workflow_dispatch

Template:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: webhook-templates
  namespace: mdai
data:
  github-workflow.json: |
    {
      "ref":   "${template:ref:-main}",
      "inputs": {
        "env":      "${template:env:-dev}",
        "build_id": "${trigger:id}"
      }
    }
  generic.json: |
    {
      "message": "${template:message:-MDAI event}",
      "hub":     "${trigger:hub_name}",
      "corr":    "${trigger:correlation_id}",
      "raw":     "${trigger:payload}"
    }
```

### Install a cluster and mdai at version 0.9.0

```bash
mdai install --version 0.9.0 -f values/overrides_0.9.0-partial.yaml
```

### Apply the threshold-based webhook use case

```bash
mdai use_case threshold_based_webhook --version 0.9.0
```

### Verify

```bash
kubectl get configmap webhook-templates -n mdai
```

## Slack webhook setup

### Create Slack webhook Secret

```bash
kubectl -n mdai create secret generic slack-webhook-secret \
  --from-literal=url='https://hooks.slack.com/services/XXXXX/XXXXX/XXXXX'
```

### Patch webhook rules into Hub CR

```bash
kubectl patch mdaihub mdaihub-ddf \
  -n mdai \
  --type=merge \
  --patch-file=0.9.0/use_cases/threshold_based_webhook/webhook-rules-patch.yaml
```

## GitHub Actions workflow trigger

### Create workflow in target repo

- Workflow must support workflow_dispatch.

```bash
on:
  workflow_dispatch:
    inputs:
      env:
        required: true
      build_id:
        required: true
```

### Create GitHub token Secret

```bash
kubectl -n mdai create secret generic github-token \
  --from-literal=authorization="Bearer github_pat_XXXXXXXX"
```

## Update Hub CR webhook action

### Edit your Hub CR to include the GitHub dispatch webhook:

```bash
url:
  value: https://api.github.com/repos/OWNER/REPO/actions/workflows/deploy.yml/dispatches
```

<!-- OLD, but using to update the above -->
<!-- ### Slack webhook setup

Get your Slack wehbook URL. Follow [this guide](https://api.slack.com/messaging/webhooks) to get a webhook URL.
For security, store it in a Secret and reference it from the action.

#### 1) Create the Secret (replace the URL):

```shell
kubectl -n mdai create secret generic slack-webhook-secret \
  --from-literal=url='https://hooks.slack.com/services/XXXXXXXXXXXXXXXXXXXXXXXX'
```

#### 2) Reference it from your Hub CR action:

Use examples from [webhook-rules-patch.yaml](/0.9.0/use_cases/threshold_based_webhook/webhook-rules-patch.yaml) to add an action with built-in slack template to your hub custom resource.

```sh
# Patch in webhook rules from separate file
kubectl patch mdaihub mdaihub-ddf -n mdai --type=merge --patch-file=0.9.0/use_cases/threshold_based_webhook/webhook-rules-patch.yaml
```

### GitHub Action trigger (workflow_dispatch)

You can trigger a repository workflow that supports workflow_dispatch.

#### 1) Example workflow in your repo (e.g., .github/workflows/deploy.yml):

```yaml
name: Dispatch Test
on:
  workflow_dispatch:
    inputs:
      env:
        description: Environment
        required: true
        default: dev
      build_id:
        description: Build ID
        required: true
        default: local
jobs:
  echo:
    runs-on: ubuntu-latest
    steps:
      - run: echo "env=${{ github.event.inputs.env }} build_id=${{ github.event.inputs.build_id }}"
```

#### 2) Create a GitHub token and Secret

- Use a fine-grained PAT (or classic PAT) with Read and Write access to Actions for the target repo.
- Store it as a bearer value in a Secret (same namespace as the Hub CR):

```shell
kubectl -n mdai create secret generic github-token \
  --from-literal=authorization="Bearer github_pat_********_*********"
```

#### 3) Add action to your Hub CR to call GitHub’s dispatch API:

- Use examples from [hub_ref_webhook_actions.yaml](https://github.com/DecisiveAI/mdai-labs/blob/01701c6b71f9ab478bec0157406f1cb520d8d54d/mdai/hub/0.9.0/hub_ref_webhook_actions.yaml#L182-L206) to add an action which will trigger your GitHub webhook to your hub custom resource `hub_ref.yaml`.
- Update `OWNER/REPO` in repo URL with the one you created:
  `url: { value: https://api.github.com/repos/OWNER/REPO/actions/workflows/deploy.yml/dispatches }`
- Re-apply your updated hub custom resource.

```sh
kubectl apply -f ./mdai/hub/0.9.0/hub_ref.yaml -n mdai
```

Additional template examples could be found at [webhook-templates.yaml](https://github.com/DecisiveAI/mdai-labs/blob/01701c6b71f9ab478bec0157406f1cb520d8d54d/mdai/hub/0.9.0/configmaps/webhook-templates.yaml)

### Validation & best practices

• URL must be an absolute http(s) URL (whether provided inline via url.value or indirectly via urlFrom.secretKeyRef).
• HTTP method must be one of the allowed values (use POST when payloadTemplate is present).
• Do not combine a Slack-specific template (if your cluster provides one) with payloadTemplate. Use one or the other.
• Keep tokens and webhooks only in Secrets; never commit them to Git.
• Ensure Secrets and the Hub CR are in the same namespace.

## Appendix 1: How to make error conditions happen for testing

The `anomalous_error_rate` prometheus alert currently requires at least an hour's worth of data to trigger.
To test it sooner, temporarily replace the expression in [hub.yaml](0.9.0/use_cases/data_filtration/dynamic/hub.yaml) with the lower-threshold expression below:

```yaml
- name: anomalous_error_rate
      expr: "sum(increase(error_logs_by_service_total[5m])) by (mdai_service) > 0.1 * sum(avg_over_time(increase(error_logs_by_service_total[5m])[1h:])) by (mdai_service)"
      severity: warning
      for: 3m
      keep_firing_for: 3m
``` -->
