-- Minimal junit writer for the headless suites: every check() records a
-- case, and write() emits the report the folio docs read as evidence.
local M = { cases = {} }

local function esc(s)
  return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub('"', "&quot;"))
end

function M.record(name, ok, detail)
  table.insert(M.cases, { name = name, ok = ok, detail = detail })
end

function M.write(path, classname)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f = assert(io.open(path, "w"))
  f:write('<?xml version="1.0"?>\n<testsuites><testsuite name="' .. esc(classname) .. '">\n')
  for _, c in ipairs(M.cases) do
    f:write('<testcase classname="' .. esc(classname) .. '" name="' .. esc(c.name) .. '">')
    if not c.ok then
      f:write('<failure message="' .. esc(c.detail or "") .. '"/>')
    end
    f:write("</testcase>\n")
  end
  f:write("</testsuite></testsuites>\n")
  f:close()
end

return M
