# Golang Makefile
# Please do not alter this alter this directly
GOLANG_MK_VERSION := 0.1.0

GO ?= go

GOFILES := $(shell find . -name "*.go" -type f ! -path "./vendor/*")
GOFMT ?= gofmt -s

GOFLAGS := -i -v
EXTRA_GOFLAGS ?=

LDFLAGS := -X "main.Version=$(shell git describe --tags --always | sed 's/-/+/' | sed 's/^v//')" -X "main.Tags=$(TAGS)"

PACKAGES ?= $($(shell $(GO) list ./... | grep -v /vendor/))

.PHONY: all
all: build

.PHONY: clean
clean:
	$(GO) clean -i ./...
	rm -rf $(EXECUTABLE) $(DIST) $(BUILD_DIR)

.PHONY: dep
dep:
	@hash dep > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/golang/dep/cmd/dep; \
	fi
	dep ensure

.PHONY: fmt
fmt:
	$(GOFMT) -w $(GOFILES)

.PHONY: vet
vet:
	$(GO) vet $(PACKAGES)

.PHONY: errcheck
errcheck:
	@hash errcheck > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/kisielk/errcheck; \
	fi
	errcheck $(PACKAGES)

.PHONY: lint
lint:
	@hash golint > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/golang/lint/golint; \
	fi
	for PKG in $(PACKAGES); do golint -set_exit_status $$PKG || exit 1; done;

.PHONY: misspell-check
misspell-check:
	@hash misspell > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/client9/misspell/cmd/misspell; \
	fi
	misspell -error -i unknwon $(GOFILES)

.PHONY: misspell
misspell:
	@hash misspell > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/client9/misspell/cmd/misspell; \
	fi
	misspell -w -i unknwon $(GOFILES)

.PHONY: fmt-check
fmt-check:
	# get all go files and run go fmt on them
	@diff=$$($(GOFMT) -d $(GOFILES)); \
	if [ -n "$$diff" ]; then \
		echo "Please run 'make fmt' and commit the result:"; \
		echo "$${diff}"; \
		exit 1; \
	fi;

.PHONY: test
test:
	$(GO) test $(PACKAGES)

.PHONY: coverage
coverage:
	@hash gocovmerge > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/wadey/gocovmerge; \
	fi
	gocovmerge integration.coverage.out $(shell find . -type f -name "coverage.out") > coverage.all;\

.PHONY: install
install: $(wildcard *.go)
	$(GO) install -v -tags '$(TAGS)' -ldflags '-s -w $(LDFLAGS)'

.PHONY: build
build: 
	$(GO) build $(GOFLAGS) $(EXTRA_GOFLAGS) -tags '$(TAGS)' -ldflags '-s -w $(LDFLAGS)' -o "$(BUILD_DIR)/$(EXECUTABLE)"

.PHONY: name
release-name:
	@echo "$(EXECUTABLE)-$(VERSION)"

.PHONY: release
release: release-build release-check

.PHONY: release-build
release-build:
	@hash gox > /dev/null 2>&1; if [ $$? -ne 0 ]; then \
		$(GO) get -u github.com/mitchellh/gox; \
	fi
	gox -os "linux windows darwin" -arch="386 amd64 arm arm64" -osarch="!darwin/arm !darwin/arm64" -ldflags '$(LDFLAGS)' -output "$(DIST)/$(EXECUTABLE)-$(VERSION)_{{.OS}}_{{.Arch}}" 

.PHONY: release-check
release-check:
	@cd $(DIST); $(foreach file,$(filter-out $(wildcard $(DIST)/*.sha256), $(wildcard $(DIST)/*)),sha256sum $(notdir $(file)) > $(notdir $(file)).sha256;)

# golang-update-makefile downloads latest version of golang.mk
golang-update-makefile:
	@wget https://raw.githubusercontent.com/eloo/dev-handbook/master/make/golang.mk -O /tmp/golang.mk 2>/dev/null
	@if ! grep -q $(GOLANG_MK_VERSION) /tmp/golang.mk; then cp /tmp/golang.mk golang.mk && echo "golang.mk updated"; else echo "golang.mk is up-to-date"; fi