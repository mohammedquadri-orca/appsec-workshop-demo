# Orca AppSec end-to-end demo
#
# Typical order:
#   make bootstrap OWNER=<you>     # state bucket (tagged orca-cloud-to-dev=true)
#   make apply     OWNER=<you>     # VPC, ECR, EC2, buckets
#   make build push-image          # build linux/amd64 image, push to ECR
#   ...demo...
#   make destroy   OWNER=<you>     # main stack (ECR images are force-deleted)
#   make destroy-bootstrap OWNER=<you>   # state bucket – LAST
#
# Requires: docker, terraform >= 1.10, aws cli (authenticated to the SANDBOX account).

SHELL        := /bin/bash
AWS_REGION   ?= us-east-1
OWNER        ?=
IMAGE_NAME   ?= orca-appsec-demo
LOCAL_TAG    ?= local
IMAGE_TAG    ?= v1
REPO_URL     ?= $(shell git remote get-url origin 2>/dev/null | sed -E 's|git@github.com:|https://github.com/|; s|\.git$$||')
GIT_SHA      ?= $(shell git rev-parse --short HEAD 2>/dev/null)

TF_VARS      = -var "owner=$(OWNER)" -var "region=$(AWS_REGION)"
TF           = terraform -chdir=infra
TF_BOOT      = terraform -chdir=infra/bootstrap

.PHONY: help check-owner bootstrap init plan apply build push-image destroy destroy-bootstrap scan-local hook-install hook-uninstall

help:
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk -F':.*?## ' '{printf "  %-18s %s\n", $$1, $$2}'

check-owner:
	@test -n "$(OWNER)" || { echo "ERROR: set OWNER, e.g. make $(MAKECMDGOALS) OWNER=jdoe"; exit 1; }

bootstrap: check-owner ## Create the Terraform state bucket (local state) and write infra/backend.hcl
	$(TF_BOOT) init -input=false
	$(TF_BOOT) apply $(TF_VARS)
	@printf 'bucket = "%s"\nregion = "%s"\n' "$$($(TF_BOOT) output -raw state_bucket)" "$(AWS_REGION)" > infra/backend.hcl
	@echo "Wrote infra/backend.hcl:"; cat infra/backend.hcl

init: ## terraform init for the main stack against the S3 backend
	@test -f infra/backend.hcl || { echo "ERROR: run 'make bootstrap' first"; exit 1; }
	$(TF) init -input=false -reconfigure -backend-config=backend.hcl

plan: check-owner init ## terraform plan for the main stack
	$(TF) plan $(TF_VARS) -var "image_tag=$(IMAGE_TAG)"

apply: check-owner init ## terraform apply for the main stack (prompts for approval)
	$(TF) apply $(TF_VARS) -var "image_tag=$(IMAGE_TAG)"

build: ## Build the app image (linux/amd64) as orca-appsec-demo:local
	docker build --platform linux/amd64 \
	  --build-arg REPO_URL="$(REPO_URL)" --build-arg GIT_SHA="$(GIT_SHA)" \
	  -t $(IMAGE_NAME):$(LOCAL_TAG) .

push-image: ## Tag and push orca-appsec-demo:local to ECR as $(IMAGE_TAG)
	@ECR_URL="$$($(TF) output -raw ecr_repository_url)" && \
	REGISTRY="$${ECR_URL%%/*}" && \
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin "$$REGISTRY" && \
	docker tag $(IMAGE_NAME):$(LOCAL_TAG) "$$ECR_URL:$(IMAGE_TAG)" && \
	docker push "$$ECR_URL:$(IMAGE_TAG)"

destroy: check-owner init ## Destroy the main stack (ECR repo is force-deleted with its images)
	$(TF) destroy $(TF_VARS) -var "image_tag=$(IMAGE_TAG)"

destroy-bootstrap: check-owner ## Destroy the state bucket – run LAST, after 'make destroy'
	$(TF_BOOT) destroy $(TF_VARS)
	rm -f infra/backend.hcl

scan-local: ## Run all orca-cli scans locally (needs ORCA_SECURITY_API_TOKEN + ORCA_PROJECT_KEY)
	./scripts/orca-local-scan.sh

hook-install: ## Install the Orca secrets pre-commit hook into .git/hooks
	ln -sf ../../scripts/pre-commit-orca-secrets.sh .git/hooks/pre-commit
	@echo "Installed. Note: if git core.hooksPath points elsewhere, run: git config core.hooksPath .git/hooks"

hook-uninstall: ## Remove the Orca secrets pre-commit hook
	rm -f .git/hooks/pre-commit
