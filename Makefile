.DEFAULT_GOAL := help

DIST := bin
BUILD_DIR := build

NAME := golang-cli-example
EXECUTABLE := $(NAME)

TAGS ?=

VERSION := $(shell cat VERSION)

include golang.mk

.PHONY: build
build: golang-build ## Wrapper for golang-build

.PHONY: version
version: ## Prints the version
	@echo $(VERSION) 

.PHONY: help 
help: ## Prints usage help for this makefile
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = "(:|: .*?## )"}; {printf "\033[36m%-30s\033[0m %s\n", $$(NF-1), $$(NF)}'

.PHONY: 	
goals: goals ## Prints all available goals 
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = "(:|: .*?## )"}; {printf "%s\n", $$(NF-1)}'
