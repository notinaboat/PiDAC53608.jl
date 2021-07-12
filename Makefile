PACKAGE := $(shell basename $(PWD))
export JULIA_DEPOT_PATH = $(CURDIR)/../jl_depot

all: README.md

JL := julia --project

jl:
	sudo -E $(JL) -i -e "using $(PACKAGE)"

jlenv:
	$(JL)

README.md: src/$(PACKAGE).jl
	$(JL) -e "using $(PACKAGE); \
		      println($(PACKAGE).readme())" > $@
