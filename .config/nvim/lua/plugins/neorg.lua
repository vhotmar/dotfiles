return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        table.insert(opts.ensure_installed, "norg")
      else
        opts.ensure_installed = { "norg" }
      end
    end,
  },

  {
    "benlubas/neorg-interim-ls",
  },

  {
    "nvim-neorg/neorg",
    lazy = false,
    -- ft = "norg",
    -- dependencies = { "luarocks.nvim" },
    version = "*",
    config = function()
      require("neorg").setup {
        load = {
          ["core.defaults"] = {},
          ["core.dirman"] = {
            config = {
              workspaces = {
                notes = "~/main/notes/",
              },
              default_workspace = "notes",
            },
          },
          ["core.keybinds"] = {
            -- https://github.com/nvim-neorg/neorg/blob/main/lua/neorg/modules/core/keybinds/keybinds.lua
            config = {
              default_keybinds = true,
              -- neorg_leader = "<Leader><Leader>",
            },
          },
          ["external.interim-ls"] = {
            config = {
              -- default config shown
              completion_provider = {
                -- Enable or disable the completion provider
                enable = true,

                -- Show file contents as documentation when you complete a file name
                documentation = true,

                -- Try to complete categories provided by Neorg Query. Requires `benlubas/neorg-query`
                categories = false,

                -- suggest heading completions from the given file for `{@x|}` where `|` is your cursor
                -- and `x` is an alphanumeric character. `{@name}` expands to `[name]{:$/people:# name}`
                people = {
                  enable = false,

                  -- path to the file you're like to use with the `{@x` syntax, relative to the
                  -- workspace root, without the `.norg` at the end.
                  -- ie. `folder/people` results in searching `$/folder/people.norg` for headings.
                  -- Note that this will change with your workspace, so it fails silently if the file
                  -- doesn't exist
                  path = "people",
                },
              },
            },
          },
          ["core.completion"] = {
            config = { engine = { module_name = "external.lsp-completion" } },
          },
          ["core.concealer"] = { config = { icon_preset = "diamond" } },
          ["core.ui.calendar"] = {},
          ["core.journal"] = {
            config = {
              strategy = "flat",
              workspace = "notes",
            },
          },
          ["core.export"] = {},
          ["core.export.markdown"] = { config = { extensions = "all" } },
          ["core.summary"] = {},
          ["core.looking-glass"] = {},
        },
      }

      -- vim.wo.foldlevel = 99
      -- vim.wo.conceallevel = 2
    end,
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "norg", "rmd", "org", "codecompanion" },
  },
}
