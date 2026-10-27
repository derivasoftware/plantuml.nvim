-- covers: plantuml.setup, plantuml.plugin_root
-- Headless unit suite for setup(): the filetype, the autocommands, the
-- preview commands and the language server configuration.
-- Run: nvim --headless -u tests/minimal_init.lua -l tests/smoke_plantuml.lua
local failed = {}
local suite_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local junit = dofile(suite_root .. "/tests/junit.lua")
local function check(name, ok)
  junit.record(name, ok)
  if not ok then table.insert(failed, name) end
  print((ok and "ok  " or "FAIL") .. " " .. name)
end

local plantuml = require("plantuml")
plantuml.setup({ lsp = { enabled = false } })

check("setup maps the plantuml extensions to the filetype",
  vim.filetype.match({ filename = "a.puml" }) == "plantuml"
  and vim.filetype.match({ filename = "a.iuml" }) == "plantuml"
  and vim.filetype.match({ filename = "a.wsd" }) == "plantuml")

local autocmds = vim.api.nvim_get_autocmds({ group = "plantuml_nvim", event = "FileType" })
check("setup registers one FileType autocommand", #autocmds == 1)

local commands = vim.api.nvim_get_commands({})
check("setup registers the preview commands",
  commands.PlantumlPreview ~= nil and commands.PlantumlPreviewStop ~= nil)

check("setup leaves the language server alone when disabled",
  vim.lsp.config == nil or vim.lsp.config.plantuml_lsp == nil
  or vim.lsp.config.plantuml_lsp.cmd == nil)

plantuml.setup({ lsp = { enabled = true, cmd = { "plantuml-lsp-test" } } })
check("setup configures the language server with the given command",
  vim.lsp.config == nil
  or vim.deep_equal(vim.lsp.config.plantuml_lsp.cmd, { "plantuml-lsp-test" }))

-- plugin_root: the FileType callback starts tree-sitter only when the
-- built parser sits under the plugin root
local path = vim.fn.tempname() .. ".puml"
vim.fn.writefile({ "@startuml", "class A", "@enduml" }, path)
vim.cmd.edit(path)
local has_parser = vim.fn.filereadable(suite_root .. "/parser/plantuml.so") == 1
check("the FileType callback starts highlighting only with the plugin's parser",
  (vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()] ~= nil) == has_parser)

junit.write(suite_root .. "/test-results/junit-smoke-plantuml.xml", "tests/smoke_plantuml.lua")
if #failed > 0 then
  print("FAILED: " .. table.concat(failed, ", "))
  vim.cmd("cquit 1")
end
print("smoke_plantuml: all green")
vim.cmd("quitall!")
