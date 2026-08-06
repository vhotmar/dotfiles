-- denols only for deno-shebang scripts; vtsls for everything else.
-- Needed because repos like own-codereview keep a deno.json at the repo root
-- (for scripts/) next to package.json, which makes the stock lspconfig
-- root-detection hand the whole monorepo to denols and disable vtsls.
local function is_deno_script(bufnr)
  if vim.b[bufnr].deno_shebang ~= nil then
    return vim.b[bufnr].deno_shebang
  end
  local first = vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] or ""
  return first:match("^#!") ~= nil and first:match("deno") ~= nil
end

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      denols = {
        enabled = true,
        root_dir = function(bufnr, on_dir)
          if not is_deno_script(bufnr) then
            return
          end
          local root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock", ".git" })
            or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
          on_dir(root)
        end,
      },
      vtsls = {
        root_dir = function(bufnr, on_dir)
          if is_deno_script(bufnr) then
            return
          end
          local root = vim.fs.root(bufnr, {
            { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" },
            { ".git" },
          })
          on_dir(root or vim.fn.getcwd())
        end,
      },
    },
  },
}
