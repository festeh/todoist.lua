local Layout = require("nui.layout")
local Todoist = require("todoist.todoist")
local State = require("todoist.state")
local MainMenu = require("todoist.main_menu")
local Tasks = require("todoist.tasks_menu")
local Status = require("todoist.status")
local Data = require("todoist.data")
local Messages = require("todoist.messages")

local function init_ui(todoist)
  local state = State.init()
  local data = Data.init({ state = state, todoist = todoist })
  local status = Status.init()
  local tasks = Tasks.init({ state = state })
  local main_menu = MainMenu.init({ state = state })
  local upperRow = { Layout.Box(main_menu.ui, { size = "20%" }), Layout.Box(tasks.ui, { size = "80%" }) }

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
        Layout.Box(status.ui, { size = "15%" }),
      },
      { dir = "col" }
    )
  )
  state:add_subscriber(main_menu)
  state:add_subscriber(tasks)
  state:add_subscriber(status)
  state:add_subscriber(data)

  return { main_menu = main_menu, tasks = tasks, layout = layout, state = state }
end


local M = {}

function M.main()
  local todoist = Todoist.init()
  if todoist == nil then
    print("Failed to initialize Todoist")
    return
  end
  local ui = init_ui(todoist)
  ui.layout:mount()
  local state = ui.state
  state:notify({ type = Messages.QUERY_PROJECTS })
  state:notify({ type = Messages.QUERY_TASKS })
  state.main_window_id = ui.main_menu.ui.winid
  state.task_window_id = ui.tasks.ui.winid
end

return M
