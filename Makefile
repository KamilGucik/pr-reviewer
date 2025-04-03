.PHONY: test lint

test:
	nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedFile tests/pr-reviewer/pr-reviewer_spec.lua"

lint:
	luacheck lua/

doc:
	nvim --headless -c "helptags doc/" -c q

all: test lint doc
