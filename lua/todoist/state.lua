
--- @class State
--- @field status NuiPopup
--- @field main_window_id number | nil
--- @field task_window_id number | nil
--- @field selected_task Task | nil
State = {
  selected_task = nil,
  menu = nil,
  main_window_id = nil,
  task_window_id = nil,
}

local M = {}

function State:repr()
  local task_str = self.selected_task and self.selected_task.content or "None"
  local menu = (self.menu and self.menu.text) or "None"
  return string.format("State(selected_task=%s, menu=%s)", task_str, menu)
end

function State:_update_status()
  if self.status == nil then
    return
  end
  vim.api.nvim_buf_set_lines(self.status.bufnr, 0, -1, false, { self:repr() })
end

--- @param task Task | nil
function State:set_selected_task(task)
  self.selected_task = task
  self:_update_status()
end

function State:new_task_context()
  if self.menu == "today" then
    return { due_string = "today" }
  end
  return {}
end

function State:set_menu(menu)
  self.menu = menu
  self:_update_status()
end

function State:extract_last_input()
  local input = self.last_input
  self.last_input = ""
  return input
end

function M.init(status)
  State.__index = State
  local self = setmetatable({status = status}, State)
  return self
end

return M
