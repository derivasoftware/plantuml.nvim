# plantuml.nvim

Argos NA project (agents may act as Owner): input SREQs in `input/`,
requirements and verifications in `requirements/` and `verifications/`.
Branch mode by default; merge on green.

Lua plugin, no venv. Verify with:

```bash
make
nvim --headless -u tests/minimal_init.lua -l tests/wiring.lua
nvim --headless -u tests/minimal_init.lua -l tests/smoke_plantuml.lua
nvim --headless -u tests/minimal_init.lua -l tests/smoke_preview.lua
```

The grammar pin lives in the Makefile (`GRAMMAR_TAG`); queries are
copied from the same clone — never edit `queries/plantuml/` by hand.
