# plantuml.nvim

The [deriva/plantuml](https://gitlab.semantiqa.dev/deriva/plantuml)
toolchain in Neovim: the real tree-sitter grammar (highlight, folds,
indentation), and [plantuml-lsp](https://gitlab.semantiqa.dev/deriva/plantuml/plantuml-lsp)
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
  url = "https://gitlab.semantiqa.dev/deriva/plantuml/plantuml.nvim.git",
  build = "make",
  ft = "plantuml",
  opts = {},
}
```

The language server (`pip install plantuml-lsp`, or a venv binary):

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
- **LSP**: parse diagnostics with exact ranges, semantic lints
  (unknown endpoints, duplicates, broken includes, participants no
  class explains), completion, hover (participants show the card of
  the class they play), references/rename across the workspace,
  `gd` through `!include`/`!includesub`, `vim.lsp.buf.format` via
  plantuml-fmt.

## Development

```bash
make            # clone pinned grammar, build parser/plantuml.so, copy queries
nvim --headless -u tests/minimal_init.lua -l tests/smoke.lua
```

Bumping the grammar = editing `GRAMMAR_TAG` in the Makefile and
rebuilding; queries follow automatically.

## Governance

An [argos](https://gitlab.semantiqa.dev/deriva/argos/argos) NA project —
see `CLAUDE.md`.
