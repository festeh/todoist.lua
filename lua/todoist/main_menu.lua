local Menu = require("nui.menu")
local NuiTree = require("nui.tree")

local function prepareOnMenuChange(state, todoist, tasks)
  return function(item, menu)
    local filter = item.text == "Today" and "today" or "overdue"
    state:set_menu(item.text)
    state:set_selected_task(nil)
    todoist:queryTasks({ filter = filter }, vim.schedule_wrap(function(out)
      local body = out.body
      local decoded = vim.fn.json_decode(body)
      local nodes = {}
      for _, task in ipairs(decoded) do
        table.insert(nodes, NuiTree.Node({ text = task.content, _id = task.id, _type = "item" }))
      end
      tasks.tree:set_nodes(nodes)
      tasks.tree:render()
    end))
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
  local on_change = prepareOnMenuChange(params.state, params.todoist, params.tasks)
  self.ui = init_ui(on_change)
  add_keybinds(self.ui, params.state)
  return self
end

return M
