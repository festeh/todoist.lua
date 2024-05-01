local Popup = require("nui.popup")
local Menu = require("nui.menu")
local Input = require("nui.input")
local Request = require("todoist.request")

--- @class Tasks
--- @field ui NuiMenu
--- @field task_input NuiInput
Tasks = {}

local function task_input()
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

local function init_ui(on_change)
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
    end,
    on_change = on_change,
  })
  return menu
end

function Tasks:add_keybinds(state, todoist)
  local menu = self.ui
  -- back to main menu
  menu:map("n", "h", function()
    vim.api.nvim_set_current_win(state.main_window_id)
  end, { nowait = true, noremap = true })
  -- reschedule task to today
  menu:map("n", "r", function()
    if state.selected_task == nil then
      vim.notify("No task selected or wrong menu")
      return
    end
    -- TODO: custom reschedule?
    local res = todoist:rescheduleTask(state.selected_task._id, "today")
    if Request.is_success(res) then
      menu.tree:remove_node(state.selected_task._id)
      menu.tree:render()
      state:set_selected_task(nil)
    end
  end, { nowait = true, noremap = true })
  -- edit task name
  menu:map("n", "e", function()
    if state.selected_task == nil then
      return
    end
    -- TODO: implement
    taskInput._.default_value = state.selected_task.text
    taskInput:mount()
  end, { nowait = true, noremap = true })
  -- complete task
  menu:map("n", "c", function()
    if state.selected_task == nil then
      vim.notify("No task selected")
      return
    end
    local res = todoist:completeTask(state.selected_task._id)
    if Request.is_success(res) then
      menu.tree:remove_node(state.selected_task._id)
      menu.tree:render()
      state:set_selected_task(nil)
    else
      vim.notify("Failed to complete task")
    end
  end, { nowait = true, noremap = true })
end

local function prepare_on_change(state)
  return function(item, _)
    state:set_selected_task(item)
  end
end

--- @class TasksParams
--- @field state State
--- @field todoist Todoist

local M = {}

--- @param params TasksParams
M.init = function(params)
  local self = setmetatable({}, Tasks)
  Tasks.__index = Tasks
  local ui = init_ui(prepare_on_change(params.state))
  self.ui = ui
  self.task_input = task_input()
  self:add_keybinds(params.state, params.todoist)
  return self
end

return M
