return {
  ft = { 'java' },
  'nvim-java/nvim-java',
  config = function()
    require('java').setup()

    local formatter_path = vim.fn.fnamemodify(
      debug.getinfo(1, 'S').source:sub(2),
      ':h'
    ) .. '/intellij-java-style.xml'

    vim.lsp.config('jdtls', {
      settings = {
        java = {
          format = {
            enabled = true,
            settings = {
              url = formatter_path,
              profile = 'IntelliJStyle',
            },
          },
        },
      },
    })

    vim.lsp.enable('jdtls')
  end,
}
