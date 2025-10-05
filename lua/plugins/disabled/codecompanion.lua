return {
  'olimorris/codecompanion.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-treesitter/nvim-treesitter',
    'hrsh7th/nvim-cmp', -- Optional: For slash commands and variables in the chat buffer
    'nvim-telescope/telescope.nvim', -- Optional: For slash commands
    { 'stevearc/dressing.nvim', opts = {} }, -- Optional: Improves the default Neovim UI
  },

  -- Plugin keybindings (moved outside of config)
  keys = {
    { '<leader>ba', '<cmd>CodeCompanionActions<cr>', mode = { 'n', 'v' }, desc = 'CodeCompanion actions' },
    { '<leader>bc', '<cmd>CodeCompanionChat Add<cr>', mode = 'v', desc = 'Add selection to chat' },
    { '<leader>bt', '<cmd>CodeCompanionChat Toggle<cr>', mode = { 'n', 'v' }, desc = 'Toggle chat' },
    { '<leader>bf', '<cmd>CodeCompanionChat<cr>', mode = 'n', desc = 'Open chat' },
    { '<leader>bl', '<cmd>CodeCompanion<cr>', mode = { 'n', 'v' }, desc = 'Inline assistant' },
    { '<leader>bp', '<cmd>CodeCompanion /<cr>', mode = { 'n', 'v' }, desc = 'Prompt library' },
  },

  config = function()
    local status_ok, codecompanion = pcall(require, 'codecompanion')
    if not status_ok then
      vim.notify('CodeCompanion not found', vim.log.levels.ERROR)
      return
    end

    codecompanion.setup({
      -- Adapter strategies
      strategies = {
        chat = { adapter = 'copilot' },
        inline = { adapter = 'copilot' },
        agent = { adapter = 'copilot' },
      },

      -- Adapter configuration (using latest format)
      adapters = {
        name = "copilot",
        model = "claude-sonnet-4",
      },

      -- General options
      opts = {
        log_level = 'ERROR',
        send_code = true,
        silence_notifications = false,
      },

      -- UI configuration
      display = {
        action_palette = {
          width = 95,
          height = 10,
        },
        chat = {
          window = {
            layout = 'vertical',
            width = 0.4,
            height = 1.0,
            relative = 'editor',
            border = 'rounded',
            row = 0,
            col = '100%',
            opts = {
              breakindent = true,
              cursorcolumn = false,
              cursorline = false,
              foldcolumn = '0',
              linebreak = true,
              list = false,
              signcolumn = 'no',
              spell = false,
              wrap = true,
              winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
            },
          },
          intro_message = 'Welcome to CodeCompanion ✨',
          separator = '─',
          show_header_separator = true,
          show_references = true,
        },
      },

      -- Chat buffer keymaps (simplified format)
      keymaps = {
        ['<C-s>'] = 'keymaps.send',
        ['<C-c>'] = 'keymaps.close',
        ['q'] = 'keymaps.cancel_request',
        ['gc'] = 'keymaps.clear',
        ['ga'] = 'keymaps.codeblock',
        ['gs'] = 'keymaps.save',
        [']'] = 'keymaps.next',
        ['['] = 'keymaps.previous',
      },
    })
  end,
}
