return {
  "catppuccin/nvim",
  name = "nvim",
  priority = 1000,
  config = function()
    require("catppuccin").setup {
      transparent_background = true,
      flavour = "frappe",
      show_end_of_buffer = true,
    }
  end,
}
