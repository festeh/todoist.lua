local Layout = require("nui.layout")
local Popup = require("nui.popup")
local Menu = require("nui.menu")
local Todoist = require("todoist.todoist")
local State = require("todoist.state")
local NuiTree = require("nui.tree")
local Input = require("nui.input")

local function inputComponent()
  local popup_options = {
    position = "50%",
    zindex = 1000,
    size = {
      width = 100,
    },
    border = {
      style = "rounded",
      text = {
        top = "[New Name]",
        top_align = "center",
      },
    }
  }
  local input = Input(popup_options, {
    default_value = "New Task",
    on_close = function()
      print("CLOSED")
    end,
    on_submit = function(item)
      print("SUBMITTED", vim.inspect(item))
    end,
  })
  return input
end

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

local function tasksComponent(state, input, onChange)
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
      print("CLOSED")
    end,
    on_submit = function(item)
      print("SUBMITTED", vim.inspect(item))
    end,
    on_change = onChange,
  })
  menu:map("n", "r", function()
    if state.menu ~= "overdue" or state.selectedTask == nil then
      return
    end
  end, { nowait = true, noremap = true })
  menu:map("n", "e", function()
    if state.selectedTask == nil then
      return
    end
    input._.default_value = state.selectedTask.text
    input:mount()
  end, { nowait = true, noremap = true })
  return menu
end

local function updateStatus(status, text)
  vim.api.nvim_buf_set_lines(status.bufnr, 0, -1, false, { text })
end

local function prepareOnMenuChange(state, todoist, status, tasks)
  return function(item, menu)
    updateStatus(status, state:repr())
    local filter = item.text == "Today" and "today" or "overdue"
    state.menu = filter
    state.selectedTask = nil
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
    updateStatus(status, state:repr())
  end
end

local function prepareOnTaskChange(state, status)
  return function(item, menu)
    state.selectedTask = item
    vim.api.nvim_buf_set_lines(status.bufnr, 0, -1, false, {state:repr()})
  end
end

local function initUI(todoist)
  local state = State.init()
  local input = inputComponent()
  local status = statusComponent()
  local tasks = tasksComponent(state, input, prepareOnTaskChange(state, status))
  local menu = menuComponent(prepareOnMenuChange(state, todoist, status, tasks))
  tasks:map("n", " ", function()
    if state.selectedTask == nil then
      return
    end
    updateStatus(status, state:repr())
  end, { nowait = true, noremap = true })
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


local M = {}

function M.main()
  local todoist = Todoist.initTodoist()
  if todoist == nil then
    print("Failed to initialize Todoist")
    return
  end
  local ui = initUI(todoist)
  ui.layout:mount()
end

return M
