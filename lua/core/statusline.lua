-- Don't load statusline in VSCode
if vim.g.vscode then return end

local lualine = require('lualine')
local constants = require('core.constants')
local colors = constants.colors

local conditions = {
  buffer_not_empty = function() return vim.fn.empty(vim.fn.expand('%:t')) ~= 1 end,
  hide_in_width = function() return vim.fn.winwidth(0) > 80 end,
  check_git_workspace = function()
    local filepath = vim.fn.expand('%:p:h')
    local gitdir = vim.fn.finddir('.git', filepath .. ';')
    return gitdir and #gitdir > 0 and #gitdir < #filepath
  end,
}

-- Config
local config = {
  options = {
    -- Disable sections and component separators
    component_separators = '',
    section_separators = '',
    theme = {
      -- We are going to use lualine_c an lualine_x as left and
      -- right section. Both are highlighted by c theme .  So we
      -- are just setting default looks o statusline
      normal = { c = { fg = colors.green, bg = nil } },
      inactive = { c = { fg = colors.green, bg = nil } },
    },
  },
  sections = {
    -- these are to remove the defaults
    lualine_a = {},
    lualine_b = {},
    lualine_y = {},
    lualine_z = {},
    -- These will be filled later
    lualine_c = {},
    lualine_x = {},
  },
  inactive_sections = {
    -- these are to remove the defaults
    lualine_a = {},
    lualine_b = {},
    lualine_y = {},
    lualine_z = {},
    lualine_c = {},
    lualine_x = {},
  },
}

-- Inserts a component in lualine_c at left section
local function ins_left(component) table.insert(config.sections.lualine_c, component) end

-- Inserts a component in lualine_x at right section
local function ins_right(component) table.insert(config.sections.lualine_x, component) end


local function truncate_text(text)
  if type(text) == 'string' and #text > 40 then
    return text:sub(1, 37) .. '...'
  end
  return text
end

local function createLeftBubble(color, icon, component)
  local cond = component.cond
  component.color = color

  ins_left({
    function() return icon end,
    cond = cond,
    color = color,
    padding = { left = 1, right = 0 },
  })

  if type(component[1]) == 'function' then
    local orig_fn = component[1]
    component[1] = function(...)
      return truncate_text(orig_fn(...))
    end
  end
  if component.fmt then
    local orig_fmt = component.fmt
    component.fmt = function(text, ...)
      return truncate_text(orig_fmt(text, ...))
    end
  else
    component.fmt = truncate_text
  end
  ins_left(component)
end


local function createRightBubble(color, icon, component)
  local cond = component.cond
  component.color = color

  ins_right({
    function() return icon end,
    cond = cond,
    color = color,
    padding = { left = 1, right = 0 },
  })

  if type(component[1]) == 'function' then
    local orig_fn = component[1]
    component[1] = function(...)
      return truncate_text(orig_fn(...))
    end
  end
  if component.fmt then
    local orig_fmt = component.fmt
    component.fmt = function(text, ...)
      return truncate_text(orig_fmt(text, ...))
    end
  else
    component.fmt = truncate_text
  end
  ins_right(component)
end

createLeftBubble(function() return { fg = colors.green, gui = 'bold' } end, '', { 'mode' })

createLeftBubble(function() return { fg = colors.peach, gui = 'bold' } end, '󰕥', {
  function()
    local msg = 'NONE'
    local buf_ft = vim.bo.filetype
    local clients = vim.lsp.get_clients()
    if next(clients) == nil then return msg end
    for _, client in ipairs(clients) do
      local filetypes = client.config.filetypes
      if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then return client.name end
    end
    return msg
  end,
})

createLeftBubble(function() return { fg = colors.sapphire, gui = 'bold' } end, '', {
  function()
    local current_working_directory = vim.fn.getcwd()
    local folder_name = vim.fn.fnamemodify(current_working_directory, ':t')
    return folder_name
  end,
})

-- createLeftBubble(
--   function()
--     return { fg = colors.sky, gui = 'bold' }
--   end,
--   '󰈔',
--   { 'filename', cond = conditions.buffer_not_empty }
-- )

createLeftBubble(function() return { fg = colors.mauve, gui = 'bold' } end, '', {
  function()
    local status = vim.fn.FugitiveHead()
    if status == '' then return 'NONE' end
    return status
  end,
})

createLeftBubble(function() return { fg = colors.green, gui = 'bold' } end, '', { 'datetime', style = '%H:%M' })

-- -- Insert mid section. You can make any number of sections in neovim :)
-- -- for lualine it's any number greater then 2
-- ins_left {
--   function()
--     return '%='
--   end,
-- }

ins_left({
  'diff',
  -- Is it me or the symbol for modified us really weird
  symbols = { added = ' ', modified = ' ', removed = ' ' },
  diff_color = {
    added = { fg = colors.green },
    modified = { fg = colors.orange },
    removed = { fg = colors.red },
  },
  cond = conditions.hide_in_width,
  always_visible = true,
})

ins_right({
  'diagnostics',
  sources = { 'nvim_diagnostic', 'nvim_lsp', 'nvim_workspace_diagnostic' },
  symbols = { error = ' ', warn = '󰀨 ', info = ' ', hint = '󰠠 ' },
  diagnostics_color = {
    color_error = { fg = colors.red },
    color_warn = { fg = colors.yellow },
    color_info = { fg = colors.cyan },
  },
})

-- createRightBubble(
--   function()
--     return { fg = colors.yellow, gui = 'bold' }
--   end,
--   '󰊿',
--   {
--     function()
--       return vim.bo.fenc
--     end,
--     cond = conditions.buffer_not_empty,
--     fmt = string.upper,
--   }
-- )
--
-- createRightBubble(
--   function()
--     return { fg = colors.lavender, gui = 'bold' }
--   end,
--   '󰣇',
--   { 'o:fileformat', fmt = string.upper }
-- )
--
-- createRightBubble(
--   function()
--     return { fg = colors.maroon, gui = 'bold' }
--   end,
--   '󰡯',
--   { 'o:filetype', fmt = string.upper }
-- )
--
-- createRightBubble(
--   function()
--     return { fg = colors.blue, gui = 'bold' }
--   end,
--   '󰖡',
--   { 'filesize', cond = conditions.buffer_not_empty }
-- )
--
-- createRightBubble(
--   function()
--     return { fg = colors.pink, gui = 'bold' }
--   end,
--   '',
--   { 'location' }
-- )

lualine.setup(config)
