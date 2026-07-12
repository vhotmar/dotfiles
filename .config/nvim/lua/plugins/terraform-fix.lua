-- Workaround: opening certain terraform files (e.g. files with `<<-EOT`
-- heredocs containing `${...}` interpolations) freezes Neovim at 100% CPU.
-- Live `sample` of the stuck nvim --embed server showed a vim.schedule()'d Lua
-- callback spinning forever in vim.str_utfindex/mb_utflen while processing
-- terraform-ls's textDocument/semanticTokens/full response. Disabling semantic
-- tokens for terraform-ls avoids the runaway loop. Diagnostics, completion and
-- formatting are unaffected.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      terraformls = {
        on_attach = function(client)
          client.server_capabilities.semanticTokensProvider = nil
        end,
      },
    },
  },
}
