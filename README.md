# plantuml.nvim

<!-- folio: colophon --project plantuml.nvim --junit test-results/junit-ut.xml --junit_st test-results/junit-st.xml -->
![powered by: argos](https://img.shields.io/badge/powered%20by-argos-1f6feb) ![traced: 100%](https://img.shields.io/badge/traced-100%25-2ea44f) ![verified: 100%](https://img.shields.io/badge/verified-100%25-2ea44f) ![tests: 100%](https://img.shields.io/badge/tests-100%25-2ea44f) ![UT: n/a](https://img.shields.io/badge/UT-n%2Fa-lightgrey) ![ST: n/a](https://img.shields.io/badge/ST-n%2Fa-lightgrey) ![diagnostics: 0](https://img.shields.io/badge/diagnostics-0-2ea44f)

> **plantuml.nvim** is powered by **argos**. **folio** generates this documentation from the repository's model: 3 requirements · 3 verifications · 0 constraints. Quality: 100% traced to code · 100% verified · 100% tests passing.
<!-- /folio -->

The [deriva/plantuml](https://github.com/derivasoftware)
toolchain in Neovim: the real tree-sitter grammar (highlight, folds,
indentation), and [plantuml-lsp](https://github.com/derivasoftware/plantuml-lsp)
— diagnostics and semantic lints, completion, hover with
class↔sequence correlation, workspace-wide references and rename,
go-to-definition across `!includesub`, formatting via plantuml-fmt.

Self-sufficient: the build step compiles the **pinned** grammar and
copies its queries — no nvim-treesitter dependency, no drift between
parser and queries.

## Install

lazy.nvim:

```lua
{
  "deriva/plantuml.nvim",
  url = "https://github.com/derivasoftware/plantuml.nvim.git",
  build = "make",
  ft = "plantuml",
  opts = {},
}
```

The language server (straight from git, or point `cmd` at a venv binary):

```bash
pip install git+https://github.com/derivasoftware/plantuml-lsp.git@v0.8.1
```

```lua
opts = { lsp = { cmd = { "/path/to/venv/bin/plantuml-lsp" } } }
```

Requires Neovim ≥ 0.11 (native `vim.lsp.config`) and a C compiler for
the build step.

## What you get

- **Highlighting** from the grammar itself — the same node vocabulary
  every tool of the family consumes, raw-frontier included.
- **Folding** (`zc`/`zo`) on bodies, packages/namespaces, frames and
  notes; **indentation** mirroring the plantuml-fmt canonical style.
- **Interactive preview** — `:PlantumlPreview` serves the diagram in
  your browser via `plantuml-render serve`: drag entities and
  namespaces, filter members/namespaces/notes, pan and zoom, reload on
  save. `:PlantumlPreviewStop` kills the server. Requires
  `plantuml-render` ≥ 0.6 on PATH (npm).
- **LSP**: parse diagnostics with exact ranges, semantic lints
  (unknown endpoints, duplicates, broken includes, participants no
  class explains), completion, hover (participants show the card of
  the class they play), references/rename across the workspace,
  `gd` through `!include`/`!includesub`, `vim.lsp.buf.format` via
  plantuml-fmt.

## Development

```bash
make            # clone pinned grammar, build parser/plantuml.so, copy queries
nvim --headless -u tests/minimal_init.lua -l tests/wiring.lua        # UT
nvim --headless -u tests/minimal_init.lua -l tests/editor.lua  # ST: real keys, real server
```

Both suites write junit reports under `test-results/`; the docs read
them as evidence.

Bumping the grammar = editing `GRAMMAR_TAG` in the Makefile and
rebuilding; queries follow automatically.

## Scope

The family covers a standard-driven subset of PlantUML, never the whole
language. Class diagrams: 125 of 149 standard constructs structural;
sequence: 70 of 111, with the lifecycle verbs (activate, ref, box,
delays) still raw; activity: actions and swimlanes structural, control
flow raw. Everything else (deployment, components, state, mindmaps,
gantt) parses lossless as raw lines, never an ERROR, but gets no
structure. Highlighting and folding cover every diagram through
the raw tier; intelligence and preview follow the subsets above.

## Documentation

- [Architecture](doc/architecture.md): the model's diagrams, rendered from source
- [Requirements & status](doc/requirements.md): what was asked and the traceability matrix
- [Repo quality](doc/quality.md): artefact inventory and health metrics

*Not affiliated with or endorsed by the PlantUML project.*
