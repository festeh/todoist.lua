local Menu = require("nui.menu")
local InputMenu = require("todoist.input_menu")
local Task = require("todoist.task")
local Messages = require("todoist.messages")
local NuiTree = require("nui.tree")

--- @class Tasks
--- @field ui NuiMenu
--- @field change_name_input NuiInput
--- @field new_task_input NuiInput
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

function Tasks:map(char, action)
  self.ui:map("n", char, action, { nowait = true, noremap = true })
end

function Tasks:add_keybinds()
  local state = self.state
  -- back to main menu
  self:map("h", function()
    self.state:notify({ type = Messages.MAIN_MENU_FOCUSED })
  end)
  -- reschedule task to today
  self:map("r", function()
    self.state:notify({ type = Messages.RESCHEDULE_TASK, id = state.selected_task.id, due_string = "today" })
  end)
  -- edit task name
  self:map("e", function()
    self.change_name_input._.default_value = state.selected_task.content
    self.change_name_input:mount()
  end)
  -- complete task
  self:map("c", function()
    self.state:notify({ type = Messages.COMPLETE_TASK, id = state.selected_task.id })
  end)
  -- add new task
  self:map("a", function()
    self.new_task_input:mount()
  end)
  -- delete task
  self:map("x", function()
    self.state:notify({ type = Messages.DELETE_TASK, id = state.selected_task.id })
  end)
end

function Tasks:prepare_on_submit_task_name()
  return function(name)
    self.state:notify({ type = Messages.RENAME_TASK, name = name })
  end
end

function Tasks:prepare_on_submit_new_task()
  return function(name)
    self.state:notify({ type = Messages.NEW_TASK, name = name })
  end
end

local function prepare_on_change(state)
  return function(item, _)
    local params = { content = item.text, id = item._id }
    state:set_selected_task(Task.init(params))
  end
end

function Tasks:on_notify(message)
  if message.type == Messages.TASKS_FOCUSED then
    local linenr = 1
    --- # TODO: remove this field from state
    vim.api.nvim_set_current_win(self.state.task_window_id)
    vim.api.nvim_win_set_cursor(self.state.task_window_id, { linenr, 0 })
    local node, target_linenr = self.ui.tree:get_node(linenr)
    self.ui._.on_change(node)
  end
  if message.type == Messages.TASKS_VIEW_LOADED then
    local nodes = {}
    for _, task in ipairs(message.data) do
      local node = NuiTree.Node({
        _type = "item",
        _id = task.id,
        text = task.content,
      })
      nodes = vim.list_extend(nodes, { node })
    end
    self.ui.tree:set_nodes(nodes)
    self.ui.tree:render()
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
  self.state = params.state
  self.change_name_input = InputMenu.init("[New Name]", self:prepare_on_submit_task_name())
  self.new_task_input = InputMenu.init("[New Task]", self:prepare_on_submit_new_task())
  self:add_keybinds()
  return self
end

return M
