return {
  "mikavilpas/yazi.nvim",
  event = "VeryLazy",
  dependencies = {
    "folke/snacks.nvim",
  },
  enabled = function()
    if vim.fn.executable "yazi" == 1 then
      return true
    end
    return false
  end,
  lazy = true,
  keys = {
    {
      "<leader>a",
      mode = { "n", "v" },
      "<cmd>Yazi<cr>",
      desc = "Open yazi at the current file",
    },
    -- {
    --   -- Open in the current working directory
    --   "<leader>cw",
    --   "<cmd>Yazi cwd<cr>",
    --   desc = "Open the file manager in nvim's working directory",
    -- },
    {
      "<c-up>",
      "<cmd>Yazi toggle<cr>",
      desc = "Resume the last yazi session",
    },
  },
  opts = {
    -- open_for_directories = true,
    -- floating_window_scaling_factor = 1,
  },
}
