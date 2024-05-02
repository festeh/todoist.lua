--- @class Task
--- @field id string
--- @field content string
Task = {
  id = "",
  content = ""
}

--- @class TaskParams
--- @field id string
--- @field content string

local M = {}

--- @param params TaskParams
--- @return Task
function M.init(params)
  local self = setmetatable(params, Task)
  Task.__index = Task
  return self
end

return M
