return {
  "saghen/blink.cmp",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "rafamadriz/friendly-snippets",
  },
  version = "1.*",
  opts = {
    -- Preset para comportamiento VSCode
    keymap = { preset = "enter" },  -- Enter confirma la selección

    -- Apariencia
    appearance = {
      nerd_font_variant = "mono",
    },

    -- Fuentes de autocompletado
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },

    -- Fuzzy search
    fuzzy = {
      implementation = "prefer_rust_with_warning",
    },

    -- Comportamiento
    completion = {
      autocomplete = true, -- abre automáticamente cuando escribes
      completeopt = "menu,menuone,noinsert,noselect", -- estilo VSCode
    },
  },
}

