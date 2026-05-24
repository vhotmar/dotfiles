vim.filetype.add {
  extension = { asd = "lisp", cl = "lisp", lsp = "lisp" },
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "commonlisp" } },
  },

  { "eraserhd/parinfer-rust", build = "cargo build --release" },

  -- {
  --   "vlime/vlime",
  --   lazy = false,
  --   config = function(p)
  --     vim.opt.rtp:prepend(p.dir .. "/vim")
  --     vim.cmd "runtime! plugin/*.vim"
  --   end,
  -- },

  { "julienvincent/nvim-paredit", opts = {}, event = "LazyFile" },
}
