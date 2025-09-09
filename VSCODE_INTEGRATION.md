# VSCode + Neovim Integration Guide

This Neovim configuration now works seamlessly with both standalone Neovim and VSCode's Neovim extension.

## How It Works

The configuration automatically detects when it's running inside VSCode (`vim.g.vscode` is set) and:

1. **Disables conflicting plugins**: UI plugins like lualine, colorschemes, file explorers, terminals, etc.
2. **Keeps essential functionality**: Text manipulation, navigation, and editing enhancements
3. **Provides VSCode-specific keymaps**: Integrates with VSCode commands for file operations, git, etc.

## VSCode Setup

1. Install the [VSCode Neovim extension](https://marketplace.visualstudio.com/items?itemName=asvetliakov.vscode-neovim)
2. In your VSCode `settings.json`, add:
   ```json
   {
     "vscode-neovim.neovimExecutablePaths.darwin": "/opt/homebrew/bin/nvim",
     "vscode-neovim.neovimInitVimPaths.darwin": "~/.config/nvim/init.lua",
     "extensions.experimental.affinity": {
       "asvetliakov.vscode-neovim": 1
     }
   }
   ```
   
3. Adjust the paths according to your system (Linux users should use "linux" instead of "darwin")

## Plugin Behavior

### Disabled in VSCode
- **UI Plugins**: lualine, catppuccin theme, which-key
- **File Management**: yazi file manager, toggleterm
- **Git UI**: gitsigns, fugitive
- **LSP/Completion**: mason, blink.cmp (VSCode handles these)
- **Debugging**: nvim-dap (VSCode has built-in debugger)
- **Testing**: neotest (VSCode has test runners)
- **AI**: Copilot plugins (VSCode has native Copilot)

### Enabled in Both
- **Text Objects**: nvim-surround, mini.ai, treesitter-textobjects
- **Navigation**: hop.nvim, leap.nvim
- **Editing**: Comment.nvim, nvim-autopairs, nvim-ts-autotag
- **Core**: treesitter for syntax highlighting

### VSCode-Specific Keymaps
When in VSCode, certain leader key combinations are remapped to use VSCode commands:

- `<leader>ff` → VSCode Quick Open
- `<leader>fg` → VSCode Find in Files  
- `<leader>fc` → VSCode Command Palette
- `<leader>e` → VSCode File Explorer
- `<leader>gg` → VSCode Git View
- `<leader>xx` → VSCode Problems Panel
- `gd` → VSCode Go to Definition
- `gr` → VSCode Go to References
- etc.

## Custom Functions

Your custom utility functions (in `lua/custom/`) continue to work in both environments, but some UI-dependent features may be limited in VSCode.

## Troubleshooting

1. **If plugins don't load in regular Neovim**: Check that the VSCode detection is working by running `:lua print(vim.g.vscode)` - it should be `nil` in regular Neovim.

2. **If VSCode Neovim doesn't start**: Check the extension settings and ensure the Neovim path is correct.

3. **Performance issues**: The configuration loads fewer plugins in VSCode, so it should be faster. If not, check the VSCode extension logs.

## Benefits

- ✅ Same muscle memory and keybindings in both environments
- ✅ Reduced plugin conflicts with VSCode's built-in features  
- ✅ Better performance in VSCode (fewer plugins loaded)
- ✅ Full Neovim functionality when needed
- ✅ Seamless switching between editors
