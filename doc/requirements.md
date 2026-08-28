# Requirements & status

## What was asked

The system requirements, with a check for implemented and one per test
suite: the smoke suite is the unit tier and the integration suite (real
keys against the real server) is the system tier. No argos reader
models Lua yet, so the implemented column and the verification test ids
read from that gap; the junit reports are what the last runs executed.

<!-- folio: sreqs --junit test-results/junit-ut.xml --junit_st test-results/junit-st.xml -->
| SREQ | Title | Implemented | UT | ST |
| --- | --- | --- | --- | --- |
| `SREQ-00001-1` | The plugin shall bring the PlantUML toolchain to Neovim | ✓ | ✓ | ~ |
| `SREQ-00002-1` | The plugin shall serve the interactive preview from a local page | ✓ | ✓ | ✓ |
<!-- /folio -->

## Total traceability

<!-- folio: matrix --junit test-results/junit-ut.xml --junit_st test-results/junit-st.xml -->
| SREQ | Requirements | Diagrams | Classes | UT | ST | Verifications |
| --- | --- | --- | --- | --- | --- | --- |
| `SREQ-00001-1` | `REQ-00001-1`<br>`REQ-00002-1` | `CL_Init`<br>`CL_PlantumlNvim`<br>`HLD_PlantumlNvim` | `plantuml`<br>`plantuml.preview` | 8 | 40 | `VER-00001-2`<br>`VER-00002-3` |
| `SREQ-00002-1` | `REQ-00003-1` | `CL_PlantumlNvim`<br>`CL_Preview`<br>`HLD_PlantumlNvim` | `plantuml`<br>`plantuml.preview` | 1 | 2 | `VER-00003-2` |
<!-- /folio -->
