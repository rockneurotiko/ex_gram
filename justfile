set shell := ["sh", "-euc"]

[group('general')]
list:
    @just --list

[group('general')]
deps:
    mix deps.get

[group('general')]
compile: deps
    mix compile --warnings-as-errors

[group('test')]
test:
    mix test --warnings-as-errors

[group('lint')]
format *args="":
    mix format {{ args }}

[group('lint')]
credo:
    mix credo

[group('lint')]
dialyzer:
    mix dialyzer

[private]
[parallel]
[group('lint')]
lint-checks: (format "--check-formatted") credo dialyzer

[group('lint')]
lint: compile lint-checks
