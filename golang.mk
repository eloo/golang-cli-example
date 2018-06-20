# Golang Makefile
# Please do not alter this alter this directly
GOLANG_MK_VERSION := 0.1.7

GO ?= go

GOFILES := $(shell find . -name "*.go" -type f ! -path "./vendor/*")
GOFMT ?= gofmt -s

GOFLAGS := -i -v
EXTRA_GOFLAGS ?=

# Defaults for build release artifacts
# Can be modified by setting it before loading this file
ifndef GOLANG_RELEASE_OS
  GOLANG_RELEASE_OS=linux windows darwin
endif
ifndef GOLANG_RELEASE_ARCH
  GOLANG_RELEASE_ARCH=386 amd64 arm arm64
endif
ifndef GOLANG_RELEASE_OSARCH
  GOLANG_RELEASE_OSARCH=!darwin/arm !darwin/arm64
endif

LDFLAGS := -X "main.SemVer=${VERSION}" -X "main.GitCommit=$(shell git describe --tags --always | sed 's/-/+/' | sed 's/^v//')" -X "main.Tags=$(TAGS)"

PACKAGES ?= $($(shell $(GO) list ./... | grep -v /vendor/))

.PHONY: golang-clean
golang-clean: ## Cleanup go files
	$(GO) clean -i ./...
	rm -rf $(EXECUTABLE) $(DIST) $(BUILD_DIR)

.PHONY: golang-dep
golang-dep: ## Run dep ensure
	@hash dep > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/golang/dep/cmd/dep; \
	fi
	@dep ensure

.PHONY: golang-dep-update
golang-dep-update: ## Update dependencies using dep
	@hash dep > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/golang/dep/cmd/dep; \
	fi
	@dep ensure --update

.PHONY: golang-fmt
golang-fmt: ## Format go code
	$(GOFMT) -w $(GOFILES)

.PHONY: golang-vet
golang-vet: ## Vet the go files
	$(GO) vet $(PACKAGES)

.PHONY: golang-errcheck
golang-errcheck: ## Run errcheck
	@hash errcheck > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/kisielk/errcheck; \
	fi
	errcheck $(PACKAGES)

.PHONY: golang-lint
golang-lint: ## Lint go files
	@hash golint > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/golang/lint/golint; \
	fi
	for PKG in $(PACKAGES); do golint -set_exit_status $$PKG || exit 1; done;

.PHONY: golang-misspell-check
golang-misspell-check: ## Run misspell
	@hash misspell > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/client9/misspell/cmd/misspell; \
	fi
	misspell -error -i unknwon $(GOFILES)

.PHONY: golang-misspell
golang-misspell: ## Run misspell without breaking the build
	@hash misspell > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/client9/misspell/cmd/misspell; \
	fi
	misspell -w -i unknwon $(GOFILES)

.PHONY: golang-fmt-check
golang-fmt-check: ## Format go and fail if not formatted
	# get all go files and run go fmt on them
	@diff=$$($(GOFMT) -d $(GOFILES)); \
	if [ -n "$$diff" ]; then \
		echo "Please run 'make fmt' and commit the result:"; \
		echo "$${diff}"; \
		exit 1; \
	fi;

.PHONY: golang-test
golang-test: ## Test go files
	$(GO) test $(PACKAGES)

.PHONY: golang-coverage
golang-coverage: ## Run code coverage
	@hash gocovmerge > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/wadey/gocovmerge; \
	fi
	gocovmerge integration.coverage.out $(shell find . -type f -name "coverage.out") > coverage.all;\

.PHONY: golang-install
golang-install: $(wildcard *.go) ## Run go install
	$(GO) install -v -tags '$(TAGS)' -ldflags '-s -w $(LDFLAGS)'

.PHONY: golang-build
golang-build: ## Build the binary
	$(GO) build $(GOFLAGS) $(EXTRA_GOFLAGS) -tags '$(TAGS)' -ldflags '-s -w $(LDFLAGS) -X main.SemVer=${VERSION}-snapshot' -o "$(BUILD_DIR)/$(EXECUTABLE)"

.PHONY: golang-name
golang-release-name: ## Print predicated binary release name
	@echo "$(EXECUTABLE)-$(VERSION)"

.PHONY: golang-release
golang-release: golang-release-build golang-release-check ## Trigger release-build and release-check

.PHONY: golang-release-build
golang-release-build: ## Build release binaries
	@hash gox > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/mitchellh/gox; \
	fi
	gox -os "${GOLANG_RELEASE_OS}" -arch="${GOLANG_RELEASE_ARCH}" -osarch="${GOLANG_RELEASE_OSARCH}" -ldflags '$(LDFLAGS)' -output "$(DIST)/$(EXECUTABLE)-$(VERSION)_{{.OS}}_{{.Arch}}"

.PHONY: golang-release-check
golang-release-check: ## Create sha256 sums
	@cd $(DIST); $(foreach file,$(filter-out $(wildcard $(DIST)/*.sha256), $(wildcard $(DIST)/*)),sha256sum $(notdir $(file)) > $(notdir $(file)).sha256;)

golang-update-makefile: ## Update the golang.mk
	@wget https://raw.githubusercontent.com/eloo/dev-handbook/master/make/golang.mk -O /tmp/golang.mk 2>/dev/null
	@if ! grep -q $(GOLANG_MK_VERSION) /tmp/golang.mk; then cp /tmp/golang.mk golang.mk && echo "golang.mk updated"; else echo "golang.mk is up-to-date"; fi
