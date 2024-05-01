local Menu = require("nui.menu")
local Request = require("todoist.request")
local InputMenu = require("todoist.input_menu")

--- @class Tasks
--- @field ui NuiMenu
--- @field task_input NuiInput
--- @field todoist Todoist
--- @field state State
Tasks = {}


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

function Tasks:add_keybinds()
  local menu = self.ui
  local state = self.state
  local todoist = self.todoist
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
    local id = state.selected_task._id
    -- TODO: custom reschedule?
    local res = todoist:update(id, { due_string = "today" })
    if Request.is_success(res) then
      menu.tree:remove_node(id)
      menu.tree:render()
      state:set_selected_task(nil)
    end
  end, { nowait = true, noremap = true })
  -- edit task name
  menu:map("n", "e", function()
    if state.selected_task == nil then
      vim.notify("No task selected")
      return
    end
    self.task_input._.default_value = state.selected_task.text
    self.task_input:mount()
  end, { nowait = true, noremap = true })
  -- complete task
  menu:map("n", "c", function()
    if state.selected_task == nil then
      vim.notify("No task selected")
      return
    end
    local res = todoist:complete(state.selected_task._id)
    if Request.is_success(res) then
      menu.tree:remove_node(state.selected_task._id)
      menu.tree:render()
      state:set_selected_task(nil)
    else
      vim.notify("Failed to complete a task")
    end
  end, { nowait = true, noremap = true })
end

function Tasks:prepare_on_submit_task_name()
  return function(name)
    local res = self.todoist:update(self.state.selected_task._id, { content = name })
    if Request.is_success(res) then
      self.state.set_selected_task(name)
      self.ui.tree:render()
    else
      vim.notify("Failed to rename a task")
    end
  end
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
  self.todoist = params.todoist
  self.state = params.state
  self.task_input = InputMenu.init("[New Name]", self:prepare_on_submit_task_name())
  self:add_keybinds()
  return self
end

return M
