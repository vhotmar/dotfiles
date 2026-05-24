vim.filetype.add { extension = { ooz = "oozavor", ooztest = "ooztest" } }

vim.api.nvim_create_autocmd("FileType", {
  pattern = "oozavor",
  callback = function(args)
    vim.bo[args.buf].commentstring = "; %s"
    pcall(vim.treesitter.start, args.buf, "oozavor")
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "ooztest",
  callback = function(args)
    vim.bo[args.buf].commentstring = "; %s"
    pcall(vim.treesitter.start, args.buf, "ooztest")
  end,
})

return {
  {
    "julienvincent/nvim-paredit",
    ft = { "oozavor", "clojure", "scheme", "lisp", "fennel", "janet" },
    opts = {
      filetypes = { "oozavor", "clojure", "scheme", "lisp", "fennel", "janet" },
    },
  },
}
