State = {
  selectedTask = nil,
  menu = nil,
}

local M = {}

function State:repr()
  local task = (self.selectedTask and self.selectedTask.text) or "None"
  local menu = self.menu or "None"
  return string.format("State(selectedTask=%s, menu=%s)", task, menu)
end

function M.init()
  State.__index = State
  local self = setmetatable({}, State)
  return self
end

return M
