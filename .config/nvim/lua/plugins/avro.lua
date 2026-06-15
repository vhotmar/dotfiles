-- It is base json + lang.json extra adds schema validation
vim.filetype.add {
  extension = {
    avsc = "json",
    avpr = "json",
  },
}

return {}
