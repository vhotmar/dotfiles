return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        table.insert(opts.ensure_installed, "norg")
      else
        opts.ensure_installed = { "norg" }
      end
    end,
  },

  -- {
  --   "nvim-neorg/neorg",
  --   ft = "norg",
  --   dependencies = { "luarocks.nvim" },
  --   version = "*",
  --   config = function()
  --     require("neorg").setup {
  --       load = {
  --         ["core.defaults"] = {},
  --         ["core.concealer"] = {},
  --         ["core.completion"] = {
  --           config = { engine = "nvim-cmp" },
  --         },
  --         ["core.integrations.nvim-cmp"] = {},
  --       },
  --     }
  --
  --     -- vim.wo.foldlevel = 99
  --     -- vim.wo.conceallevel = 2
  --   end,
  -- },
}
