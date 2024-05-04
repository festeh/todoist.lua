local Menu = require("nui.menu")
local NuiTree = require("nui.tree")
local Messages = require("todoist.messages")

--- @class MainMenu
--- @field ui NuiMenu
--- @field state State
MainMenu = {

}

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
        type = "today",
        text = "Today",
        _type = "item",
        query = { today = true }
      }),
      NuiTree.Node({
        _id = "outdated",
        type = "outdated",
        text = "Outdated",
        _type = "item",
        query = { outdated = true }
      })
    })
    for _, project in ipairs(message.data) do
      local node = NuiTree.Node({
        type = "project",
        _id = project.id,
        text = project.name,
        _type = "item",
        project_id = project.id,
      })
      nodes = vim.list_extend(nodes, { node })
    end
    self.ui.tree:set_nodes(nodes)
    self.ui.tree:render()
    if message.set_cursor then
      vim.api.nvim_win_set_cursor(self.ui.winid, { 1, 0 })
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
