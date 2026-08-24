-- Headless smoke: filetype wiring, parser load, queries, folding.
-- Run: nvim --headless -u tests/minimal_init.lua -l tests/smoke.lua
local failed = {}
local function check(name, ok)
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

for _, q in ipairs({ "highlights", "folds", "indents" }) do
  local ok_q, query = pcall(vim.treesitter.query.get, "plantuml", q)
  check("query " .. q, ok_q and query ~= nil)
end

check("foldexpr wired", vim.wo.foldmethod == "expr")

if #failed > 0 then
  print("FAILED: " .. table.concat(failed, ", "))
  vim.cmd("cquit 1")
end
print("smoke: all green")
vim.cmd("quitall!")
