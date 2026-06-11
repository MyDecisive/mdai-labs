CLUSTER ?= mdai-labs
IMAGE   ?= noisy-app:0.2.0

.PHONY: build load apply run teardown logs

build:
	docker build -t $(IMAGE) ./app

load: build
	kind load docker-image $(IMAGE) --name $(CLUSTER)

apply:
	./scripts/run-scenario.sh

run: load apply

teardown:
	./scripts/teardown.sh

logs:
	kubectl -n noisy-neighbor logs -f deploy/loadgen
