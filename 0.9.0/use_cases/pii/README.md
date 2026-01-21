# PII Redaction use case

## Install a cluster and mdai at version 0.9.0

```bash
mdai install --version 0.9.0 -f values/overrides_0.9.0-partial.yaml
```

## Jumping straight to dynamic

Apply all relevant files for dynamic pii workflow

```bash
mdai use_case pii --version 0.9.0 --workflow dynamic
```

## Update the Manual variables

**Port fwd the mdai-gateway service**

```bash
kubectl port-forward -n mdai svc/mdai-gateway 8081:8081
```

### Option 1: All variables at once, multi curl via make

**Use the Makefile to update the manual variables.**

```bash
make -C ./0.9.0/use_cases/pii variables-apply
```

### Option 2: One variable at a time, one curl

```bash
curl -sS -X POST -H 'Content-Type: application/json' -d '{"data":"\\\\b(?:\\\\d[ -]*){11,15}(\\\\d{4})\\\\b"}' 'http://localhost:8081/variables/hub/mdaihub-pii/var/cc_regex'

curl -sS -X POST -H 'Content-Type: application/json' -d '{"data":"****-****-****-$1"}' 'http://localhost:8081/variables/hub/mdaihub-pii/var/cc_template'
```

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
