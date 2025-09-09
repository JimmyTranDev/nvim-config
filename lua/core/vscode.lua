local M = {}

M.is_vscode = function() return vim.g.vscode ~= nil end

M.setup_vscode_options = function()
  if not M.is_vscode() then return end

  -- Disable certain visual elements that VSCode handles
  vim.opt.number = false
  vim.opt.relativenumber = false
  vim.opt.signcolumn = 'no'
  vim.opt.foldcolumn = '0'
  vim.opt.cursorline = false
  vim.opt.colorcolumn = ''

  -- Keep important editing behavior
  vim.opt.clipboard = 'unnamedplus'
  vim.opt.ignorecase = true
  vim.opt.smartcase = true

  -- VSCode handles these UI elements
  vim.opt.laststatus = 0 -- No status line in VSCode
  vim.opt.showtabline = 0 -- No tab line in VSCode
  vim.opt.cmdheight = 1 -- Minimal command height
end

M.setup_vscode_keymaps = function()
  if not M.is_vscode() then return end

  local keymap = vim.keymap

  -- Use VSCode's command palette instead of Telescope
  keymap.set('n', '<leader>ff', '<Cmd>call VSCodeNotify("workbench.action.quickOpen")<CR>')
  keymap.set('n', '<leader>fg', '<Cmd>call VSCodeNotify("workbench.action.findInFiles")<CR>')
  keymap.set('n', '<leader>fc', '<Cmd>call VSCodeNotify("workbench.action.showCommands")<CR>')

  -- Use VSCode's file explorer
  keymap.set('n', '<leader>e', '<Cmd>call VSCodeNotify("workbench.files.action.focusFilesExplorer")<CR>')

  -- Use VSCode's integrated terminal
  keymap.set('n', '<leader>tt', '<Cmd>call VSCodeNotify("workbench.action.terminal.toggleTerminal")<CR>')

  -- Use VSCode's git integration
  keymap.set('n', '<leader>gg', '<Cmd>call VSCodeNotify("workbench.view.scm")<CR>')
  keymap.set('n', '<leader>gb', '<Cmd>call VSCodeNotify("gitlens.toggleFileBlame")<CR>')

  -- Use VSCode's problem panel
  keymap.set('n', '<leader>xx', '<Cmd>call VSCodeNotify("workbench.actions.view.problems")<CR>')

  -- Format using VSCode
  keymap.set('n', '<leader>cf', '<Cmd>call VSCodeNotify("editor.action.formatDocument")<CR>')
  keymap.set('v', '<leader>cf', '<Cmd>call VSCodeNotify("editor.action.formatSelection")<CR>')

  -- Code actions using VSCode
  keymap.set('n', '<leader>ca', '<Cmd>call VSCodeNotify("editor.action.quickFix")<CR>')

  -- Rename using VSCode
  keymap.set('n', '<leader>cr', '<Cmd>call VSCodeNotify("editor.action.rename")<CR>')

  -- Go to definition/references using VSCode
  keymap.set('n', 'gd', '<Cmd>call VSCodeNotify("editor.action.revealDefinition")<CR>')
  keymap.set('n', 'gr', '<Cmd>call VSCodeNotify("editor.action.goToReferences")<CR>')
  keymap.set('n', 'gi', '<Cmd>call VSCodeNotify("editor.action.goToImplementation")<CR>')

  -- Diagnostics navigation
  keymap.set('n', '[d', '<Cmd>call VSCodeNotify("editor.action.marker.prev")<CR>')
  keymap.set('n', ']d', '<Cmd>call VSCodeNotify("editor.action.marker.next")<CR>')

  -- Folding
  keymap.set('n', 'za', '<Cmd>call VSCodeNotify("editor.toggleFold")<CR>')
  keymap.set('n', 'zR', '<Cmd>call VSCodeNotify("editor.unfoldAll")<CR>')
  keymap.set('n', 'zM', '<Cmd>call VSCodeNotify("editor.foldAll")<CR>')
end

M.setup = function()
  if M.is_vscode() then
    M.setup_vscode_options()
    M.setup_vscode_keymaps()
  end
end

return M
