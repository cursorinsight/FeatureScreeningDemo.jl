###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

##------------------------------------------------------------------------------
## Variables and functions
##------------------------------------------------------------------------------

# Common directories and paths
TOP_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
ABS_DIR := $(abspath $(TOP_DIR))

# Julia
JULIA := $(shell which julia)

ifeq "$$(strip $(JULIA))" ""
JULIA := julia
endif

##------------------------------------------------------------------------------
## Targets
##------------------------------------------------------------------------------

.PHONY: default
default: help #: Show help

.PHONY: help
help: #: Show help topics
	@grep "#:" Makefile* | grep -v "@grep" | sort | \
		sed "s/\([A-Za-z_ -]*\):.*#\(.*\)/$$(tput setaf 3)\1$$(tput sgr0)\2/g"

.PHONY: test
test: $(JULIA) #: Run all unit tests
	@$(JULIA) --project --depwarn=no -e 'using Pkg: test; test()'

.PHONY: console shell
console: shell
shell: $(JULIA) #: Start Julia shell
	@$(JULIA) --project --startup-file=no

$(JULIA):
	@echo Please install \`$$@\' manually!
	@exit 1
