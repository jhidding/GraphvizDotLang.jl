.PHONY: docs examples all

example_scripts := $(wildcard examples/*.jl)
example_output := $(example_scripts:%.jl=%.svg)

examples: $(example_output) 

examples/%.svg: examples/%.jl
	julia --project=. --compile=min -O0 $< $@

docs:
	cd docs; \
	julia --compile=min -O0 --project=.. make.jl

all: examples docs

