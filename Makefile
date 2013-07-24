SHELL := /bin/bash
REBAR = ./rebar

all: compile

compile: get_deps
	@$(REBAR) compile

compile_skip:
	@$(REBAR) compile skip_deps=true

clean:
	@$(REBAR) clean

eunit:
	$(REBAR) skip_deps=true eunit

get_deps:
	@echo "Fetching deps as: $(REBAR)"
	@$(REBAR) get-deps

run:
	erl -boot start_sasl -sname meru -s meru -pa ebin -pa deps/*/ebin
