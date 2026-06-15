-- C# / .NET IDE layer.
--
-- Uses roslyn.nvim (the Microsoft Roslyn language server) — the modern
-- replacement for OmniSharp, and the right choice for .NET 8/10.
--
-- IMPORTANT: the `roslyn` package roslyn.nvim expects is NOT in the default
-- mason registry — it comes from the Crashdummyy custom registry. The default
-- registry only has a *different* package called `roslyn-language-server`,
-- which roslyn.nvim ignores. So we add the extra registry below; without it
-- you get `Cannot find package "roslyn"`.
--
-- If it ever misbehaves, fall back to OmniSharp: delete this file and run
-- `:LazyExtras` → enable `lang.omnisharp`.
return {
  -- Add the custom registry + ensure the .NET servers/tools are installed.
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.registries = opts.registries or { "github:mason-org/mason-registry" }
      -- Crashdummyy registry packages `roslyn` + `rzls` (Razor).
      table.insert(opts.registries, "github:Crashdummyy/mason-registry")
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "roslyn",      -- Microsoft.CodeAnalysis.LanguageServer (from Crashdummyy)
        "netcoredbg",  -- debugger
        "csharpier",   -- formatter
      })
    end,
  },

  {
    "seblj/roslyn.nvim",
    ft = { "cs" },
    opts = {
      filewatching = "roslyn",
    },
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
