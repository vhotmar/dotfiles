return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "templ" } },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        table.insert(opts.ensure_installed, "templ")
      else
        opts.ensure_installed = { "templ" }
      end
    end,
  },
}
