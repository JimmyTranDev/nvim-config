local M = {}

-- Key-value storage using SQLite
local sqlite_file = os.getenv('HOME') .. '/.config/dotfiles_kv.db'

-- Initialize database
function M.init_db()
  local cmd = string.format('sqlite3 "%s" "CREATE TABLE IF NOT EXISTS keyvalue (key TEXT PRIMARY KEY, value TEXT);"', sqlite_file)
  os.execute(cmd)
end

-- Set a key-value pair
function M.set(key, value)
  if not key or not value then
    print('Error: Key and value cannot be empty')
    return false
  end

  M.init_db()

  local escaped_key = key:gsub("'", "''")
  local escaped_value = value:gsub("'", "''")

  local cmd = string.format('sqlite3 "%s" "INSERT OR REPLACE INTO keyvalue (key, value) VALUES (\'%s\', \'%s\');"', sqlite_file, escaped_key, escaped_value)

  local result = os.execute(cmd)
  if result then
    print(string.format("Successfully set key '%s' to '%s'", key, value))
    return true
  else
    print('Error: Failed to set key-value pair')
    return false
  end
end

-- Get a value by key
function M.get(key)
  if not key then
    print('Error: Key cannot be empty')
    return nil
  end

  M.init_db()

  local escaped_key = key:gsub("'", "''")
  local cmd = string.format('sqlite3 "%s" "SELECT value FROM keyvalue WHERE key = \'%s\';"', sqlite_file, escaped_key)

  local handle = io.popen(cmd)
  if not handle then
    print('Error: Failed to execute database query')
    return nil
  end

  local result = handle:read('*l')
  handle:close()

  if result and result ~= '' then
    print(string.format("Retrieved key '%s': %s", key, result))
    return result
  else
    print(string.format("Key '%s' not found", key))
    return nil
  end
end

-- Delete a key-value pair
function M.delete(key)
  if not key then
    print('Error: Key cannot be empty')
    return false
  end

  M.init_db()

  local escaped_key = key:gsub("'", "''")
  local cmd = string.format('sqlite3 "%s" "DELETE FROM keyvalue WHERE key = \'%s\';"', sqlite_file, escaped_key)

  local result = os.execute(cmd)
  if result then
    print(string.format("Successfully deleted key '%s'", key))
    return true
  else
    print('Error: Failed to delete key')
    return false
  end
end

-- List all keys
function M.list_keys()
  M.init_db()

  local cmd = string.format('sqlite3 "%s" "SELECT key FROM keyvalue ORDER BY key;"', sqlite_file)
  local handle = io.popen(cmd)
  if not handle then
    print('Error: Failed to execute database query')
    return {}
  end

  local keys = {}
  for line in handle:lines() do
    table.insert(keys, line)
  end
  handle:close()

  return keys
end

return M
