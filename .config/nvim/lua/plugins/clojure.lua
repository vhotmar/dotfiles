return {
  "HiPhish/rainbow-delimiters.nvim",

  {
    "williamboman/mason.nvim",
    opts = { ensure_installed = { "cljfmt", "clojure-lsp" } },
  },

  {
    "mini.pairs",
    opts = { skip_unbalanced = false },
  },
}
