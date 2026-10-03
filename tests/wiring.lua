-- Headless smoke: filetype wiring, parser load, queries, folding.
-- Run: nvim --headless -u tests/minimal_init.lua -l tests/wiring.lua
local failed = {}
local suite_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local junit = dofile(suite_root .. "/tests/junit.lua")
local function check(name, ok)
  junit.record(name, ok)
  if not ok then table.insert(failed, name) end
  print((ok and "ok  " or "FAIL") .. " " .. name)
end

require("plantuml").setup({ lsp = { enabled = false } })

local path = vim.fn.tempname() .. ".puml"
vim.fn.writefile({
  "@startuml",
  "class Widget {",
  "  +draw() : None",
  "}",
  "alt ok",
  "  a -> b",
  "end",
  "@enduml",
}, path)
vim.cmd.edit(path)
local buf = vim.api.nvim_get_current_buf()

check("filetype", vim.bo[buf].filetype == "plantuml")

local ok_parser, parser = pcall(vim.treesitter.get_parser, buf, "plantuml")
check("parser loads", ok_parser and parser ~= nil)
if ok_parser and parser then
  local tree = parser:parse()[1]
  check("parses without errors", not tree:root():has_error())
end

-- Literal names (no loop): static test discovery reads the first
-- argument of each check(...) call, so the case ids must be literals.
local ok_hi, query_hi = pcall(vim.treesitter.query.get, "plantuml", "highlights")
check("query highlights", ok_hi and query_hi ~= nil)
local ok_fold, query_fold = pcall(vim.treesitter.query.get, "plantuml", "folds")
check("query folds", ok_fold and query_fold ~= nil)
local ok_ind, query_ind = pcall(vim.treesitter.query.get, "plantuml", "indents")
check("query indents", ok_ind and query_ind ~= nil)

check("foldexpr wired", vim.wo.foldmethod == "expr")

check("preview commands", vim.fn.exists(":PlantumlPreview") == 2
  and vim.fn.exists(":PlantumlPreviewStop") == 2)

-- las teclas del menú son buffer-local y expr (fuera del pum, fallback)
local has_tab = false
for _, m in ipairs(vim.api.nvim_buf_get_keymap(0, "i")) do
  if m.lhs == "<Tab>" and m.expr == 1 then has_tab = true end
end
check("pum keys mapeadas (con LSP off no)", not has_tab)

junit.write(suite_root .. "/test-results/junit-ut.xml", "tests/wiring.lua")
if #failed > 0 then
  print("FAILED: " .. table.concat(failed, ", "))
  vim.cmd("cquit 1")
end
print("smoke: all green")
vim.cmd("quitall!")
