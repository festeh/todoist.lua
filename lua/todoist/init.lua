local Layout = require("nui.layout")
local Popup = require("nui.popup")
local Menu = require("nui.menu")
local Todoist = require("todoist.todoist")
local NuiTree = require("nui.tree")

local function statusComponent()
  local popup_options = {
    border = {
      style = "rounded",
    },
    focusable = false,
  }
  local popup = Popup(popup_options)
  return popup
end

local function menuComponent(on_change)
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
    win_options = {
      winhighlight = "Normal:Normal",
    },
    on_close = function()
      print("CLOSED")
    end,
    on_submit = function(item)
      print("SUBMITTED", vim.inspect(item))
    end,
    on_change = on_change,
  })
  return menu
end

local function tasksComponent(onChange)
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
    end,
    on_change = onChange,
  })
  return menu
end

local function prepareOnMenuChange(todoist, status, tasks)
  return function(item, menu)
    vim.api.nvim_buf_set_lines(status.bufnr, 0, -1, false, { "Selected: " .. item.text })
    print(vim.inspect(todoist))
    local filter = item.text == "Today" and "today" or "overdue"
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

local function prepareOnTaskChange(status)
  return function(item, menu)
    vim.api.nvim_buf_set_lines(status.bufnr, 0, -1, false, { "Selected Task: " .. item.text })
  end
end

local function initUI(todoist)
  local status = statusComponent()
  local tasks = tasksComponent(prepareOnTaskChange(status))
  local menu = menuComponent(prepareOnMenuChange(todoist, status, tasks))
  local upperRow = { Layout.Box(menu, { size = "20%" }), Layout.Box(tasks, { size = "80%" }) }

  local layout = Layout(
    {
      position = "0%",
      size = {
        width = "100%",
        height = "100%",
      },
    },
    Layout.Box(
      {
        Layout.Box(upperRow, { size = "85%", dir = "row" }),
        Layout.Box(status, { size = "15%" }),
      },
      { dir = "col" }
    )
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
  local todoist = Todoist.initTodoist()
  if todoist == nil then
    print("Failed to initialize Todoist")
    return
  end
  print(vim.inspect(todoist))
  local ui = initUI(todoist)
  local callback = initCallback(ui.tasks)
  ui.layout:mount()
  -- local res = todoist:queryTasks(vim.schedule_wrap(callback))
  local node = NuiTree.Node({ text = "Loaded", id = "loadedsd", _id = "ssdff", _type = "item" })
  ui.tasks.tree:add_node(node)
  print("Done 2")
  -- ui.tasks:unmount()
  ui.tasks.tree:render()
  -- ui.tasks:mount()
end

return M
