return {
  -- slime (REPL integration)
  {
    "jpalardy/vim-slime",
    keys = {
      { "<leader>rc", "<cmd>SlimeConfig<cr>", desc = "Slime config" },
      { "<leader>rr", "<Plug>SlimeSendCell<BAR>/^# %%<CR>", desc = "Slime send cell" },
      { "<leader>rl", "<Plug>SlimeLineSend", desc = "Slime send line" },
      { "<leader>rm", "<Plug>SlimeMotionSend", desc = "Slime send motion" },
      { "<leader>re", "<Plug>SlimeRegionSend", mode = { "x" }, desc = "Evaluate selected" },
    },
    config = function()
      vim.g.slime_no_mappings = 1
      vim.g.slime_target = "tmux"
      vim.g.slime_cell_delimiter = "# %%"
      vim.g.slime_bracketed_paste = 1
      vim.g.slime_default_config = {
        socket_name = vim.api.nvim_eval 'get(split($TMUX, ","), 0)',
        target_pane = "{right}",
      }
    end,
  },
}