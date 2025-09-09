return {
  'zbirenbaum/copilot.lua',
  cmd = 'Copilot',
  event = 'InsertEnter',
  cond = function()
    return not require('core.vscode').is_vscode() -- VSCode has its own Copilot extension
  end,

  config = function()
    require('copilot').setup({
      panel = {
        enabled = false,
        auto_refresh = false,
        keymap = {
          jump_prev = false,
          jump_next = false,
          accept = false,
          refresh = false,
          open = false,
        },
        layout = {
          position = 'bottom', -- | top | left | right | horizontal | vertical
          ratio = 0.4,
        },
      },
      suggestion = {
        enabled = true,
        auto_trigger = true,
        hide_during_completion = true,
        debounce = 75,
        keymap = {
          accept = '<c-h>',
          accept_word = false,
          accept_line = false,
          next = '<c-K>',
          prev = '<c-J>',
          dismiss = false,
        },
      },
      filetypes = {
        yaml = true,
        markdown = true,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        ['.'] = false,
      },
      copilot_node_command = 'node', -- Node.js version must be > 18.x
      server_opts_overrides = {},
    })
  end,
}
