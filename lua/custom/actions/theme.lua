local M = {}

local constants = require('custom.constants.links')

-- Function to switch Catppuccin theme flavor
function M.switch_catppuccin_flavor()
  local flavors = constants.catppuccin.flavors
  local descriptions = constants.catppuccin.flavor_descriptions
  
  -- Create options with descriptions
  local options = {}
  for _, flavor in ipairs(flavors) do
    table.insert(options, descriptions[flavor])
  end
  
  vim.ui.select(options, {
    prompt = 'Select Catppuccin flavor:',
    format_item = function(item) return item end,
  }, function(selected_option)
    if not selected_option then return end
    
    -- Find the flavor from the selected description
    local selected_flavor = nil
    for flavor, description in pairs(descriptions) do
      if description == selected_option then
        selected_flavor = flavor
        break
      end
    end
    
    if not selected_flavor then return end
    
    -- Update the current flavor in constants
    constants.catppuccin.current_flavor = selected_flavor
    
    -- Apply the new theme
    vim.cmd('colorscheme catppuccin-' .. selected_flavor)
    
    -- Update the Catppuccin setup with new flavor
    require('catppuccin').setup({
      flavour = selected_flavor,
    })
    
    -- Refresh statusline with new colors
    if _G.refresh_statusline then
      _G.refresh_statusline()
    end
    
    -- Refresh which-key highlights
    if _G.refresh_which_key_highlights then
      _G.refresh_which_key_highlights()
    end
    
    vim.notify(string.format('🎨 Switched to Catppuccin %s', descriptions[selected_flavor]), vim.log.levels.INFO)
  end)
end

-- Function to cycle through flavors quickly
function M.cycle_catppuccin_flavor()
  local flavors = constants.catppuccin.flavors
  local current_flavor = constants.catppuccin.current_flavor
  local descriptions = constants.catppuccin.flavor_descriptions
  
  -- Find current index
  local current_index = 1
  for i, flavor in ipairs(flavors) do
    if flavor == current_flavor then
      current_index = i
      break
    end
  end
  
  -- Get next flavor (cycle back to 1 if at end)
  local next_index = current_index + 1
  if next_index > #flavors then
    next_index = 1
  end
  
  local next_flavor = flavors[next_index]
  
  -- Update constants and apply theme
  constants.catppuccin.current_flavor = next_flavor
  vim.cmd('colorscheme catppuccin-' .. next_flavor)
  
  -- Update the Catppuccin setup
  require('catppuccin').setup({
    flavour = next_flavor,
  })
  
  -- Refresh statusline with new colors
  if _G.refresh_statusline then
    _G.refresh_statusline()
  end
  
  -- Refresh which-key highlights
  if _G.refresh_which_key_highlights then
    _G.refresh_which_key_highlights()
  end
  
  vim.notify(string.format('🎨 Cycled to Catppuccin %s', descriptions[next_flavor]), vim.log.levels.INFO)
end

-- Function to get current theme info
function M.get_current_catppuccin_info()
  local current_flavor = constants.catppuccin.current_flavor
  local description = constants.catppuccin.flavor_descriptions[current_flavor]
  vim.notify(string.format('Current theme: %s', description), vim.log.levels.INFO)
end

return M
