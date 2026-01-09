local M = {}

local TEXT_TRUNCATE_LENGTH = 40
local TEXT_TRUNCATE_PREVIEW = 37
local MIN_WIDTH_FOR_DETAILS = 80
local DEFAULT_THEME_FLAVOR = 'mocha'

local function get_catppuccin_colors()
  local ok, catppuccin = pcall(require, 'catppuccin.palettes')
  if not ok then
    return {
      green = '#40a02b',
      peach = '#fe640b',
      sapphire = '#209fb5',
      mauve = '#8839ef',
      red = '#d20f39',
      yellow = '#df8e1d',
      sky = '#04a5e5',
    }
  end

  local colors = catppuccin.get_palette(DEFAULT_THEME_FLAVOR)

  colors.orange = colors.peach or colors.orange
  colors.cyan = colors.sky or colors.cyan

  return colors
end

local colors = get_catppuccin_colors()

local conditions = {
  buffer_not_empty = function() return vim.fn.empty(vim.fn.expand('%:t')) ~= 1 end,

  hide_in_width = function() return vim.fn.winwidth(0) > MIN_WIDTH_FOR_DETAILS end,

  check_git_workspace = function()
    local filepath = vim.fn.expand('%:p:h')
    local gitdir = vim.fn.finddir('.git', filepath .. ';')
    return gitdir and #gitdir > 0 and #gitdir < #filepath
  end,
}

local function truncate_text(text)
  if type(text) == 'string' and #text > TEXT_TRUNCATE_LENGTH then return text:sub(1, TEXT_TRUNCATE_PREVIEW) .. '...' end
  return tostring(text)
end

local config = {
  options = {
    component_separators = '',
    section_separators = '',
    theme = {
      normal = { c = { fg = colors.green, bg = nil } },
      inactive = { c = { fg = colors.green, bg = nil } },
    },
  },
  sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_y = {},
    lualine_z = {},
    lualine_c = {},
    lualine_x = {},
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_y = {},
    lualine_z = {},
    lualine_c = {},
    lualine_x = {},
  },
}

local function create_left_bubble(color_fn, icon, component)
  local cond = component.cond
  component.color = color_fn

  table.insert(config.sections.lualine_c, {
    function() return icon end,
    cond = cond,
    color = color_fn,
    padding = { left = 1, right = 0 },
  })

  if type(component[1]) == 'function' then
    local orig_fn = component[1]
    component[1] = function(...) return truncate_text(orig_fn(...)) end
  end

  if component.fmt then
    local orig_fmt = component.fmt
    component.fmt = function(text, ...) return truncate_text(orig_fmt(text, ...)) end
  else
    component.fmt = truncate_text
  end

  table.insert(config.sections.lualine_c, component)
end

local function create_right_bubble(color_fn, icon, component)
  local cond = component.cond
  component.color = color_fn

  table.insert(config.sections.lualine_x, {
    function() return icon end,
    cond = cond,
    color = color_fn,
    padding = { left = 1, right = 0 },
  })

  if type(component[1]) == 'function' then
    local orig_fn = component[1]
    component[1] = function(...) return truncate_text(orig_fn(...)) end
  end

  if component.fmt then
    local orig_fmt = component.fmt
    component.fmt = function(text, ...) return truncate_text(orig_fmt(text, ...)) end
  else
    component.fmt = truncate_text
  end

  table.insert(config.sections.lualine_x, component)
end

local function get_lsp_client()
  local buf_ft = vim.bo.filetype
  local clients = vim.lsp.get_clients()

  if next(clients) == nil then return 'NONE' end

  for _, client in ipairs(clients) do
    local filetypes = client.config.filetypes
    if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then return client.name end
  end

  return 'NONE'
end

local function get_directory_name()
  local cwd = vim.fn.getcwd()
  return vim.fn.fnamemodify(cwd, ':t')
end

local function get_git_branch()
  local ok, status = pcall(vim.fn.FugitiveHead)
  if not ok or status == '' then return 'NONE' end
  return status
end

create_left_bubble(function() return { fg = colors.green, gui = 'bold' } end, '', { 'mode' })

create_left_bubble(function() return { fg = colors.peach, gui = 'bold' } end, '󰕥', { get_lsp_client })

create_left_bubble(function() return { fg = colors.sapphire, gui = 'bold' } end, '', { get_directory_name })

create_left_bubble(function() return { fg = colors.mauve, gui = 'bold' } end, '', { get_git_branch })

create_left_bubble(function() return { fg = colors.green, gui = 'bold' } end, '', { 'datetime', style = '%H:%M' })

table.insert(config.sections.lualine_c, {
  'diff',
  symbols = { added = ' ', modified = ' ', removed = ' ' },
  diff_color = {
    added = { fg = colors.green },
    modified = { fg = colors.orange or colors.peach },
    removed = { fg = colors.red },
  },
  cond = conditions.hide_in_width,
  always_visible = true,
})

table.insert(config.sections.lualine_x, {
  'diagnostics',
  sources = { 'nvim_diagnostic', 'nvim_lsp', 'nvim_workspace_diagnostic' },
  symbols = { error = ' ', warn = '󰀨 ', info = ' ', hint = '󰠠 ' },
  diagnostics_color = {
    color_error = { fg = colors.red },
    color_warn = { fg = colors.yellow },
    color_info = { fg = colors.cyan or colors.sky },
  },
})

function M.refresh_statusline()
  colors = get_catppuccin_colors()

  config.options.theme.normal.c.fg = colors.green
  config.options.theme.inactive.c.fg = colors.green

  local ok, lualine = pcall(require, 'lualine')
  if ok then
    lualine.setup(config)
  else
    vim.notify('Failed to refresh statusline: lualine not available', vim.log.levels.WARN)
  end
end

function M.setup()
  local ok, lualine = pcall(require, 'lualine')
  if not ok then
    vim.notify('Lualine not available, skipping statusline setup', vim.log.levels.WARN)
    return
  end

  lualine.setup(config)

  vim.api.nvim_create_autocmd('ColorScheme', {
    pattern = 'catppuccin*',
    callback = M.refresh_statusline,
    desc = 'Refresh statusline when Catppuccin theme changes',
  })

  _G.refresh_statusline = M.refresh_statusline
end

M.setup()

return M
