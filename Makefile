.DEFAULT_GOAL := help

# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GORUN=$(GOCMD) run
GOLIST=$(GOCMD) list
GOTEST=$(GOCMD) test
GOGET=$(GOCMD) get
GOMOD=$(GOCMD) mod

# Binary names
MAIN_BINARY=alert-webhook
TOKEN_BINARY=${MAIN_BINARY}-token
MAIN_BINARY_UNIX=$(MAIN_BINARY)-linux-amd64
TOKEN_BINARY_UNIX=$(TOKEN_BINARY)-linux-amd64

build-token:
	$(GOBUILD) -o ${TOKEN_BINARY} cmd/token/main.go

build: build-token
	$(GOBUILD) -o ${MAIN_BINARY} cmd/webhook/main.go

build-linux: ## Build a linux binary
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -o $(MAIN_BINARY_UNIX) cmd/webhook/main.go
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -o ${TOKEN_BINARY_UNIX} cmd/token/main.go

clean: ## Clean the working dir and it's compiled binary
	if [ -f ${MAIN_BINARY} ] ; then rm ${MAIN_BINARY} ; fi
	if [ -f ${TOKEN_BINARY} ] ; then rm ${TOKEN_BINARY} ; fi
	if [ -f ${MAIN_BINARY_UNIX} ] ; then rm ${MAIN_BINARY_UNIX} ; fi
	if [ -f ${TOKEN_BINARY_UNIX} ] ; then rm ${TOKEN_BINARY_UNIX} ; fi

unittest: ## Run unit tests
	$(GOTEST) -short  ./...

test: ## Run test coverage
	$(GOTEST) -v -cover -covermode=atomic ./...

run: ## Compile and run the main program
	$(GORUN) cmd/webhook/main.go

list: ## Print the current module's dependencies.
	$(GOLIST) -m all

lint-prepare: ## Install the golangci linter
	@echo "Installing golangci-lint" 
	curl -sfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh| sh -s latest

lint: ## Run the golangci linter on source code
	./bin/golangci-lint run \
		--exclude-use-default=false \
		--enable=golint \
		--enable=gocyclo \
		--enable=goconst \
		--enable=unconvert \
		./...

tidy: ## Remove unused dependencies
	$(GOMOD) tidy

help: ## Print help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build build-linux clean unittest test run list lint-prepare lint tidy help