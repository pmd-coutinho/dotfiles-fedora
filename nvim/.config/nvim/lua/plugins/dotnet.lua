-- C# / .NET IDE layer.
--
-- Uses roslyn.nvim (the Microsoft Roslyn language server) — the modern
-- replacement for OmniSharp, and the right choice for .NET 8/10. The server
-- itself is installed via Mason as the `roslyn` package; roslyn.nvim
-- auto-detects that install.
--
-- If roslyn ever misbehaves (it's the one fiddly bit on Linux), the reliable
-- fallback is OmniSharp: delete this file and run `:LazyExtras` → enable
-- `lang.omnisharp`.
return {
  {
    "seblj/roslyn.nvim",
    ft = { "cs" },
    opts = {
      -- let roslyn.nvim broadcast project/solution to all buffers
      filewatching = "roslyn",
    },
  },

  -- Ensure the Roslyn LSP + debugger + formatter are installed via Mason.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, { "roslyn", "netcoredbg", "csharpier" })
    end,
  },

  -- Treesitter parsers for the .NET ecosystem.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "c_sharp", "xml", "sql", "dockerfile", "json", "yaml", "toml",
      })
    end,
  },

  -- Format C# with csharpier.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        cs = { "csharpier" },
      },
    },
  },
}
