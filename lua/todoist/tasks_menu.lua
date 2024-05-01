local Popup = require("nui.popup")
local Menu = require("nui.menu")
local Input = require("nui.input")
local Request = require("todoist.request")

local function inputComponent()
  local popup_options = {
    position = "50%",
    zindex = 1000,
    size = {
      width = 100,
    },
    border = {
      style = "rounded",
      text = {
        top = "[New Name]",
        top_align = "center",
      },
    }
  }
  local input = Input(popup_options, {
    default_value = "New Task",
    on_close = function()
      print("CLOSED")
    end,
    on_submit = function(item)
      print("SUBMITTED", vim.inspect(item))
    end,
  })
  return input
end



--- @param state State
--- @param todoist Todoist
local function init_ui(state, todoist, taskInput, onChange)
  local popup_options = {
    relative = "win",
    enter = false,
    border = {
      style = "rounded",
      text = {
        top = "[Tasks]",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal",
    }
  }

  local menu = Menu(popup_options, {
    lines = {
    },
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>" },
    },
    on_close = function()
      print("CLOSED")
    end,
    on_submit = function(item)
      print("SUBMITTED", vim.inspect(item))
    end,
    on_change = onChange,
  })
  menu:map("n", "c", function()
    if state.selectedTask == nil then
      vim.notify("No task selected")
      return
    end
    local res = todoist:completeTask(state.selectedTask._id)
    if Request.is_success(res) then
      menu.tree:remove_node(state.selectedTask._id)
      menu.tree:render()
      state:setSelectedTask(nil)
    else
      vim.notify("Failed to complete task")
    end
  end, { nowait = true, noremap = true })
  menu:map("n", "r", function()
    if state.menu ~= "overdue" or state.selectedTask == nil then
      vim.notify("No task selected or wrong menu")
      return
    end
    local res = todoist:rescheduleTask(state.selectedTask._id, "today")
    if Request.is_success(res) then
      menu.tree:remove_node(state.selectedTask._id)
      menu.tree:render()
      state:setSelectedTask(nil)
    end
  end, { nowait = true, noremap = true })
  menu:map("n", "e", function()
    if state.selectedTask == nil then
      return
    end
    taskInput._.default_value = state.selectedTask.text
    taskInput:mount()
  end, { nowait = true, noremap = true })
  return menu
end


local function prepareOnTaskChange(state)
  return function(item, menu)
    state:setSelectedTask(item)
  end
end

--- @class Tasks
Tasks = {}

local M = {}

--- @class TasksParams
--- @field state State
--- @field todoist Todoist

--- @param params TasksParams
M.init = function(params)
  local self = setmetatable({}, Tasks)
  local ui = init_ui(params.state, params.todoist, inputComponent(), prepareOnTaskChange(params.state))
  self.ui = ui
  return self
end

return M
