vim.api.nvim_command('set runtimepath^=~/projects/todoist_lua')
vim.api.nvim_command('set runtimepath^=/home/dlipin/.local/share/nvim/lazy/nui.nvim')
package.loaded["todoist"] = nil
local m = require("todoist")

m.init()
