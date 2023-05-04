.PHONY:
help:
	echo "See README.md"

ifeq ($(V),)
.SILENT:
endif

MAKEFLAGS += --no-builtin-rules --no-builtin-variables
.SUFFIXES:

PROGRESS := printf "  \\033[1;96m%10s\\033[0m  \\033[1;m%s\\033[0m\\n"

ifeq ($(shell uname),Darwin)
DO_TOKEN ?= $(shell yq e .access-token ~/Library/Application\ Support/doctl/config.yaml)
endif

TERRAFORM_FLAGS += -var "do_token=$(DO_TOKEN)"
TERRAFORM_FLAGS += -var "grafana_cloud_username=$(GRAFANA_CLOUD_USERNAME)"
TERRAFORM_FLAGS += -var "grafana_cloud_password=$(GRAFANA_CLOUD_PASSWORD)"

.PHONY: tf-plan
tf-plan:
	$(PROGRESS) TERRAFORM PLAN
	terraform plan $(TERRAFORM_FLAGS)

.PHONY: tf-apply
tf-apply:
	if [ "$$DO_TOKEN" = "" ]; then \
		echo DO_TOKEN is not set; \
		exit 1; \
	fi
	if [ "$$GRAFANA_CLOUD_USERNAME" = "" ]; then \
		echo GRAFANA_CLOUD_USERNAME is not set; \
		exit 1; \
	fi
	if [ "$$GRAFANA_CLOUD_PASSWORD" = "" ]; then \
		echo GRAFANA_CLOUD_PASSWORD is not set; \
		exit 1; \
	fi
	$(PROGRESS) TERRAFORM APPLY
	terraform apply $(TERRAFORM_FLAGS)

.PHONY: tf-destroy
tf-destroy:
	if [ "$$DO_TOKEN" = "" ]; then \
		echo DO_TOKEN is not set; \
		exit 1; \
	fi
	if [ "$$GRAFANA_CLOUD_USERNAME" = "" ]; then \
		echo GRAFANA_CLOUD_USERNAME is not set; \
		exit 1; \
	fi
	if [ "$$GRAFANA_CLOUD_PASSWORD" = "" ]; then \
		echo GRAFANA_CLOUD_PASSWORD is not set; \
		exit 1; \
	fi
	$(PROGRESS) TERRAFORM DESTROY
	terraform destroy $(TERRAFORM_FLAGS)
