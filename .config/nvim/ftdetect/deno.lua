vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  callback = function(args)
    local line = vim.api.nvim_buf_get_lines(args.buf, 0, 1, false)[1] or ""
    if vim.regex([[^#!.*\<deno\>]]):match_str(line) ~= nil then
      vim.b[args.buf].deno_shebang = true
      vim.bo[args.buf].filetype = "typescript"
    end
  end,
})
