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
BINARY=alert-webhook
BINARY_UNIX=$(BINARY)_unix

build: ## Build the main 'kmgmt' binary
	$(GOBUILD) -o ${BINARY} main.go

build-linux: ## Build a linux binary
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -o $(BINARY_UNIX) main.go

clean: ## Clean the working dir and it's compiled binary
	if [ -f ${BINARY} ] ; then rm ${BINARY} ; fi

unittest: ## Run unit tests
	$(GOTEST) -short  ./...

test: ## Run test coverage
	$(GOTEST) -v -cover -covermode=atomic ./...

run: ## Compile and run the main program
	$(GORUN) main.go

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