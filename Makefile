include golang.mk

DIST := bin
BUILD_DIR := build

NAME := golang-cli-example
EXECUTABLE := $(NAME)


TAGS ?=

GIT_VERSION_TAG ?= $(shell git tag -l --points-at HEAD | grep v )

ifneq ($(DRONE_TAG),)
	VERSION ?= $(subst v,,$(DRONE_TAG))
else
	ifneq ($(GIT_VERSION_TAG),)
		VERSION ?= $(subst v,,$(GIT_VERSION_TAG))
	else
		VERSION ?= $(shell git branch | grep \* | cut -d ' ' -f2)
	endif
endif
