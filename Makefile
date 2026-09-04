IMAGE_NAME ?= schemaforge-runtime
FLYWAY_VERSION ?= 13.4.0
IMAGE_TAG ?= $(FLYWAY_VERSION)
PLATFORM ?= linux/amd64
AWS_REGION ?= ap-southeast-1
ECR_NAMESPACE ?= platform
GIT_SHA := $(shell git rev-parse --short HEAD 2>/dev/null || printf unknown)

.PHONY: test build smoke ecr-login ecr-create ecr-lifecycle push

test:
	./test/test-entrypoint.sh

build:
	docker build \
		--platform $(PLATFORM) \
		--build-arg FLYWAY_VERSION=$(FLYWAY_VERSION) \
		--build-arg VCS_REF=$(GIT_SHA) \
		-t $(IMAGE_NAME):$(IMAGE_TAG) .

smoke:
	docker run --rm --platform $(PLATFORM) --entrypoint /flyway/flyway $(IMAGE_NAME):$(IMAGE_TAG) -v

ecr-login:
	@test -n "$(AWS_ACCOUNT_ID)" || (echo "AWS_ACCOUNT_ID is required" >&2; exit 1)
	aws ecr get-login-password --region $(AWS_REGION) | \
		docker login --username AWS --password-stdin \
		$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com

ecr-create:
	aws ecr describe-repositories \
		--region $(AWS_REGION) \
		--repository-names $(ECR_NAMESPACE)/$(IMAGE_NAME) >/dev/null 2>&1 || \
	aws ecr create-repository \
		--region $(AWS_REGION) \
		--repository-name $(ECR_NAMESPACE)/$(IMAGE_NAME) \
		--image-scanning-configuration scanOnPush=true

ecr-lifecycle:
	aws ecr put-lifecycle-policy \
		--region $(AWS_REGION) \
		--repository-name $(ECR_NAMESPACE)/$(IMAGE_NAME) \
		--lifecycle-policy-text file://ecr/lifecycle-policy.json

push: test build ecr-login ecr-create ecr-lifecycle
	@test -n "$(AWS_ACCOUNT_ID)" || (echo "AWS_ACCOUNT_ID is required" >&2; exit 1)
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) \
		$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_NAMESPACE)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push \
		$(AWS_ACCOUNT_ID).dkr.ecr.$(AWS_REGION).amazonaws.com/$(ECR_NAMESPACE)/$(IMAGE_NAME):$(IMAGE_TAG)
