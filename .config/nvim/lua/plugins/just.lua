return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        table.insert(opts.ensure_installed, "just")
      else
        opts.ensure_installed = { "just" }
      end
    end,
  },
}
