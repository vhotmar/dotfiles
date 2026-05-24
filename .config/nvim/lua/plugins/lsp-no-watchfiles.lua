return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ["*"] = {
        capabilities = {
          workspace = {
            didChangeWatchedFiles = {
              dynamicRegistration = false,
            },
          },
        },
      },
    },
  },
  init = function()
    local orig = vim.lsp.handlers["client/registerCapability"]
    vim.lsp.handlers["client/registerCapability"] = function(err, result, ctx, config)
      if result and result.registrations then
        result.registrations = vim.tbl_filter(function(reg)
          return reg.method ~= "workspace/didChangeWatchedFiles"
        end, result.registrations)
      end
      return orig(err, result, ctx, config)
    end
  end,
}
