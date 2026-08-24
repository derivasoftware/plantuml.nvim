-- Filetype detection must exist before the plugin loads (the plugin
-- itself is usually lazy-loaded BY this very filetype).
vim.filetype.add({
  extension = {
    puml = "plantuml",
    plantuml = "plantuml",
    iuml = "plantuml",
    wsd = "plantuml",
  },
})
