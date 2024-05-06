local Menu = require("nui.menu")
local NuiTree = require("nui.tree")
local Messages = require("todoist.messages")

--- @class MainMenu
--- @field ui NuiMenu
--- @field state State
MainMenu = {

}


--- @class TodayView
TodayView = {

}
TodayView.__index = TodayView

function TodayView.new()
  return setmetatable({}, TodayView)
end

function TodayView:filter()
  return function(task)
    if not task.due or task.due == vim.NIL then
      return false
    end
    return task.due.date == os.date("%Y-%m-%d")
  end
end

function TodayView:new_task_context()
  return {
    due_string = "today"
  }
end

--- @class OutdatedView
OutdatedView = {

}
OutdatedView.__index = OutdatedView

function OutdatedView.new()
  return setmetatable({}, OutdatedView)
end

function OutdatedView:filter()
  return function(task)
    if not task.due or task.due == vim.NIL then
      return false
    end
    return task.due.date < os.date("%Y-%m-%d")
  end
end

function OutdatedView:new_task_context()
  return {
  }
end

--- @class ProjectView
--- @field id string
ProjectView = {

}
ProjectView.__index = ProjectView

function ProjectView.new(id)
  return setmetatable({ id = id }, ProjectView)
end

function ProjectView:filter()
  return function(task)
    return task.project_id == self.id
  end
end

function ProjectView:new_task_context()
  return {
    project_id = self.id
  }
end

--- @param state State
local function prepare_on_change(state)
  return function(item, menu)
    state:set_menu(item)
    state:set_selected_task(nil)
    state:notify({ type = Messages.TASKS_VIEW_REQUESTED })
  end
end


function MainMenu:init_ui(on_change)
  local popup_options = {
    relative = "win",
    enter = true,
    border = {
      style = "rounded",
      text = {
        top = "[Todoist]",
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
    max_width = 20,
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>" },
    },
    win_options = {
      winhighlight = "Normal:Normal",
    },
    on_close = function()
    end,
    on_change = on_change,
  })
  return menu
end

--- @param params Params
function MainMenu:add_keybinds(params)
  local menu = self.ui
  menu:map("n", "l", function()
    self.state:notify({ type = Messages.TASKS_FOCUSED })
  end)
end

function MainMenu:on_notify(message)
  if message.type == Messages.PROJECTS_LOADED then
    local nodes = {}
    --- add Today and Outdated nodes
    nodes = vim.list_extend(nodes, {
      NuiTree.Node({
        _id = "today",
        _type = "item",
        text = "Today",
        data = TodayView.new(),
      }),
      NuiTree.Node({
        _id = "outdated",
        _type = "item",
        text = "Outdated",
        data = OutdatedView.new(),
      })
    })
    for _, project in ipairs(message.data) do
      local node = NuiTree.Node({
        _id = project.id,
        _type = "item",
        text = project.name,
        data = ProjectView.new(project.id),
      })
      nodes = vim.list_extend(nodes, { node })
    end
    self.ui.tree:set_nodes(nodes)
    self.ui.tree:render()
    if message.set_cursor then
      vim.api.nvim_win_set_cursor(self.ui.winid, { 1, 0 })
      local node, target_linenr = self.ui.tree:get_node(1)
      self.ui._.on_change(node)
    end
  end
  if message.type == Messages.MAIN_MENU_FOCUSED then
    vim.api.nvim_set_current_win(self.ui.winid)
  end
end

local M = {}

--- @class Params
--- @field state State

--- @param params Params
--- @return MainMenu
M.init = function(params)
  local self = setmetatable({}, MainMenu)
  MainMenu.__index = MainMenu
  local on_change = prepare_on_change(params.state)
  self.state = params.state
  self.ui = self:init_ui(on_change)
  self:add_keybinds(params)
  return self
end

return M
