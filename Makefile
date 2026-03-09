.PHONY: help init plan apply destroy validate fmt lint shellcheck clean pre-commit \
       puppet-deps puppet-lint puppet-validate puppet-test \
       bolt-apply bolt-provision bolt-cleanup

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

puppet-deps: ## Install Puppet gem dependencies
	cd puppet && bundle install

puppet-lint: ## Run puppet-lint on manifests
	cd puppet && bundle exec puppet-lint --relative site-modules/

puppet-validate: ## Validate Puppet manifests
	cd puppet && bundle exec puppet parser validate site-modules/role/manifests/*.pp site-modules/profile/manifests/**/*.pp

puppet-test: ## Run rspec-puppet tests
	cd puppet && bundle exec rake spec

bolt-apply: ## Apply Puppet role to Mac instance via Bolt
	cd puppet/bolt && bolt apply --targets mac_runners -e 'include role::github_actions_mac_runner'

bolt-provision: ## Provision runner via Bolt (requires RUNNER_TOKEN and RUNNER_URL)
	@test -n "$(RUNNER_URL)" || (echo "ERROR: Set RUNNER_URL (e.g. https://github.com/org/repo)" && exit 1)
	@test -n "$(RUNNER_TOKEN)" || (echo "ERROR: Set RUNNER_TOKEN (gh api -X POST repos/{owner}/{repo}/actions/runners/registration-token --jq '.token')" && exit 1)
	cd puppet/bolt && bolt plan run provision \
		--targets mac_runners \
		github_runner_url='$(RUNNER_URL)' \
		github_runner_token='$(RUNNER_TOKEN)'

bolt-cleanup: ## De-register and remove runner via Bolt (optional RUNNER_TOKEN)
	cd puppet/bolt && bolt plan run cleanup \
		--targets mac_runners \
		$(if $(RUNNER_TOKEN),github_runner_token='$(RUNNER_TOKEN)')

clean: ## Remove Terraform cache and state files
	find $(TERRAFORM_DIR) -name ".terraform" -type d -exec rm -rf {} + 2>/dev/null || true
	find $(TERRAFORM_DIR) -name ".terraform.lock.hcl" -delete 2>/dev/null || true
