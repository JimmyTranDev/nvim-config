local M = {}

function M.toggle_spellcheck() vim.cmd('set spell!') end

function M.toggle_wrap() vim.opt.wrap = not vim.opt.wrap:get() end

return M
