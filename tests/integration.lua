-- Integration suite: drive Neovim like the user does — real keys, real
-- LSP — and assert what is VISIBLE: hover floats, diagnostics,
-- quickfix, buffers after a rename, the served preview answering.
--
-- Run: nvim --headless -u tests/minimal_init.lua -l tests/integration.lua
-- Needs plantuml-lsp on PATH (or $PLANTUML_LSP_BIN). The preview block
-- runs only when plantuml-render is available.

local failed = {}
local junit = dofile(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h") .. "/junit.lua")
local function check(name, ok, detail)
  junit.record(name, ok, detail)
  if not ok then table.insert(failed, name .. (detail and (" (" .. detail .. ")") or "")) end
  print((ok and "ok  " or "FAIL") .. " " .. name .. (ok and "" or (" :: " .. tostring(detail))))
end

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local fixtures = root .. "/tests/fixtures/cafetera"
local lsp_bin = os.getenv("PLANTUML_LSP_BIN") or "plantuml-lsp"

require("plantuml").setup({ lsp = { cmd = { lsp_bin } } })

-- the fixtures must look like a workspace root for root_markers
vim.fn.mkdir(fixtures .. "/.git", "p")
vim.cmd.cd(fixtures)

local function open(path)
  vim.cmd.edit(fixtures .. "/" .. path)
  local buf = vim.api.nvim_get_current_buf()
  local ok = vim.wait(10000, function()
    return #vim.lsp.get_clients({ bufnr = buf, name = "plantuml_lsp" }) > 0
  end, 100)
  return buf, ok
end

local function float_lines()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      local lines = vim.api.nvim_buf_get_lines(
        vim.api.nvim_win_get_buf(win), 0, -1, false)
      return table.concat(lines, "\n"), win
    end
  end
  return nil, nil
end

local function press_K_at(row, col)
  vim.api.nvim_win_set_cursor(0, { row, col })
  -- feedkeys "x" drains the typeahead synchronously — nvim_input only
  -- queues, and vim.wait never consumes pending keys in script mode
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("K", true, false, true), "x", false)
  local text
  vim.wait(6000, function()
    text = float_lines()
    return text ~= nil
  end, 100)
  -- close the float so the next probe starts clean
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative ~= "" then
      pcall(vim.api.nvim_win_close, win, true)
    end
  end
  return text
end

-- ── 1. Hover: participant shows the class it plays ──────────────────
local seq_buf, attached = open("secuencia/SEQ_PrepararCafe.puml")
check("lsp attaches", attached)
local seq_client = vim.lsp.get_clients({ bufnr = seq_buf, name = "plantuml_lsp" })[1]
local trig = vim.tbl_get(seq_client.server_capabilities,
  "completionProvider", "triggerCharacters") or {}
check("completion: trigger characters declarados",
  vim.tbl_contains(trig, ":") and vim.tbl_contains(trig, ">"),
  vim.inspect(trig))

local hover = press_K_at(7, 15) -- participant Cafetera
check("K participante: ficha del participante", hover and hover:find("participant"), hover)
check("K participante: trae la clase correlacionada",
  hover and hover:find("preparar", 1, true) ~= nil, hover and hover:sub(1, 80))

-- ── 2. Hover cualificado en el agregado (PUML-28) ───────────────────
open("clases/CL_Sistema.puml")
local qualified = press_K_at(16, 10) -- maquina.Cafetera ..|> Calentable
check("K maquina.Cafetera resuelve la clase",
  qualified ~= nil and qualified:find("class", 1, true) ~= nil,
  qualified and qualified:sub(1, 60) or "sin float")

-- ── 3. gd sobre !includesub aterriza en el !startsub ────────────────
open("clases/CL_Sistema.puml")
vim.api.nvim_win_set_cursor(0, { 6, 4 }) -- !includesub ./CL_Cafetera.puml!Cafetera
vim.lsp.buf.definition()
local landed = vim.wait(6000, function()
  return vim.api.nvim_buf_get_name(0):find("CL_Cafetera%.puml") ~= nil
end, 100)
local line = landed and vim.api.nvim_get_current_line() or ""
check("gd includesub: fichero hoja", landed)
check("gd includesub: linea del startsub", line:find("!startsub Cafetera") ~= nil, line)

