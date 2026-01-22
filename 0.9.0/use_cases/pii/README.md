# PII Redaction use case

## Install a cluster and mdai at version 0.9.0

```bash
mdai install --version 0.9.0 -f values/overrides_0.9.0-partial.yaml
```

## Install the MdaiHub CR

### Option 1: Jumping straight to dynamic - multi-variable approach

Apply all relevant files for dynamic pii workflow

```bash
mdai use_case pii --version 0.9.0 --workflow dynamic
```

#### Update the Manual variables

**Port fwd the mdai-gateway service**

```bash
kubectl port-forward -n mdai svc/mdai-gateway 8081:8081
```

**Use the Makefile to update the manual variables.**

```bash
make -C ./0.9.0/use_cases/pii variables-apply
```

### Option 2: Jumping straight to dynamic - single variable approach

Apply all relevant files for dynamic pii workflow for single-variable updates

```bash
mdai apply ./0.9.0/use_cases/pii/dynamic/hub-single-var.yaml
mdai apply ./0.9.0/use_cases/pii/dynamic/otel-single-var.yaml
mdai apply ./mock-data/pii.yaml
```

#### Update the Manual variables

**Port fwd the mdai-gateway service**

```bash
kubectl port-forward -n mdai svc/mdai-gateway 8081:8081
```

**Create a valid ottl safe regex string for your curl**

```bash
# This is an example function that creates an OTTL compatible regex string.
to_ottl_safe_regex_string() {
  local s=$1
  s=${s//\\/\\\\}
  s=${s//\\/\\\\}
  printf '%s\n' "$s"
}
```

**Create the regex as a string**

```bash
# This is an example credit card regex string
EXAMPLE_CC_REGEX='\b(?:\d[ -]*){11,15}(\d{4})\b'
```

**Transform the string to be ottl-safe and ready to use in a curl**

```bash
transformed_cc_str="$(to_ottl_safe_regex_string "$EXAMPLE_CC_REGEX")"

# expected output
# \\\\b(?:\\\\d[ -]*){11,15}(\\\\d{4})\\\\b
```

**Fire off the curl request and update your variables config map**

>[!NOTE]
>Make sure you port-forwarded the `mdai-gateway` pod to 8081 before `curl`ing.

```bash
# Given this ottl rule:
#   replace_pattern(attributes["cc"], "${env:CC_REGEX}", "${env:CC_TEMPLATE}")

# This curl updates the regex variable
curl -sS -X POST \
  -H 'Content-Type: application/json' \
  -d "$(printf '{"data":"%s"}' "$transformed_cc_str")" \
  'http://localhost:8081/variables/hub/mdaihub-pii/var/cc_regex'

# This curl updates the replace template for when the above regex is matched
# (ex. 1111-1111-1111-1234 will convert to "****-****-****-1234")
curl -sS -X POST \
  -H 'Content-Type: application/json' \
  -d '{"data":"********-****-****-$1"}' \
  'http://localhost:8081/variables/hub/mdaihub-pii/var/cc_template'
```

## Validate the changes are applied and working as expected

**Check config map**

Check your configmap (mdai-pii-variables) to make sure your variable was updated

```bash
kubectl describe -n mdai configmaps mdaihub-pii-variables
```

You should see something like the following output

```bash
Name:         mdaihub-pii-variables
Namespace:    mdai
Labels:       app.kubernetes.io/managed-by=mdai-operator
              mydecisive.ai/configmap-type=hub-variables
              mydecisive.ai/hub-name=mdaihub-pii
Annotations:  <none>

Data
====
CC_REGEX:
----
\\b(?:\\d[ -]*){11,15}(\\d{4})\\b

CC_TEMPLATE:
----
********-****-****-$1


BinaryData
====

Events:  <none>
```

**Check gateway-collector logs**

Check your collector logs are scrubbing your field as expected

```bash
kubectl logs -n mdai svc/gateway-collector
```

You should see something like the following output

```bash
Trace ID:
Span ID:
Flags: 0
LogRecord #79
ObservedTimestamp: 1970-01-01 00:00:00 +0000 UTC
Timestamp: 2026-01-22 02:02:03.066501 +0000 UTC
SeverityText:
SeverityNumber: Unspecified(0)
Body: Str(Action payment-check processed successfully)
Attributes:
     -> timestamp: Str(2025-05-14T12:04:22Z)
     -> level: Str(INFO)
     -> logger: Str(checkout-service)
     -> action: Str(payment-check)
     -> user_id: Int(1005)
     -> name: Str(Ella Johnson)
     -> ssn: Str(000-11-4444)
     -> phone: Str(123-456-5555)
     -> email: Str(ella.j@example.com)
     -> cc: Str(********-****-****-0002)
     -> billing_address: Str(207 Sunset Blvd, Los Angeles, CA 12345)
     -> transaction_id: Int(90005)
     -> amount: Double(49.99)
     -> duration: Int(30)
     -> status: Str(success)
     -> fluent.tag: Str(dummy)
```

Congrats, you updated manual variables.

----

## Makefile commands

Dry run (default)

```bash
make -C ./0.9.0/use_cases/pii variables
```

Dry run (explicit)

```bash
make -C ./0.9.0/use_cases/pii variables-dry
```

Actually send requests

```bash
make -C ./0.9.0/use_cases/pii variables-apply
```
Override hub name

```bash
make -C ./0.9.0/use_cases/pii variables HUBNAME=testhub
```

Override file or endpoint

```bash
make -C ./0.9.0/use_cases/pii variables VARS_FILE=custom.json BASE_URL=http://localhost:9000/variables/hub/foo/var
```
