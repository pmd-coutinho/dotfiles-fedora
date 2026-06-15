-- Catppuccin Mocha — match the rest of the desktop.
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = false,
      integrations = {
        cmp = true,
        gitsigns = true,
        treesitter = true,
        native_lsp = { enabled = true },
        mason = true,
        which_key = true,
        telescope = { enabled = true },
        fzf = true,
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin-mocha",
    },
  },
}
