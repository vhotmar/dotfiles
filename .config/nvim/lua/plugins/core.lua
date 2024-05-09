return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-frappe",
    },
  },

  {
    "telescope.nvim",
    dependencies = {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      config = function()
        require("telescope").load_extension "fzf"
      end,
    },
  },

  {
    "echasnovski/mini.indentscope",
    ---@param opts table
    opts = function(_, opts)
      opts.draw = {}
      opts.draw.delay = 0
      opts.draw.animation = require("mini.indentscope").gen_animation.none()
    end,
  },

  {
    "nvim-notify",
    opts = {
      render = "compact",
    },
  },

  {
    "kaarmu/typst.vim",
    ft = "typst",
    lazy = false,
  },

  {
    "vhyrro/luarocks.nvim",
    priority = 1000, -- We'd like this plugin to load first out of the rest
    config = true, -- This automatically runs `require("luarocks-nvim").setup()`
  },

  {
    "nvim-neorg/neorg",
    ft = "norg",
    dependencies = { "luarocks.nvim" },
    version = "*",
    config = function()
      require("neorg").setup {
        load = {
          ["core.defaults"] = {},
          ["core.concealer"] = {},
          ["core.completion"] = {
            config = { engine = "nvim-cmp" },
          },
          ["core.integrations.nvim-cmp"] = {},
        },
      }

      -- vim.wo.foldlevel = 99
      -- vim.wo.conceallevel = 2
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "norg",
      },
    },
  },

  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },

  {
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
  },
}
