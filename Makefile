.PHONY: docs

docs:
	cd docs; \
	julia --compile=min -O0 --project=.. make.jl

