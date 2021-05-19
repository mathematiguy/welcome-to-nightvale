IMAGE_NAME := $(shell basename `git rev-parse --show-toplevel` | tr '[:upper:]' '[:lower:]')
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')
DOCKER_REGISTRY := mathematiguy
IMAGE := $(DOCKER_REGISTRY)/$(IMAGE_NAME)
HAS_DOCKER ?= $(shell which docker)
RUN ?= $(if $(HAS_DOCKER), docker run $(DOCKER_ARGS) --rm -v $$(pwd):/work -w /work -u $(UID):$(GID) $(IMAGE))
UID ?= $(shell id -u)
GID ?= $(shell id -g)
DOCKER_ARGS ?=
LOG_LEVEL ?= INFO

.PHONY: docker docker-push docker-pull enter enter-root

all: models/cecil_speaks/pytorch_model.bin

generate: scripts/generate_text.py
	$(RUN) python3 $<

OUTPUT_DIR ?= models/cecil_speaks
train: models/cecil_speaks/pytorch_model.bin
models/cecil_speaks/pytorch_model.bin: scripts/train.py data/train.txt
	$(RUN) python3 $< --train_dir data --output_dir $(OUTPUT_DIR) --log_level $(LOG_LEVEL)

split: data/train.txt
data/train.txt: scripts/train_split.py nightvale/.crawl.done
	$(RUN) python3 $< --corpus_dir nightvale/corpus --output_dir data --log_level $(LOG_LEVEL)

crawl: nightvale/.crawl.done
nightvale/.crawl.done:
	$(RUN) bash -c 'cd nightvale && scrapy crawl transcripts -L $(LOG_LEVEL)' && touch $@

clean:
	rm -rf nightvale/transcripts.json nightvale/transcripts.txt models/*

docker:
	docker build $(DOCKER_ARGS) --tag $(IMAGE):$(GIT_TAG) .
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

docker-push:
	docker push $(IMAGE):$(GIT_TAG)
	docker push $(IMAGE):latest

docker-pull:
	docker pull $(IMAGE):$(GIT_TAG)
	docker tag $(IMAGE):$(GIT_TAG) $(IMAGE):latest

enter: DOCKER_ARGS=-it
enter:
	$(RUN) bash

enter-root: DOCKER_ARGS=-it
enter-root: UID=root
enter-root: GID=root
enter-root:
	$(RUN) bash
