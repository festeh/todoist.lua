package.loaded["todoist"] = nil
local m = require("todoist")

print(vim.inspect(m))

m.init()

