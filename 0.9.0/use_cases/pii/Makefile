# -------- Configuration --------
HUBNAME ?= mdaihub-pii
BASE_URL ?= http://localhost:8081/variables/hub/$(HUBNAME)/var
VARS_FILE ?= ./testdata/variables.json

# DRY_RUN=1 → print only
# DRY_RUN=0 → execute curl
DRY_RUN ?= 1

# -------- Targets --------
.PHONY: variables variables-dry variables-apply

variables: variables-dry

variables-dry:
	@$(MAKE) variables-run DRY_RUN=1

variables-apply:
	@$(MAKE) variables-run DRY_RUN=0

variables-run:
	@jq -r --arg base "$(BASE_URL)" '\
	  to_entries[] | \
	  .key as $$name | \
	  ( .value | del(.ottl) ) as $$body | \
	  ($$base + "/" + $$name) as $$url | \
	  "curl -sS -X POST -H '\''Content-Type: application/json'\'' -d " \
	  + ($$body | tojson | @sh) + " " + ($$url | @sh) \
	' "$(VARS_FILE)" | \
	while IFS= read -r cmd; do \
	  echo "--------------------------------------------------"; \
	  echo "$$cmd"; \
	  echo; \
	  if [ "$(DRY_RUN)" -eq 0 ]; then \
	    sh -c "$$cmd"; \
	  fi; \
	done

