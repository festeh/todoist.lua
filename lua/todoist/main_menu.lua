local Menu = require("nui.menu")

--- @param state State
--- @param tasks_menu Tasks
local function prepare_on_change(state, tasks_menu)
  return function(item, menu)
    vim.notify(item.text, "info", { title = "Selected in main" })
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

--- @param menu NuiMenu
--- @param state State
local function add_keybinds(menu, state)
  menu:map("n", "l", function()
    vim.api.nvim_set_current_win(state.task_window_id)
    vim.api.nvim_win_set_cursor(state.task_window_id, { 1, 0 })
  end)
end

--- @class MainMenu
--- @field ui NuiMenu
MainMenu = {

}

local M = {}

--- @class Params
--- @field todoist Todoist
--- @field state State
--- @field tasks Tasks

--- @param params Params
--- @return MainMenu
M.init = function(params)
  local self = setmetatable({}, MainMenu)
  local on_change = prepare_on_change(params.state, params.tasks)
  self.ui = init_ui(on_change)
  add_keybinds(self.ui, params.state)
  return self
end

return M
