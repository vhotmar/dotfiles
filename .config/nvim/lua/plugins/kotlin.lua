-- Replace the deprecated fwcd kotlin-language-server (stuck on Kotlin 2.1.0,
-- crashes on JDK 25) with the official JetBrains kotlin-lsp.
return {
  {
    -- Upstream mason-registry ships a malformed `{{{` interpolation in kotlin-lsp's
    -- linux_arm64 `bin`, which aborts the install on aarch64. Local registry is
    -- listed first so its corrected copy wins.
    "mason-org/mason.nvim",
    opts = {
      registries = {
        "file:~/.config/nvim/mason-registry",
        "github:mason-org/mason-registry",
      },
      -- kotlin.nvim resolves the server from $MASON, and disabling the lspconfig
      -- entry below drops it from LazyVim's mason ensure_installed list.
      ensure_installed = { "kotlin-lsp" },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = { enabled = false },
        -- kotlin.nvim owns the kotlin_lsp client entirely. `enabled = false` both
        -- stops LazyVim calling vim.lsp.enable() and adds kotlin_lsp to the
        -- mason-lspconfig `automatic_enable` exclude list; either one starting a
        -- client from nvim-lspconfig's default config would win the race and
        -- leave it without kotlin.nvim's workspace/configuration handler.
        kotlin_lsp = { enabled = false },
      },
    },
  },
  {
    -- Handles `jar://` and `jrt://` definition targets via the server's own
    -- `decompile` command, plus inlay hints, LSP folding and organize-imports.
    "AlexandrosAlexiou/kotlin.nvim",
    ft = { "kotlin" },
    dependencies = { "mason.nvim", "mason-lspconfig.nvim", "trouble.nvim" },
    opts = {},
  },
}
