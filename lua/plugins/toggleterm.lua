local languageActions = require('custom.actions.language')
local toggleTermActions = require('custom.actions.toggleterm')

local function grep_markdown_headings()
  local snacks = require('snacks')

  snacks.picker.grep({
    search = '^#{1,6} ',
    prompt = 'Markdown Headings',
    title = 'Find Markdown Headings',
    rg = {
      '--type=md',
      '--line-number',
      '--column',
      '--smart-case',
      '--no-heading',
      '--color=never',
    },
    layout = {
      preset = 'default',
      preview = true,
    },
    format = function(item)
      local text = item.text or ''
      local level = text:match('^(#{1,6})')
      local heading_text = text:match('^#{1,6}%s*(.*)')

      if level and heading_text then
        local indent = string.rep('  ', #level - 1)
        return {
          { item.filename and vim.fn.fnamemodify(item.filename, ':t') or '', 'Comment' },
          { ':' .. (item.lnum or ''), 'LineNr' },
          { ' ' },
          { indent .. level .. ' ' .. heading_text, 'Normal' },
        }
      else
        return { { item.text or '', 'Normal' } }
      end
    end,
  })
end

return {
  'akinsho/nvim-toggleterm.lua',
  keys = {
    { mode = 'n', '<leader>fm', grep_markdown_headings, desc = 'Find Markdown Headings', silent = true },

    { mode = 'n', '<leader>tl', ':4TermExec cmd="live-server --port=9090"<CR>', desc = 'Live Server', silent = true },
    { mode = 'n', '<leader>tM', languageActions.compile_mjml_file, desc = 'Compile Mjml Html', silent = true },

    { mode = 'n', '<leader>tdD', ':3TermExec cmd="mkdocs gh-deploy"<CR>', desc = 'Mkdocs Deploy', silent = true },
    { mode = 'n', '<leader>tds', ':4TermExec cmd="mkdocs serve"<CR>', desc = 'Mkdocs Serve', silent = true },
    { mode = 'n', '<leader>tdd', languageActions.serve_markdown_folder, desc = 'Markserve', silent = true },

    { mode = 'n', '<leader>t1', ':1ToggleTerm<CR>', desc = 'Toggle Terminal 1', silent = true },
    { mode = 'n', '<leader>t2', ':2ToggleTerm<Cr>', desc = 'Toggle Terminal 2', silent = true },

    { mode = 't', '<C-h>', [[<Cmd>wincmd h<CR>]], desc = 'Terminal left window', silent = true },
    { mode = 't', '<C-j>', [[<Cmd>wincmd j<CR>]], desc = 'Terminal down window', silent = true },
    { mode = 't', '<C-k>', [[<Cmd>wincmd k<CR>]], desc = 'Terminal up window', silent = true },
    { mode = 't', '<C-l>', [[<Cmd>wincmd l<CR>]], desc = 'Terminal right window', silent = true },
    { mode = 't', '<Esc>', [[<C-\><C-n>]], desc = 'Terminal escape to normal mode', silent = true },

    { mode = 'n', '<leader>tnum', languageActions.create_npm_update_executor(7, 'minor'), silent = true, desc = 'Npm Update Minor' },
    { mode = 'n', '<leader>tnun', languageActions.create_npm_update_executor(7, 'major'), silent = true, desc = 'Npm Update Major' },
    { mode = 'n', '<leader>tnup', languageActions.create_npm_update_executor(7, 'patch'), silent = true, desc = 'Npm Update Patch' },
    { mode = 'n', '<leader>tnui', languageActions.create_npm_update_executor(7, 'interactive'), silent = true, desc = 'Npm Update Interactive' },
    { mode = 'n', '<leader>tni', languageActions.create_package_command_runner(7, 'install'), silent = true, desc = 'Npm Install' },
    { mode = 'n', '<leader>tnt', languageActions.create_package_command_runner(7, 'test'), silent = true, desc = 'Npm Test' },
    { mode = 'n', '<leader>tnc', languageActions.create_package_command_runner(7, 'lint'), silent = true, desc = 'Npm Lint' },
    { mode = 'n', '<leader>tnb', languageActions.create_package_command_runner(7, 'check'), silent = true, desc = 'Npm Check' },

    { mode = 'n', '<leader>tnx', toggleTermActions.killAllToggleTerm, silent = true, desc = 'Kill All Terminals' },

    { mode = 'n', '<leader>tnd', languageActions.create_package_command_runner(6, 'dev'), silent = true, desc = 'Npm Dev' },
    { mode = 'n', '<leader>tns', languageActions.create_package_command_runner(5, 'start'), silent = true, desc = 'Npm Start' },

    { mode = 'n', '<leader>tnj', function() languageActions.run_package_script(1) end, silent = true, desc = 'Npm Script 1' },
    { mode = 'n', '<leader>tnJ', toggleTermActions.create_kill_toggle_term(1), silent = true, desc = 'Npm Script 1 Exit' },
    { mode = 'n', '<leader>tnk', function() languageActions.run_package_script(2) end, silent = true, desc = 'Npm Script 2' },
    { mode = 'n', '<leader>tnK', toggleTermActions.create_kill_toggle_term(2), silent = true, desc = 'Npm Script 2 Exit' },
    { mode = 'n', '<leader>tnl', function() languageActions.run_package_script(3) end, silent = true, desc = 'Npm Script 3' },
    { mode = 'n', '<leader>tnL', toggleTermActions.create_kill_toggle_term(3), silent = true, desc = 'Npm Script 3 Exit' },
    { mode = 'n', '<leader>tn;', function() languageActions.run_package_script(4) end, silent = true, desc = 'Npm Script 4' },
    { mode = 'n', '<leader>tn:', toggleTermActions.create_kill_toggle_term(4), silent = true, desc = 'Npm Script 4 Exit' },

    {
      mode = 'n',
      '<leader>tnf',
      function() languageActions.create_package_command_runner(9, 'fms:types', true)() end,
      silent = true,
      desc = 'Npm FMS Types and Gen',
    },
    {
      mode = 'n',
      '<leader>tna',
      function()
        languageActions.create_package_command_runner(5, 'build')()
        languageActions.create_package_command_runner(6, 'lint:fix')()
        languageActions.create_package_command_runner(7, 'test')()
      end,
      silent = true,
      desc = 'Npm All (build, lint, test)',
    },
    {
      mode = 'n',
      '<leader>tnA',
      function()
        for i = 6, 8 do
          toggleTermActions.create_kill_toggle_term(i)()
        end
      end,
      silent = true,
      desc = 'Npm Kill All (build, lint, test)',
    },

    {
      mode = 'n',
      '<leader>tma',
      function()
        vim.cmd('2TermExec cmd="make start-app"')
        vim.cmd('3TermExec cmd="make start-server"')
      end,
      silent = true,
      desc = 'Make All (start-app, start-server)',
    },
    { mode = 'n', '<leader>tmj', languageActions.create_make_command_runner(1), desc = 'Run Makefile Target', silent = true },
    { mode = 'n', '<leader>tmJ', toggleTermActions.create_kill_toggle_term(1), desc = 'Makefile Exit', silent = true },
    { mode = 'n', '<leader>tmk', languageActions.create_make_command_runner(2), desc = 'Run Makefile Target', silent = true },
    { mode = 'n', '<leader>tmK', toggleTermActions.create_kill_toggle_term(2), desc = 'Makefile Exit', silent = true },
    { mode = 'n', '<leader>tmm', languageActions.create_make_command_runner(3), desc = 'Run Makefile Target', silent = true },
    { mode = 'n', '<leader>tmM', toggleTermActions.create_kill_toggle_term(3), desc = 'Makefile Exit', silent = true },
    { mode = 'n', '<leader>tms', ':1TermExec cmd="make start"<CR>', desc = 'Make Start', silent = true },

    { mode = 'n', '<leader>tcr', ':4TermExec cmd="cargo run"<CR>', desc = 'Cargo Run', silent = true },
    { mode = 'n', '<leader>tcb', ':3TermExec cmd="cargo build"<CR>', desc = 'Cargo Build', silent = true },
    { mode = 'n', '<leader>tct', ':3TermExec cmd="cargo test"<CR>', desc = 'Cargo Test', silent = true },
    { mode = 'n', '<leader>tcR', ':3TermExec cmd="cargo run --release"<CR>', desc = 'Cargo Release', silent = true },
    { mode = 'n', '<leader>tcu', ':3TermExec cmd="cargo update"<CR>', desc = 'Cargo Update', silent = true },
    { mode = 'n', '<leader>tcd', ':3TermExec cmd="cargo doc"<CR>', desc = 'Cargo Doc', silent = true },
    { mode = 'n', '<leader>tcl', ':3TermExec cmd="cargo clippy"<CR>', desc = 'Cargo Clippy', silent = true },
    { mode = 'n', '<leader>tcf', ':3TermExec cmd="cargo fmt"<CR>', desc = 'Cargo Fmt', silent = true },
    { mode = 'n', '<leader>tcc', ':3TermExec cmd="cargo check"<CR>', desc = 'Cargo Check', silent = true },
    { mode = 'n', '<leader>tca', ':3TermExec cmd="cargo audit"<CR>', desc = 'Cargo Audit', silent = true },

    { mode = 'n', '<leader>tfb', ':3TermExec cmd="flutter pub run build_runner build"<CR>', desc = 'Build', silent = true },

    { mode = 'n', '<leader>tvs', languageActions.run_maven_spring_boot, desc = 'Start Project (Maven/Node)', silent = true },
    { mode = 'n', '<leader>tvc', ':3TermExec cmd="mvn compile"<CR>', desc = 'Maven Compile', silent = true },
    { mode = 'n', '<leader>tvt', ':3TermExec cmd="mvn test"<CR>', desc = 'Maven Test', silent = true },
    { mode = 'n', '<leader>tvi', ':3TermExec cmd="mvn install"<CR>', desc = 'Maven Install', silent = true },
    { mode = 'n', '<leader>tvC', ':3TermExec cmd="mvn clean"<CR>', desc = 'Maven Clean', silent = true },
    { mode = 'n', '<leader>tvp', ':3TermExec cmd="mvn package"<CR>', desc = 'Maven Package', silent = true },
    { mode = 'n', '<leader>tvd', ':3TermExec cmd="mvn deploy"<CR>', desc = 'Maven Deploy', silent = true },
    { mode = 'n', '<leader>tvJ', languageActions.run_java_class_javac, desc = 'Java Run Javac', silent = true },
    { mode = 'n', '<leader>tvj', languageActions.run_java_class_maven, desc = 'Maven Run', silent = true },
  },
  config = function()
    require('toggleterm').setup({
      size = 15,
      open_mapping = [[<c-\>]],
      shade_filetypes = {},
      shade_terminals = true,
      shading_factor = 1,
      start_in_insert = true,
      insert_mappings = true,
      terminal_mappings = true,
      direction = 'horizontal',
    })

    vim.keymap.set('n', [[<c-\>]], [[<Cmd>execute v:count1 . "ToggleTerm"<CR>]], { silent = true })
    vim.keymap.set('i', [[<c-\>]], [[<Esc><Cmd>execute v:count1 . "ToggleTerm"<CR>]], { silent = true })
  end,
}
