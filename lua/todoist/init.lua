local Layout = require("nui.layout")
local Popup = require("nui.popup")
local Menu = require("nui.menu")
local Todoist = require("todoist.todoist")
local NuiTree = require("nui.tree")

local function menuComponent()
  local popup_options = {
    relative = "win",
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
      submit = { "<CR>", "<Space>" },
    },
    on_close = function()
      print("CLOSED")
    end,
    on_submit = function(item)
      print("SUBMITTED", vim.inspect(item))
    end
  })
  return menu
end

local function tasksComponent()
  local popup_options = {
    relative = "win",
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
      Menu.item("Loading..."),
    },
    keymap = {
      focus_next = { "j", "<Down>", "<Tab>" },
      focus_prev = { "k", "<Up>", "<S-Tab>" },
      close = { "<Esc>", "<C-c>" },
      submit = { "<CR>", "<Space>" },

    },
    on_close = function()
      print("CLOSED")
    end,
    on_submit = function(item)
      print("SUBMITTED", vim.inspect(item))
    end
  })
  return menu
end


local function initUI()
  local menu = menuComponent()
  local tasks = tasksComponent()
  local layout = Layout(
    {
      position = "0%",
      size = {
        width = "98%",
        height = "98%",
      },
    },
    Layout.Box({ Layout.Box(menu, { size = '20%' }), Layout.Box(tasks, { size = "80%" }) }, { dir = "row" })
  )
  return { menu = menu, tasks = tasks, layout = layout }
end

local function initCallback(menu)
  return function(out)
    local body = out.body
    local decoded = vim.fn.json_decode(body)
    print(vim.inspect(decoded))
    local node = NuiTree.Node({ text = "Loaded sneaky", _id = "dff", _type = "item" })
    menu.tree:add_node(node)
    menu.tree:render()
    return node
  end
end

local M = {}

function M.main()
  local todoist = Todoist.init()
  if todoist == nil then
    print("Failed to initialize Todoist")
    return
  end
  local ui = initUI()
  local callback = initCallback(ui.tasks)
  ui.layout:mount()
  local res = todoist:queryTodayTasks(vim.schedule_wrap(callback))
  local node = NuiTree.Node({ text = "Loaded", id = "loadedsd", _id = "ssdff", _type = "item" })
  ui.tasks.tree:add_node(node)
  print("Done 2")
  -- ui.tasks:unmount()
  ui.tasks.tree:render()
  -- ui.tasks:mount()
end

return M
