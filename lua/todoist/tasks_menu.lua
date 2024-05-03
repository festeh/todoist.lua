local Menu = require("nui.menu")
local Request = require("todoist.request")
local InputMenu = require("todoist.input_menu")
local NuiTree = require("nui.tree")
local Task = require("todoist.task")

--- @class Tasks
--- @field ui NuiMenu
--- @field change_name_input NuiInput
--- @field new_task_input NuiInput
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
    local id = state.selected_task.id
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
    self.change_name_input._.default_value = state.selected_task.content
    self.change_name_input:mount()
  end, { nowait = true, noremap = true })
  -- complete task
  menu:map("n", "c", function()
    if state.selected_task == nil then
      vim.notify("No task selected")
      return
    end
    local res = todoist:complete(state.selected_task.id)
    if Request.is_success(res) then
      menu.tree:remove_node(state.selected_task.id)
      menu.tree:render()
      state:set_selected_task(nil)
    else
      vim.notify("Failed to complete a task")
    end
  end, { nowait = true, noremap = true })
  -- add new task
  menu:map("n", "a", function()
    self.new_task_input:mount()
  end, { nowait = true, noremap = true })
  -- delete task
  menu:map("n", "x", function()
    if state.selected_task == nil then
      vim.notify("No task selected")
      return
    end
    local res = todoist:delete_task(state.selected_task.id)
    if Request.is_success(res) then
      vim.notify("Task deleted", "info", { title = "Success" })
      menu.tree:remove_node(state.selected_task.id)
      menu.tree:render()
      state:set_selected_task(nil)
    else
      vim.notify("Failed to delete a task")
    end
  end, { nowait = true, noremap = true })
end

function Tasks:prepare_on_submit_task_name()
  local state = self.state
  return function(name)
    local selected_task = state.selected_task
    if selected_task == nil then
      return
    end
    local res = self.todoist:update(selected_task.id, { content = name })
    if Request.is_success(res) then
      self:reload()
      vim.notify("Task renamed", "info", { title = "Success" })
      state:set_selected_task(Task.init({ content = name, id = selected_task.id }))
    else
      vim.notify("Failed to rename a task")
    end
  end
end

function Tasks:prepare_on_submit_new_task()
  local state = self.state
  return function(name)
    local context = state:new_task_context()
    context = vim.tbl_extend("force", context, { content = name })
    local res = self.todoist:new_task(context)
    if Request.is_success(res) then
      self:reload()
    else
      vim.notify("Failed to create a task")
    end
  end
end

function Tasks:reload()
  local query = self.state:reload_tasks_context()
  self.todoist:query_tasks(query, vim.schedule_wrap(function(out)
    local body = out.body
    local decoded = vim.fn.json_decode(body)
    local nodes = {}
    for _, task in ipairs(decoded) do
      table.insert(nodes, NuiTree.Node({ text = task.content, _id = task.id, _type = "item" }))
    end
    self.ui.tree:set_nodes(nodes)
    self.ui.tree:render()
  end))
end

local function prepare_on_change(state)
  return function(item, _)
    local params = { content = item.text, id = item._id }
    state:set_selected_task(Task.init(params))
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
  self.change_name_input = InputMenu.init("[New Name]", self:prepare_on_submit_task_name())
  self.new_task_input = InputMenu.init("[New Task]", self:prepare_on_submit_new_task())
  self:add_keybinds()
  return self
end

return M
