--- plantuml.nvim: the deriva/plantuml toolchain in Neovim.
---
--- Self-sufficient: the build step compiles the pinned
--- tree-sitter-plantuml parser and copies its queries into this
--- plugin's runtimepath — no nvim-treesitter required. setup() wires
--- the filetype, native tree-sitter highlighting and folding, and the
--- plantuml-lsp language server through Neovim 0.11's native LSP API.

local M = {}

M.defaults = {
  lsp = {
    enabled = true,
    -- resolved through PATH; point it at a venv binary if you prefer
    cmd = { "plantuml-lsp" },
  },
  folds = true,
  preview = {
    -- plantuml-render >= 0.6 (npm); the serve subcommand backs
    -- :PlantumlPreview
    cmd = { "plantuml-render" },
  },
}

local function plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(source, ":h:h:h")
end

function M.setup(opts)
  opts = vim.tbl_deep_extend("force", M.defaults, opts or {})
  local root = plugin_root()

  vim.filetype.add({
    extension = {
      puml = "plantuml",
      plantuml = "plantuml",
      iuml = "plantuml",
      wsd = "plantuml",
    },
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "plantuml",
    group = vim.api.nvim_create_augroup("plantuml_nvim", { clear = true }),
    callback = function(event)
      if vim.fn.filereadable(root .. "/parser/plantuml.so") == 1 then
        pcall(vim.treesitter.start, event.buf, "plantuml")
        if opts.folds then
          vim.wo.foldmethod = "expr"
          vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo.foldlevel = 99
        end
      end
    end,
  })

  require("plantuml.preview").setup(opts.preview)

  if opts.lsp.enabled and vim.lsp.config ~= nil then
    vim.lsp.config("plantuml_lsp", {
      cmd = opts.lsp.cmd,
      filetypes = { "plantuml" },
      root_markers = { ".git" },
    })
    vim.lsp.enable("plantuml_lsp")

    -- native autocompletion: without a completion plugin, nothing pops
    -- unless we enable the 0.11 built-in with autotrigger (fires on
    -- the server's trigger characters: ':', '>', ' ', '|')
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("plantuml_lsp_completion", {}),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.name == "plantuml_lsp"
            and vim.lsp.completion ~= nil then
          vim.lsp.completion.enable(true, client.id, event.buf,
            { autotrigger = true })
          vim.bo[event.buf].omnifunc = "v:lua.vim.lsp.omnifunc"
          vim.api.nvim_set_option_value("completeopt",
            "menu,menuone,noselect,popup", { buf = event.buf })
        end
      end,
    })
  end
end

return M
