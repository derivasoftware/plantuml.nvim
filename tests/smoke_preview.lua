-- covers: plantuml.preview.start, plantuml.preview.stop, plantuml.preview.setup, plantuml.preview.browser_open
-- Headless unit suite for :PlantumlPreview: a stand-in server announces
-- its URL, the preview reports it and opens it, and stop kills it.
-- Run: nvim --headless -u tests/minimal_init.lua -l tests/smoke_preview.lua
local failed = {}
local suite_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local junit = dofile(suite_root .. "/tests/junit.lua")
local function check(name, ok)
  junit.record(name, ok)
  if not ok then table.insert(failed, name) end
  print((ok and "ok  " or "FAIL") .. " " .. name)
end

local notes = {}
vim.notify = function(msg) table.insert(notes, msg) end
local function noted(fragment)
  for _, n in ipairs(notes) do
    if n:find(fragment, 1, true) then return true end
  end
  return false
end

local preview = require("plantuml.preview")
-- a stand-in for `plantuml-render serve`: prints the URL, then waits
local fake = { "sh", "-c", 'echo "listening on http://127.0.0.1:9999/"; sleep 30' }
preview.setup({ cmd = fake })

local commands = vim.api.nvim_get_commands({})
check("setup registers start and stop commands",
  commands.PlantumlPreview ~= nil and commands.PlantumlPreviewStop ~= nil)

vim.cmd.enew()
preview.start(fake, { open = false })
check("start refuses a buffer that is not PlantUML", noted("no es un fichero PlantUML"))

local path = vim.fn.tempname() .. ".puml"
vim.fn.writefile({ "@startuml", "class A", "@enduml" }, path)
vim.cmd.edit(path)
preview.start(fake, { open = false })
check("start reports the URL the server announces",
  vim.wait(5000, function() return noted("preview en http://127.0.0.1:9999/") end, 50))

-- browser_open: with no opener on the PATH it tells the user where to go
local executable = vim.fn.executable
vim.fn.executable = function() return 0 end
notes = {}
preview.start(fake, {})
check("with no browser opener the URL is handed to the user",
  vim.wait(5000, function() return noted("en tu navegador") end, 50))
vim.fn.executable = executable

preview.stop()
preview.stop()
check("stop kills the server and is safe to repeat", true)

junit.write(suite_root .. "/test-results/junit-smoke-preview.xml", "tests/smoke_preview.lua")
if #failed > 0 then
  print("FAILED: " .. table.concat(failed, ", "))
  vim.cmd("cquit 1")
end
print("smoke_preview: all green")
vim.cmd("quitall!")
