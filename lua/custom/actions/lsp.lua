-- =============================================================================
-- LSP Action Functions
-- Language Server Protocol management utilities
-- =============================================================================

local ui_utils = require('custom.utils.ui')

local M = {}

-- =============================================================================
-- Private Helper Functions
-- =============================================================================

--- Stop all active LSP clients
---@param silent boolean? Whether to suppress notifications
---@return number stopped_count Number of clients stopped
local function stop_all_lsp_clients(silent)
  local clients = vim.lsp.get_clients()
  local stopped_count = 0
  
  for _, client in pairs(clients) do
    if client and client.name then
      local ok, err = pcall(function()
        vim.lsp.stop_client(client.id)
      end)
      
      if ok then
        stopped_count = stopped_count + 1
        if not silent then
          vim.notify('Stopped LSP client: ' .. client.name, vim.log.levels.DEBUG)
        end
      else
        if not silent then
          vim.notify('Failed to stop LSP client ' .. client.name .. ': ' .. tostring(err), vim.log.levels.WARN)
        end
      end
    end
  end
  
  return stopped_count
end

--- Restart LSP for current buffer
---@param silent boolean? Whether to suppress error notifications
local function restart_lsp_for_buffer(silent)
  local ok, err = pcall(function()
    vim.cmd('edit')
    vim.cmd('LspStart')
  end)
  
  if not ok then
    if not silent then
      vim.notify('Failed to restart LSP: ' .. tostring(err), vim.log.levels.ERROR)
    end
    return false
  end
  
  return true
end

-- =============================================================================
-- Public API Functions
-- =============================================================================

--- Refresh all LSP clients (stop all and restart for current buffer)
function M.refresh_all_lsps()
  ui_utils.show_progress('Refreshing all LSP clients...')
  
  local stopped_count = stop_all_lsp_clients(false)
  
  if stopped_count > 0 then
    vim.notify(string.format('Stopped %d LSP client(s)', stopped_count), vim.log.levels.INFO)
  else
    vim.notify('No active LSP clients found', vim.log.levels.INFO)
  end
  
  -- Small delay to allow clients to fully stop
  vim.defer_fn(function()
    if restart_lsp_for_buffer(false) then
      ui_utils.show_success('LSP clients refreshed successfully')
    end
  end, 100)
end

--- Refresh all LSP clients silently (no notifications)
function M.refresh_all_lsps_silent()
  local stopped_count = stop_all_lsp_clients(true)
  
  -- Small delay to allow clients to fully stop
  vim.defer_fn(function()
    restart_lsp_for_buffer(true)
  end, 100)
end

return M
