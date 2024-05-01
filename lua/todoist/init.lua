local Layout = require("nui.layout")
local Popup = require("nui.popup")
local Menu = require("nui.menu")
local Todoist = require("todoist.todoist")
local State = require("todoist.state")
local Request = require("todoist.request")
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

--- @param state State
--- @param todoist Todoist
local function tasksComponent(state, todoist, taskInput, onChange)
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
  menu:map("n", "c", function()
    if state.selectedTask == nil then
      vim.notify("No task selected")
      return
    end
    local res = todoist:completeTask(state.selectedTask._id)
    if Request.is_success(res) then
      menu.tree:remove_node(state.selectedTask._id)
      menu.tree:render()
      state:setSelectedTask(nil)
    else
      vim.notify("Failed to complete task")
    end
  end, { nowait = true, noremap = true })
  menu:map("n", "r", function()
    if state.menu ~= "overdue" or state.selectedTask == nil then
      vim.notify("No task selected or wrong menu")
      return
    end
    local res = todoist:rescheduleTask(state.selectedTask._id, "today")
    if Request.is_success(res) then
      menu.tree:remove_node(state.selectedTask._id)
      menu.tree:render()
      state:setSelectedTask(nil)
    end
  end, { nowait = true, noremap = true })
  menu:map("n", "e", function()
    if state.selectedTask == nil then
      return
    end
    taskInput._.default_value = state.selectedTask.text
    taskInput:mount()
  end, { nowait = true, noremap = true })
  return menu
end


local function prepareOnMenuChange(state, todoist, tasks)
  return function(item, menu)
    local filter = item.text == "Today" and "today" or "overdue"
    state:setMenu(item.text)
    state:setSelectedTask(nil)
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

local function prepareOnTaskChange(state)
  return function(item, menu)
    state:setSelectedTask(item)
  end
end

local function initUI(todoist)
  local status = statusComponent()
  local state = State.init(status)
  local input = inputComponent()
  local tasks = tasksComponent(state, todoist, input, prepareOnTaskChange(state))
  local menu = menuComponent(prepareOnMenuChange(state, todoist, tasks))
  tasks:map("n", " ", function()
    if state.selectedTask == nil then
      return
    end
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
  local todoist = Todoist.init()
  if todoist == nil then
    print("Failed to initialize Todoist")
    return
  end
  local ui = initUI(todoist)
  ui.layout:mount()
end

return M
