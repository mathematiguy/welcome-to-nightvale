IMAGE_NAME := $(shell basename `git rev-parse --show-toplevel` | tr '[:upper:]' '[:lower:]')
GIT_TAG ?= $(shell git log --oneline | head -n1 | awk '{print $$1}')
DOCKER_REGISTRY := mathematiguy
COMPUTE ?= gpu
IMAGE := $(DOCKER_REGISTRY)/$(IMAGE_NAME)-$(COMPUTE)
HAS_DOCKER ?= $(shell which docker)
RUN ?= $(if $(HAS_DOCKER), docker run $(DOCKER_ARGS) --gpus all --ipc host --rm -v $$(pwd):/work -w /work -u $(UID):$(GID) $(IMAGE))
UID ?= $(shell id -u)
GID ?= $(shell id -g)
DOCKER_ARGS ?=
LOG_LEVEL ?= INFO

.PHONY: docker docker-push docker-pull enter enter-root

MODEL_NAME ?= cecil_speaks

all: models/$(MODEL_NAME)/pytorch_model.bin

generate: scripts/generate_text.py
	$(RUN) python3 $<

OUTPUT_DIR ?= models/$(MODEL_NAME)
NUM_TRAIN_EPOCHS ?= 20
PER_DEVICE_TRAIN_BATCH_SIZE ?= 24
PER_DEVICE_EVAL_BATCH_SIZE ?= 32
EVAL_STEPS ?= 400
SAVE_STEPS ?= 800
WARMUP_STEPS ?= 500
train: models/$(MODEL_NAME)/pytorch_model.bin
models/$(MODEL_NAME)/pytorch_model.bin: scripts/train.py data/train.txt
	$(RUN) python3 $< \
			--train_dir data \
			--output_dir $(dir $@) \
			--num_train_epochs $(NUM_TRAIN_EPOCHS) \
			--per_device_train_batch_size $(PER_DEVICE_TRAIN_BATCH_SIZE) \
			--per_device_eval_batch_size $(PER_DEVICE_EVAL_BATCH_SIZE) \
			--eval_steps $(EVAL_STEPS) \
			--save_steps $(SAVE_STEPS) \
			--warmup_steps $(WARMUP_STEPS) \
			--log_level $(LOG_LEVEL)

split: data/train.txt
data/train.txt: scripts/train_split.py nightvale/.crawl.done
	$(RUN) python3 $< --corpus_dir nightvale/corpus --output_dir data --log_level $(LOG_LEVEL)

crawl: nightvale/.crawl.done
nightvale/.crawl.done:
	$(RUN) bash -c 'cd nightvale && scrapy crawl transcripts -L $(LOG_LEVEL)' && touch $@

clean:
	rm -rf nightvale/transcripts.json nightvale/transcripts.txt models/*

docker:
	docker build $(DOCKER_ARGS) --tag $(IMAGE):$(GIT_TAG) -f Dockerfile.$(COMPUTE) .
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
