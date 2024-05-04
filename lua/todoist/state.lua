local Messages = require("todoist.messages")

--- @class State
--- @field main_window_id number | nil
--- @field task_window_id number | nil
--- @field selected_task Task | nil
--- @field menu table | nil
--  @field subscribers table
State = {
  selected_task = nil,
  menu = nil,
  main_window_id = nil,
  task_window_id = nil,
  subscribers = {},
}

local M = {}

function State:repr()
  local task_str = self.selected_task and self.selected_task.content or "None"
  local menu = (self.menu and self.menu.text) or "None"
  return string.format("State(selected_task=%s, menu=%s)", task_str, menu)
end

--- @param task Task | nil
function State:set_selected_task(task)
  self.selected_task = task
  self:notify({ type = Messages.UPDATE_STATUS, status = self:repr() })
end

function State:set_menu(menu)
  self.menu = menu
  self:notify({ type = Messages.UPDATE_STATUS, status = self:repr() })
end

function State:get_task_filter()
  if self.menu.type == "date" then
    return function(task)
      return task.due == self.menu.query.due_string
    end
  end
  if self.menu.type == "project" then
    return function(task)
      return task.project_id == self.menu.project_id
    end
  end
  vim.notify("No menu set")
  return function(_)
    return false
  end
end

function State:new_task_context()
  if self.menu.type == "date" then
    if self.menu.query.due_string == "today" then
      return self.menu.query
    end
  end
  if self.menu.type == "project" then
    return self.menu.query
  end
  return {}
end

function State:extract_last_input()
  local input = self.last_input
  self.last_input = ""
  return input
end

function State:add_subscriber(subscriber)
  table.insert(self.subscribers, subscriber)
end

function State:notify(message)
  if message.type == nil then
    vim.notify("Message type is nil")
  end
  for _, subscriber in ipairs(self.subscribers) do
    subscriber:on_notify(message)
  end
end

function M.init(status)
  State.__index = State
  local self = setmetatable({ status = status }, State)
  return self
end

return M
