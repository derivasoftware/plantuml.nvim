-- Integration suite: drive Neovim like the user does — real keys, real
-- LSP — and assert what is VISIBLE: hover floats, diagnostics,
-- quickfix, buffers after a rename, the served preview answering.
--
-- Run: nvim --headless -u tests/minimal_init.lua -l tests/integration.lua
-- Needs plantuml-lsp on PATH (or $PLANTUML_LSP_BIN). The preview block
-- runs only when plantuml-render is available.

local failed = {}
local function check(name, ok, detail)
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

-- ── 4. Diagnosticos: los defectos intencionados, por severidad ──────
local lints_buf = open("extra/LINTS_Demo.puml")
local counted = vim.wait(8000, function()
  return #vim.diagnostic.get(lints_buf) >= 4
end, 200)
local sev = { 0, 0, 0, 0 }
for _, d in ipairs(vim.diagnostic.get(lints_buf)) do
  sev[d.severity] = sev[d.severity] + 1
end
check("lints: llegan", counted)
check("lints: 2 errores", sev[vim.diagnostic.severity.ERROR] == 2,
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
  require("plantuml.preview").start({ "plantuml-render" })
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

if #failed > 0 then
  print("FAILED: " .. table.concat(failed, " | "))
  vim.cmd("cquit 1")
end
print("integration: all green")
vim.cmd("quitall!")
