local ts_servers = { vtsls = true, ts_ls = true, tsserver = true, ["typescript-tools"] = true }

return {
  "neovim/nvim-lspconfig",
  init = function()
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        if not vim.b[args.buf].deno_shebang then return end
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and ts_servers[client.name] then
          vim.lsp.buf_detach_client(args.buf, args.data.client_id)
        end
      end,
    })
  end,
  opts = {
    servers = {
      denols = {
        enabled = true,
      },
    },
  },
}
