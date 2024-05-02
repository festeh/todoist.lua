local Menu = require("nui.menu")

--- @class MainMenu
--- @field ui NuiMenu
MainMenu = {

}
--- @param state State
--- @param tasks_menu Tasks
local function prepare_on_change(state, tasks_menu)
  return function(item, menu)
    local filter = item.text == "Today" and "today" or "overdue"
    state:set_menu(filter)
    state:set_selected_task(nil)
    tasks_menu:reload(filter)
  end
end

local function init_ui(on_change)
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
      Menu.item("Today"),
      Menu.item("Outdated"),
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
  local state = params.state
  local tasks = params.tasks
  local menu = self.ui
  menu:map("n", "l", function()
    vim.api.nvim_set_current_win(state.task_window_id)
    local linenr = 1
    vim.api.nvim_win_set_cursor(state.task_window_id, { linenr, 0 })
    local node, target_linenr = tasks.ui.tree:get_node(linenr)
    tasks.ui._.on_change(node)
  end)
end

local M = {}

--- @class Params
--- @field todoist Todoist
--- @field state State
--- @field tasks Tasks

--- @param params Params
--- @return MainMenu
M.init = function(params)
  local self = setmetatable({}, MainMenu)
  MainMenu.__index = MainMenu
  local on_change = prepare_on_change(params.state, params.tasks)
  self.ui = init_ui(on_change)
  self:add_keybinds(params)
  return self
end

return M
