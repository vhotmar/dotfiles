return {
  { "alaviss/nim.nvim" },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nim_langserver = {
          settings = {
            nim = {
              inlayHints = {
                typeHints = { enable = true },
                exceptionHints = { enable = true, hintStringLeft = "⚡", hintStringRight = "" },
                parameterHints = { enable = true },
              },
            },
          },
        },
      },
    },
  },
}
