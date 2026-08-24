--- :PlantumlPreview — the interactive preview in the browser, served
--- by `plantuml-render serve` (drag, filters, pan/zoom, reload on
--- save). One server per nvim instance; :PlantumlPreviewStop kills it.

local M = {}

local job = nil
local url = nil

local function browser_open(target)
  local candidates = { "wslview", "xdg-open", "open" }
  for _, cmd in ipairs(candidates) do
    if vim.fn.executable(cmd) == 1 then
      vim.system({ cmd, target }, { detach = true })
      return true
    end
  end
  vim.notify("plantuml: abre " .. target .. " en tu navegador", vim.log.levels.INFO)
  return false
end

function M.start(cmd)
  local file = vim.api.nvim_buf_get_name(0)
  if not file:match("%.puml$") and not file:match("%.plantuml$")
      and not file:match("%.iuml$") and not file:match("%.wsd$") then
    vim.notify("plantuml: el buffer actual no es un fichero PlantUML",
      vim.log.levels.WARN)
    return
  end
  if vim.bo.modified then vim.cmd.write() end
  M.stop()
  local argv = vim.list_extend(vim.deepcopy(cmd), { "serve", file })
  job = vim.system(argv, {
    stdout = function(_, data)
      if data and not url then
        local found = data:match("(http://[%d%.]+:%d+/)")
        if found then
          url = found
          vim.schedule(function()
            vim.notify("plantuml: preview en " .. url, vim.log.levels.INFO)
            browser_open(url)
          end)
        end
      end
    end,
    stderr = function(_, data)
      if data and #data > 0 then
        vim.schedule(function()
          vim.notify("plantuml-render: " .. data, vim.log.levels.ERROR)
        end)
      end
    end,
  })
end

function M.stop()
  if job ~= nil then
    job:kill(15)
    job = nil
    url = nil
  end
end

function M.setup(opts)
  vim.api.nvim_create_user_command("PlantumlPreview", function()
    M.start(opts.cmd)
  end, { desc = "Serve the interactive PlantUML preview in the browser" })
  vim.api.nvim_create_user_command("PlantumlPreviewStop", function()
    M.stop()
  end, { desc = "Stop the PlantUML preview server" })
  vim.api.nvim_create_autocmd("VimLeavePre", { callback = M.stop })
end

return M
