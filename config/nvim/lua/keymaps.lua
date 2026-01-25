
-- Definir líder global y local (debe ir antes de cualquier mapeo)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

-- Copiar y pegar
map("v", "<C-c>", '"+y', { noremap = true, desc = "Copiar al portapapeles" })
map("n", "<C-v>", '"+p', { noremap = true, desc = "Pegar desde portapapeles" })
map("i", "<C-v>", '<C-r>+', { noremap = true, desc = "Pegar en modo insert" })

-- Deshacer y rehacer estilo VSCode
map("n", "<C-z>", "u", { noremap = true, desc = "Deshacer" })
map("i", "<C-z>", "<ESC>u", { noremap = true, desc = "Deshacer en insert" })
map("n", "<C-y>", "<C-r>", { noremap = true, desc = "Rehacer" })
map("i", "<C-y>", "<ESC><C-r>", { noremap = true, desc = "Rehacer en insert" })

-- Buscar estilo VSCode
map("n", "<C-f>", "/", { noremap = true, desc = "Buscar" })
map("i", "<C-f>", "<ESC>/", { noremap = true, desc = "Buscar en insert" })

-- =========================================
-- Explorador de archivos
-- =========================================
map("n", "<leader>e", ":NvimTreeToggle<CR>", { noremap = true, desc = "Abrir árbol de archivos" })

-- Guardar archivo
map("n", "<leader>w", ":w<CR>", { noremap = true, desc = "Guardar archivo" })

-- Salir de Neovim
map("n", "<leader>q", ":q<CR>", { noremap = true, desc = "Salir de Neovim" })

-- Incrementar / Decrementar números
map("n", "+", "<C-a>", { noremap = true, desc = "Incrementar número" })
map("n", "-", "<C-x>", { noremap = true, desc = "Decrementar número" })

-- Seleccionar todo
map("n", "<C-a>", "gg<S-v>G", { noremap = true, desc = "Seleccionar todo" })

-- Indentar en visual
map("v", "<", "<gv", { noremap = true, silent = true, desc = "Indentar izquierda" })
map("v", ">", ">gv", { noremap = true, silent = true, desc = "Indentar derecha" })

-- Nueva pestaña
map("n", "te", ":tabedit<CR>", { noremap = true, desc = "Nueva pestaña" })

-- Dividir ventana
map("n", "<leader>sh", ":split<CR><C-w>w", { noremap = true, desc = "Dividir horizontal" })
map("n", "<leader>sv", ":vsplit<CR><C-w>w", { noremap = true, desc = "Dividir vertical" })

-- Navegación entre paneles
map("n", "<C-k>", "<C-w>k", { noremap = true, desc = "Mover arriba" })
map("n", "<C-j>", "<C-w>j", { noremap = true, desc = "Mover abajo" })
map("n", "<C-h>", "<C-w>h", { noremap = true, desc = "Mover izquierda" })
map("n", "<C-l>", "<C-w>l", { noremap = true, desc = "Mover derecha" })

-- Redimensionar ventanas
map("n", "<C-Up>", ":resize -3<CR>", { noremap = true, desc = "Reducir altura" })
map("n", "<C-Down>", ":resize +3<CR>", { noremap = true, desc = "Aumentar altura" })
map("n", "<C-Left>", ":vertical resize -3<CR>", { noremap = true, desc = "Reducir ancho" })
map("n", "<C-Right>", ":vertical resize +3<CR>", { noremap = true, desc = "Aumentar ancho" })

-- Buffers / tabs (barbar)
map("n", "<Tab>", ":BufferNext<CR>", { noremap = true, desc = "Buffer siguiente" })
map("n", "<S-Tab>", ":BufferPrevious<CR>", { noremap = true, desc = "Buffer anterior" })
map("n", "<leader>x", ":BufferClose<CR>", { noremap = true, desc = "Cerrar buffer" })
map("n", "<A-p>", ":BufferPin<CR>", { noremap = true, desc = "Fijar buffer" })

-- Salir de modo insert con jk
map("i", "jk", "<ESC>", { noremap = true, desc = "Salir de insert con jk" })

-- Ejecutar código según tipo de archivo
map("n", "<F5>", function()
  local ft = vim.bo.filetype
  local filename = vim.fn.expand("%")
  local output = vim.fn.expand("%:r")

  local function try_python_runners()
    local runners = { "python3", "python", "python3.11", "python3.10", "python3.9" }
    for _, cmd in ipairs(runners) do
      if vim.fn.executable(cmd) == 1 then
        vim.cmd("w")
        vim.cmd("!echo ''; " .. cmd .. " " .. filename)
        return
      end
    end
    print("No se encontró ninguna versión de Python disponible.")
  end

  if ft == "cpp" then
    vim.cmd("w")
    vim.cmd("!echo ''; g++ % -o " .. output .. " && ./" .. output)
  elseif ft == "c" then
    vim.cmd("w")
    vim.cmd("!echo ''; gcc % -o " .. output .. " && ./" .. output)
  elseif ft == "python" then
    try_python_runners()
  elseif ft == "bash" then
    vim.cmd("w")
    vim.cmd("!echo ''; bash " .. filename)
  elseif ft == "lua" then
    vim.cmd("w")
    vim.cmd("!echo ''; lua " .. filename)
  else
    print("No hay acción definida para filetype: " .. ft)
  end
end, { desc = "Compila o ejecuta según el tipo de archivo" })

