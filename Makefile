AWS_PROFILE=SOME_PROFILE
BINARY_NAME = main
GO_FILE_NAME = main.go
IMAGE_TAG = test-go-lambda:latest
ECR_REPO = REDACTED.dkr.ecr.us-west-2.amazonaws.com
FUNCTION_NAME = test-go-lambda
TEST_EVENT_FILE = sqs-event.json
OUTPUT_FILE = output.json

build:
	@echo "Building Go binary..."
	GOOS=linux GOARCH=amd64 go build -o $(BINARY_NAME) $(GO_FILE_NAME)

docker:
	@echo "Building Docker image..."
	docker buildx build --platform linux/amd64 -t $(ECR_REPO)/$(IMAGE_TAG) . --load

ecr-login:
	@echo "Logging into ECR..."
	aws --profile $(AWS_PROFILE) ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin $(ECR_REPO)

push: docker
	@echo "Pushing Docker image..."
	docker push $(ECR_REPO)/$(IMAGE_TAG)

update: push
	aws --profile $(AWS_PROFILE) lambda update-function-code --function-name $(FUNCTION_NAME) --image-uri $(ECR_REPO)/$(IMAGE_TAG)

b64event:
	@echo "Base64 encoding test event..."
	cat $(TEST_EVENT_FILE) | base64 > $(TEST_EVENT_FILE).b64

test:
	docker run --platform linux/amd64 -p 9000:8080 --rm -it $(ECR_REPO)/$(IMAGE_TAG)

invoke:
	@echo "Invoking Lambda function..."
	aws lambda invoke --profile $(AWS_PROFILE) --function-name $(FUNCTION_NAME) --payload file://sqs-event.json.b64 $(OUTPUT_FILE)
	@echo "Lambda function output:"
	@cat $(OUTPUT_FILE)
	@rm -f $(OUTPUT_FILE)

clean:
	@echo "Cleaning up..."
	rm -f $(BINARY_NAME)
