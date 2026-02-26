#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
.PHONY: all security lint format documentation documentation-examples validate-all validate validate-examples init examples tests

AWS_ECR_REGION ?= eu-west-2
DOCKER_IMAGE ?= 676206913132.dkr.ecr.${AWS_ECR_REGION}.amazonaws.com/lz/services/nuke
DOCKER_PLATFORM ?= linux/amd64
NUKE_IMAGE ?= ghcr.io/ekristen/aws-nuke
NUKE_TAG ?= v3.63.4-10-g985b49c-amd64

default: all

all:
	$(MAKE) init
	$(MAKE) validate
	$(MAKE) tests
	$(MAKE) lint
	$(MAKE) security
	$(MAKE) format
	$(MAKE) documentation

examples:
	$(MAKE) validate-examples
	$(MAKE) tests
	$(MAKE) lint-examples
	$(MAKE) lint
	$(MAKE) security
	$(MAKE) format
	$(MAKE) documentation

documentation:
	@echo "--> Generating documentation"
	@terraform-docs .
	$(MAKE) documentation-modules
	$(MAKE) documentation-examples

documentation-modules:
	@echo "--> Generating documentation for modules"
	@find . -type d -regex '.*/modules/[a-za-z\-\_]*' -not -path '*.terraform*' 2>/dev/null | while read -r dir; do \
		echo "--> Generating documentation for module: $$dir"; \
		terraform-docs $$dir; \
	done;

documentation-examples:
	@echo "--> Generating documentation for examples"
	@find . -type d -path '*/examples/*' -not -path '*.terraform*' 2>/dev/null| while read -r dir; do \
		echo "--> Generating documentation for example: $$dir"; \
		terraform-docs $$dir; \
	done;

docker-ecr-image:
	@echo "--> Building the Lambda compatible docker image ..."
	@echo "--> Change the image name by setting the DOCKER_IMAGE environment variable (default: ${DOCKER_IMAGE})"
	@echo "--> Change the aws-nuke image by setting the NUKE_IMAGE environment variable (default: ${NUKE_IMAGE})"
	@echo "--> Change the aws-nuke tag by setting the NUKE_TAG environment variable (default: ${NUKE_TAG})"
	@echo "--> Change the AWS region by setting the AWS_ECR_REGION environment variable (default: ${AWS_ECR_REGION})"
	@docker build \
	--build-arg NUKE_IMAGE=${NUKE_IMAGE} \
	--build-arg NUKE_TAG=${NUKE_TAG} \
	--platform ${DOCKER_PLATFORM} \
	--provenance=false \
	--sbom=false \
	-t ${DOCKER_IMAGE}:${NUKE_TAG} \
	-f assets/docker/Dockerfile assets/docker
	@echo "--> successfully built the image: ${DOCKER_IMAGE}:${NUKE_TAG}"

docker-ecr-image-push:
	@$(MAKE) docker-ecr-image
	@echo "--> Pushing the Lambda compatible docker image"
	@docker push ${DOCKER_IMAGE}:${NUKE_TAG}

upgrade-terraform-providers:
	@printf "%s Upgrading Terraform providers for %-24s" "-->" "."
	@terraform init -upgrade >/dev/null && echo "[OK]" || echo "[FAILED]"
	@$(MAKE) upgrade-terraform-example-providers

upgrade-terraform-example-providers:
	@if [ -d examples ]; then \
		find examples -type d -mindepth 1 -maxdepth 1 2>/dev/null | while read -r dir; do \
			printf "%s Upgrading Terraform providers for %-24s" "-->" "$$dir"; \
			terraform -chdir=$$dir init -upgrade >/dev/null && echo "[OK]" || echo "[FAILED]"; \
		done; \
	fi

init:
	@echo "--> Running terraform init"
	@terraform init -backend=false
	@find . -type f -name "*.tf" -not -path '*.terraform*' -exec dirname {} \; | sort -u | while read -r dir; do \
		echo "--> Running terraform init in $$dir"; \
		terraform -chdir=$$dir init -backend=false; \
	done;

security: init
	@echo "--> Running Security checks"
	@trivy config .
	$(MAKE) security-modules
	$(MAKE) security-examples

security-modules:
	@echo "--> Running Security checks on modules"
	@find . -type d -regex '.*/modules/[a-zA-Z\-_$$]*' -not -path '*.terraform*' 2>/dev/null | while read -r dir; do \
		echo "--> Validating $$dir"; \
	  terraform init -backend=false; \
		trivy config  --format table --exit-code  1 --severity  CRITICAL,HIGH --ignorefile .trivyignore $$dir; \
	done;

security-examples:
	@echo "--> Running Security checks on examples"
	@find . -type d -path '*/examples/*' -not -path '*.terraform*' 2>/dev/null | while read -r dir; do \
		echo "--> Validating $$dir"; \
	  terraform init -backend=false; \
		trivy config  --format table --exit-code  1 --severity  CRITICAL,HIGH --ignorefile .trivyignore $$dir; \
	done;

tests:
	@echo "--> Running Terraform Tests"
	@terraform test

validate:
	@echo "--> Running terraform validate"
	@terraform init -backend=false
	@terraform validate
	$(MAKE) validate-modules
	$(MAKE) validate-examples
	$(MAKE) validate-commits

validate-modules:
	@echo "--> Running terraform validate on modules"
	@find . -type d -regex './modules/[a-zA-Z\-]*' -not -path '*.terraform*' 2>/dev/null | while read -r dir; do \
		echo "--> Validating Module $$dir"; \
		terraform -chdir=$$dir init -backend=false; \
		terraform -chdir=$$dir validate; \
	done;

validate-examples:
	@echo "--> Running terraform validate on examples"
	@find . -type d -path '*/examples/*' -not -path '*.terraform*' 2>/dev/null | while read -r dir; do \
		echo "--> Validating $$dir"; \
		terraform -chdir=$$dir init -backend=false; \
		terraform -chdir=$$dir validate; \
	done;

validate-commits:
	@echo "--> Running commitlint against the main branch"
	@command -v commitlint >/dev/null 2>&1 || { echo "commitlint is not installed. Please install it by running 'npm install -g commitlint'"; exit 1; }
	@git log --pretty=format:"%s" origin/main..HEAD | commitlint --from=origin/main

python-tests:
	@echo "--> Running Python tests"
	@python3 -m unittest discover -s assets/docker -p 'test_*.py'

lint:
	@echo "--> Running tflint"
	@tflint --init
	@tflint -f compact
	$(MAKE) lint-modules
	$(MAKE) lint-examples

lint-modules:
	@echo "--> Running tflint on modules"
	@find . -type d -regex '.*/modules/[a-zA-Z\-_$$]*' -not -path '*.terraform*' 2>/dev/null | while read -r dir; do \
		echo "--> Linting $$dir"; \
		tflint --chdir=$$dir --init; \
		tflint --chdir=$$dir -f compact; \
	done;

lint-examples:
	@echo "--> Running tflint on examples"
	@find . -type d -path '*/examples/*' -not -path '*.terraform*' 2>/dev/null | while read -r dir; do \
		echo "--> Linting $$dir"; \
		tflint --chdir=$$dir --init; \
		tflint --chdir=$$dir -f compact; \
	done;

format:
	@echo "--> Running terraform fmt"
	@terraform fmt -recursive -write=true

clean:
	@echo "--> Cleaning up"
	@find . -type d -name ".terraform" 2>/dev/null | while read -r dir; do \
		echo "--> Removing $$dir"; \
		rm -rf $$dir; \
	done
