# Architecture

Two Lua modules carry the plugin: init wires filetype, treesitter,
folds and the language server; preview owns the served interactive
preview. The figures below are the repository's actual design, rendered
from its sources on every inject.

<!-- folio: design --assets assets -->
### System view

#### HLD_PlantumlNvim

_hld · `design/hld/HLD_PlantumlNvim.puml`_

- traces to: `SREQ-00001-1` `SREQ-00002-1`

![HLD_PlantumlNvim](assets/HLD_PlantumlNvim.svg)

### Module overview

#### CL_PlantumlNvim

_cl · `design/lld/plantuml/CL_PlantumlNvim.puml`_

- traces to: `REQ-00001-1` `REQ-00002-1` `REQ-00003-1`
- implemented in: `lua/plantuml/init.lua` · `lua/plantuml/preview.lua`
- verified by: `tests/editor.lua` (44) · `tests/wiring.lua` (9)

![CL_PlantumlNvim](assets/CL_PlantumlNvim.svg)

### Class detail

<details>
<summary><code>CL_Init</code> · traces to <code>REQ-00001-1</code> <code>REQ-00002-1</code></summary>
<ul>
<li>source: <code>design/lld/plantuml/CL_Init.puml</code></li>
<li>implemented in: <code>lua/plantuml/init.lua</code></li>
<li>verified by: <code>tests/editor.lua</code> (42), <code>tests/wiring.lua</code> (8)</li>
</ul>
<p><img alt="CL_Init" src="assets/CL_Init.svg"></p>
</details>

<details>
<summary><code>CL_Preview</code> · traces to <code>REQ-00003-1</code></summary>
<ul>
<li>source: <code>design/lld/plantuml/preview/CL_Preview.puml</code></li>
<li>implemented in: <code>lua/plantuml/preview.lua</code></li>
<li>verified by: <code>tests/editor.lua</code> (2), <code>tests/wiring.lua</code> (1)</li>
</ul>
<p><img alt="CL_Preview" src="assets/CL_Preview.svg"></p>
</details>
<!-- /folio -->
