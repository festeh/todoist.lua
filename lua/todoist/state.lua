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

function State:_updateStatus()
  if self.status == nil then
    return
  end
  vim.api.nvim_buf_set_lines(self.status.bufnr, 0, -1, false, { self:repr() })
end

function State:setSelectedTask(task)
  self.selectedTask = task
  self:_updateStatus()
end

function State:setMenu(menu)
  self.menu = menu
  self:_updateStatus()
end

function M.init(status)
  State.__index = State
  local self = setmetatable({status = status}, State)
  return self
end

return M
