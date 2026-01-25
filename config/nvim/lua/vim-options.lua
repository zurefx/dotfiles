vim.opt.number = true                   -- Mostrar número de línea
vim.opt.relativenumber = false          -- No mostrar número relativo
vim.opt.mouse = 'a'                     -- Habilitar mouse
vim.opt.showmode = false                -- Ocultar modo en la barra
vim.g.have_nerd_font = true            -- Indicador para iconos

-- Portapapeles
vim.schedule(function()
  vim.opt.clipboard = 'unnamedplus'    -- Usar portapapeles del sistema
end)

-- Indentado y formato
vim.opt.autoindent = true
vim.opt.wrap = true
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Interfaz
vim.opt.signcolumn = 'yes'             -- Mostrar columna de signos
vim.opt.cursorline = true               -- Resaltar solo la línea del cursor
vim.cmd([[highlight CursorLine guibg=NONE ctermbg=NONE]]) -- Fondo del cursor transparente y sutil

vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split'
vim.opt.scrolloff = 10
vim.opt.confirm = true

