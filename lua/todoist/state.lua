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

--- # TODO: rename
function State:get_task_filter()
  local data = (self.menu and self.menu.data) or nil
  if data == nil then
    return function(task)
      return true
    end
  end
  return data:filter()
end

function State:new_task_context()
  return self.menu.data:new_task_context()
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
