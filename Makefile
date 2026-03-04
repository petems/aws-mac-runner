.PHONY: help init plan apply destroy validate fmt lint shellcheck clean pre-commit

TERRAFORM_DIR := terraform

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform
	cd $(TERRAFORM_DIR) && OTEL_TRACES_EXPORTER= terraform init

plan: ## Run Terraform plan
	cd $(TERRAFORM_DIR) && OTEL_TRACES_EXPORTER= terraform plan

apply: ## Apply Terraform changes
	cd $(TERRAFORM_DIR) && OTEL_TRACES_EXPORTER= terraform apply

destroy: ## Destroy all infrastructure (24h billing warning!)
	@echo "WARNING: Ensure you have de-registered the GitHub runner first."
	@echo "WARNING: Dedicated host has a 24-hour minimum allocation period."
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	cd $(TERRAFORM_DIR) && OTEL_TRACES_EXPORTER= terraform destroy

validate: ## Validate Terraform configuration
	cd $(TERRAFORM_DIR) && OTEL_TRACES_EXPORTER= terraform validate

fmt: ## Format Terraform files
	cd $(TERRAFORM_DIR) && OTEL_TRACES_EXPORTER= terraform fmt -recursive

fmt-check: ## Check Terraform formatting
	cd $(TERRAFORM_DIR) && OTEL_TRACES_EXPORTER= terraform fmt -check -recursive

lint: ## Run tflint
	cd $(TERRAFORM_DIR) && tflint --recursive

shellcheck: ## Run shellcheck on all scripts
	shellcheck -x scripts/*.sh

pre-commit: ## Run pre-commit hooks
	pre-commit run --all-files

clean: ## Remove Terraform cache and state files
	find $(TERRAFORM_DIR) -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find $(TERRAFORM_DIR) -name ".terraform.lock.hcl" -delete 2>/dev/null || true
