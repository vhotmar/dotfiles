vim.filetype.add {
  pattern = {
    [".*.Jenkinsfile"] = "groovy",
  },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "groovy" } },
  },

  {
    "williamboman/mason.nvim",
    opts = { ensure_installed = { "groovy-language-server", "npm-groovy-lint" } },
  },

  {
    "neovim/nvim-lspconfig",
    servers = {
      groovyls = {},
    },
  },

  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local nls = require "null-ls"
      opts.sources = opts.sources or {}
      table.insert(opts.sources, nls.builtins.formatting.npm_groovy_lint)
      table.insert(opts.sources, nls.builtins.diagnostics.npm_groovy_lint)
    end,
  },

  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        groovy = { "npm-groovy-lint" },
      },
    },
    {
      "stevearc/conform.nvim",
      optional = true,
      opts = {
        formatters_by_ft = {
          groovy = { "npm-groovy-lint" },
        },
      },
    },
  },
}
