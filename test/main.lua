vim.api.nvim_command('set runtimepath^=~/projects/todoist_lua')
vim.api.nvim_command('set runtimepath^=~/Projects/todoist_lua')
vim.api.nvim_command('set runtimepath^=~/.local/share/nvim/lazy/nui.nvim')

for pack, _ in pairs(package.loaded) do
  if pack:match("^todoist") then
    package.loaded[pack] = nil
  end
end

local m = require("todoist")

m.main()
