-- Replace the deprecated fwcd kotlin-language-server (stuck on Kotlin 2.1.0,
-- crashes on JDK 25) with the official JetBrains kotlin-lsp.
return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = { enabled = false },
        kotlin_lsp = {},
      },
    },
  },
}
