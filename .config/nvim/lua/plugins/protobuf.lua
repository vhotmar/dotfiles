return {
  {
    "williamboman/mason.nvim",
    opts = { ensure_installed = { "buf" } },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
        },
      },
    },
  },
}
