-- vim.api.nvim_command('set runtimepath^=~/projects/todoist_lua')
vim.api.nvim_command('set runtimepath^=~/Projects/todoist_lua')
vim.api.nvim_command('set runtimepath^=~/.local/share/nvim/lazy/nui.nvim')
package.loaded["todoist"] = nil
package.loaded["todoist.todoist"] = nil
local m = require("todoist")

m.main()