-- ── 3b. gd sobre ENTIDADES: tipo en un miembro y relacion cualificada
open("clases/CL_Cafetera.puml")
vim.api.nvim_win_set_cursor(0, { 11, 23 }) -- ...pedido: Pedido) : Taza
vim.lsp.buf.definition()
local to_pedido = vim.wait(6000, function()
  return vim.api.nvim_buf_get_name(0):find("CL_Pedido%.puml") ~= nil
end, 100)
check("gd entidad: tipo de parametro -> CL_Pedido", to_pedido,
  vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"))
check("gd entidad: aterriza en la clase",
  to_pedido and vim.api.nvim_get_current_line():find("class Pedido") ~= nil,
  vim.api.nvim_get_current_line())

open("clases/CL_Sistema.puml")
vim.api.nvim_win_set_cursor(0, { 20, 10 }) -- pedidos.Pedido --> ...
vim.lsp.buf.definition()
local to_pedido2 = vim.wait(6000, function()
  return vim.api.nvim_buf_get_name(0):find("CL_Pedido%.puml") ~= nil
end, 100)
check("gd entidad: relacion cualificada -> CL_Pedido", to_pedido2,
  vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"))

-- ── 3c. Nivel de llamada: etiquetas de mensaje ↔ miembros de la clase
open("secuencia/SEQ_PrepararCafe.puml")
vim.api.nvim_win_set_cursor(0, { 19, 26 }) -- Cafetera -> Molinillo : moler(num_granos)
vim.lsp.buf.definition()
local to_moler = vim.wait(6000, function()
  return vim.api.nvim_buf_get_name(0):find("CL_Molinillo%.puml") ~= nil
end, 100)
check("gd llamada: moler -> CL_Molinillo", to_moler,
  vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"))
check("gd llamada: aterriza en el miembro",
  to_moler and vim.api.nvim_get_current_line():find("moler%(gramos") ~= nil,
  vim.api.nvim_get_current_line())

open("secuencia/SEQ_PrepararCafe.puml")
local call_hover = press_K_at(19, 26)
check("K llamada: firma declarada",
  call_hover ~= nil and call_hover:find("gramos: int", 1, true) ~= nil,
  call_hover and call_hover:sub(1, 60) or "sin float")

local deriva_buf = open("secuencia/SEQ_Deriva.puml")
local call_drift = vim.wait(8000, function()
  for _, d in ipairs(vim.diagnostic.get(deriva_buf)) do
    if d.message:find("afilar") then return true end
  end
  return false
end, 200)
check("lint llamada: afilar no declarado avisa", call_drift)
local moler_quiet = true
for _, d in ipairs(vim.diagnostic.get(deriva_buf)) do
  if d.message:find("moler") then moler_quiet = false end
end
check("lint llamada: moler declarado calla", moler_quiet)

-- error() hacia un actor: ninguna clase del workspace lo declara ->
-- Information visible sobre la etiqueta
local tour_buf = open("secuencia/SEQ_PrepararCafe.puml")
local unknown_call = vim.wait(8000, function()
  for _, d in ipairs(vim.diagnostic.get(tour_buf)) do
    if d.message:find("error", 1, true)
        and d.severity == vim.diagnostic.severity.INFO then
      return true
    end
  end
  return false
end, 200)
check("lint llamada: error() sin declaracion global (Information)", unknown_call)

-- ── 3d. Actividad enlazada: acciones → métodos, carriles → clases
local act_buf = open("actividad/ACT_CicloLimpieza.puml")
-- gd sobre :calentar(objetivo); bajo el carril |Cafetera|
vim.api.nvim_win_set_cursor(0, { 13, 5 })
vim.lsp.buf.definition()
local to_calentar = vim.wait(6000, function()
  return vim.api.nvim_buf_get_name(0):find("CL_Cafetera%.puml") ~= nil
end, 100)
check("gd accion: calentar -> CL_Cafetera", to_calentar,
  vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":t"))
check("gd accion: aterriza en el miembro",
  to_calentar and vim.api.nvim_get_current_line():find("calentar%(objetivo") ~= nil,
  vim.api.nvim_get_current_line())

open("actividad/ACT_CicloLimpieza.puml")
local act_hover = press_K_at(13, 5)
check("K accion: firma declarada",
  act_hover ~= nil and act_hover:find("objetivo: float", 1, true) ~= nil,
  act_hover and act_hover:sub(1, 60) or "sin float")

-- carril |Cafetera| correlaciona con la clase
open("actividad/ACT_CicloLimpieza.puml")
local lane_hover = press_K_at(11, 2)
check("K carril: ficha de la clase",
  lane_hover ~= nil and lane_hover:find("preparar", 1, true) ~= nil,
  lane_hover and lane_hover:sub(1, 60) or "sin float")

-- deriva: afilar(disco) bajo |Molinillo| que no lo declara
local act_drift = vim.wait(8000, function()
  for _, d in ipairs(vim.diagnostic.get(act_buf)) do
    if d.message:find("afilar") then return true end
  end
  return false
end, 200)
check("lint accion: afilar bajo Molinillo avisa", act_drift)

-- references del metodo moler: declaracion + SEQ + ACT
open("clases/CL_Molinillo.puml")
vim.api.nvim_win_set_cursor(0, { 8, 6 }) -- +moler(gramos: int)
vim.fn.setqflist({})
vim.lsp.buf.references()
vim.wait(6000, function() return #vim.fn.getqflist() > 1 end, 100)
local ref_files = {}
for _, item in ipairs(vim.fn.getqflist()) do
  ref_files[vim.fn.fnamemodify(vim.fn.bufname(item.bufnr), ":t")] = true
end
check("references metodo: incluye la secuencia",
  ref_files["SEQ_PrepararCafe.puml"] == true, vim.inspect(ref_files))
check("references metodo: incluye la actividad",
  ref_files["ACT_CicloLimpieza.puml"] == true, vim.inspect(ref_files))

-- ── 3e. Completion contextual (peticion LSP real; el menu flotante
-- de completion no es fiable en headless, el contrato del servidor si)
local function complete_at(row, col)
  local buf = vim.api.nvim_get_current_buf()
  local client = vim.lsp.get_clients({ bufnr = buf, name = "plantuml_lsp" })[1]
  local done, result = false, nil
  client:request("textDocument/completion", {
    textDocument = { uri = vim.uri_from_bufnr(buf) },
    position = { line = row, character = col },
  }, function(_, res) done, result = true, res end)
  vim.wait(5000, function() return done end, 100)
  local out = {}
  for _, item in ipairs(result or {}) do out[item.label] = item.detail end
  return out
end

open("secuencia/SEQ_PrepararCafe.puml")
-- linea 19 (0-based 18): "  Cafetera -> Molinillo : moler(num_granos)"
local after_colon = complete_at(18, 26)
check("completion tras ':': metodos del receptor",
  after_colon["moler"] ~= nil and after_colon["ajustar"] ~= nil,
  vim.inspect(vim.tbl_keys(after_colon)))
check("completion tras ':': la firma como detalle",
  after_colon["moler"] and after_colon["moler"]:find("gramos: int") ~= nil,
  after_colon["moler"])
check("completion tras ':': sin keywords",
  after_colon["note"] == nil and after_colon["class"] == nil)

local after_arrow = complete_at(18, 14) -- tras '-> '
check("completion tras flecha: participantes sin keywords",
  after_arrow["Molinillo"] ~= nil and after_arrow["note"] == nil,
  vim.inspect(vim.tbl_keys(after_arrow)))

-- ── 4. Diagnosticos: los defectos intencionados, por severidad ──────
local lints_buf = open("extra/LINTS_Demo.puml")
local counted = vim.wait(8000, function()
  return #vim.diagnostic.get(lints_buf) >= 5
end, 200)
local sev = { 0, 0, 0, 0 }
for _, d in ipairs(vim.diagnostic.get(lints_buf)) do
  sev[d.severity] = sev[d.severity] + 1
end
check("lints: llegan", counted)
check("lints: 3 errores", sev[vim.diagnostic.severity.ERROR] == 3,
  "errores=" .. sev[vim.diagnostic.severity.ERROR])
check("lints: 2 warnings", sev[vim.diagnostic.severity.WARN] == 2,
  "warnings=" .. sev[vim.diagnostic.severity.WARN])

local drift = vim.wait(8000, function()
  for _, d in ipairs(vim.diagnostic.get(seq_buf)) do
    if d.message:find("Duende") then return true end
  end
  return false
end, 200)
check("lints: deriva de Duende en el SEQ", drift)

-- ── 4b. Code actions: quick fixes sobre los lints
local function actions_at(buf, row)
  local client = vim.lsp.get_clients({ bufnr = buf, name = "plantuml_lsp" })[1]
  local diags = {}
  for _, d in ipairs(vim.diagnostic.get(buf, { lnum = row })) do
    table.insert(diags, {
      range = { start = { line = d.lnum, character = d.col },
                ["end"] = { line = d.end_lnum or d.lnum, character = d.end_col or d.col } },
      message = d.message, severity = d.severity,
    })
  end
  local done, result = false, nil
  client:request("textDocument/codeAction", {
    textDocument = { uri = vim.uri_from_bufnr(buf) },
    range = { start = { line = row, character = 0 },
              ["end"] = { line = row, character = 200 } },
    context = { diagnostics = diags },
  }, function(_, res) done, result = true, res end)
  vim.wait(5000, function() return done end, 100)
  return result or {}
end
local function apply_action(actions, pattern)
  for _, action in ipairs(actions) do
    if action.title:find(pattern) then
      vim.lsp.util.apply_workspace_edit(action.edit, "utf-16")
      return action.title
    end
  end
  return nil
end

-- crear declaracion para Fantasma (linea 8, 0-based 7)
local lint_acts = actions_at(lints_buf, 7)
local created = apply_action(lint_acts, "Fantasma")
check("action: crear declaracion de Fantasma", created ~= nil,
  vim.inspect(vim.tbl_map(function(a) return a.title end, lint_acts)))
local lints_text = table.concat(
  vim.api.nvim_buf_get_lines(lints_buf, 0, -1, false), "\n")
check("action: class Fantasma insertada",
  lints_text:find("class Fantasma") ~= nil)

-- corregir la ruta con typo (CL_Cafetera.pml, linea 17 0-based 16)
local fix_acts = actions_at(lints_buf, 16)
local fixed = apply_action(fix_acts, "CL_Cafetera%.puml")
check("action: corregir ruta del include", fixed ~= nil,
  vim.inspect(vim.tbl_map(function(a) return a.title end, fix_acts)))

-- declarar afilar() en Molinillo desde la deriva del SEQ
local deriva_buf2 = open("secuencia/SEQ_Deriva.puml")
vim.wait(6000, function() return #vim.diagnostic.get(deriva_buf2) > 0 end, 200)
local drift_row
for _, d in ipairs(vim.diagnostic.get(deriva_buf2)) do
  if d.message:find("afilar") then drift_row = d.lnum end
end
local drift_acts = actions_at(deriva_buf2, drift_row or 0)
local declared = apply_action(drift_acts, "afilar")
check("action: declarar afilar en Molinillo", declared ~= nil,
  vim.inspect(vim.tbl_map(function(a) return a.title end, drift_acts)))
local mol_buf = vim.fn.bufnr("CL_Molinillo.puml", false)
local mol_text = mol_buf > 0 and table.concat(
  vim.api.nvim_buf_get_lines(mol_buf, 0, -1, false), "\n") or ""
check("action: miembro afilar en el CL",
  mol_text:find("afilar%(") ~= nil, mol_text:sub(1, 120))

-- ── 5. References de Cafetera cruzan ficheros ───────────────────────
open("clases/CL_Cafetera.puml")
vim.api.nvim_win_set_cursor(0, { 7, 10 }) -- class Cafetera
vim.fn.setqflist({})
vim.lsp.buf.references()
vim.wait(6000, function() return #vim.fn.getqflist() > 0 end, 100)
local qf_files = {}
for _, item in ipairs(vim.fn.getqflist()) do
  qf_files[vim.fn.fnamemodify(vim.fn.bufname(item.bufnr), ":t")] = true
end
check("references: hoja y secuencia", qf_files["CL_Cafetera.puml"] and
  qf_files["SEQ_PrepararCafe.puml"], vim.inspect(qf_files))
check("references: agregado cualificado (PUML-28)",
  qf_files["CL_Sistema.puml"] == true, vim.inspect(qf_files))

-- ── 6. Rename aplicado sobre buffers reales ─────────────────────────
open("clases/CL_Molinillo.puml")
vim.api.nvim_win_set_cursor(0, { 6, 10 }) -- class Molinillo
vim.lsp.buf.rename("Triturador")
local renamed = vim.wait(6000, function()
  local text = table.concat(
    vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  return text:find("Triturador") ~= nil
end, 100)
check("rename: hoja renombrada", renamed)
local seq_text = table.concat(
  vim.api.nvim_buf_get_lines(seq_buf, 0, -1, false), "\n")
check("rename: secuencia renombrada", seq_text:find("Triturador") ~= nil)

-- ── 7. Preview servido (si plantuml-render esta) ────────────────────
if vim.fn.executable("plantuml-render") == 1 then
  open("clases/CL_Sistema.puml")
  local notified
  vim.notify = function(msg) notified = notified or msg end
  -- open=false: la suite valida por curl, nunca abre tu navegador
  require("plantuml.preview").start({ "plantuml-render" }, { open = false })
  vim.wait(10000, function()
    return notified ~= nil and notified:find("http") ~= nil
  end, 200)
  local url = notified and notified:match("(http://[%d%.]+:%d+/)")
  check("preview: servidor anuncia URL", url ~= nil, tostring(notified))
  if url then
    local page = vim.system({ "curl", "-sf", url }, { text = true }):wait()
    check("preview: la pagina responde", page.code == 0 and
      page.stdout:find("f%-members") ~= nil)
  end
  require("plantuml.preview").stop()
else
  print("skip preview (plantuml-render no disponible)")
end

junit.write(root .. "/test-results/junit-st.xml", "tests/integration.lua")
if #failed > 0 then
  print("FAILED: " .. table.concat(failed, " | "))
  vim.cmd("cquit 1")
end
print("integration: all green")
vim.cmd("quitall!")
