local Layout = require("nui.layout")
local Todoist = require("todoist.todoist")
local State = require("todoist.state")
local MainMenu = require("todoist.main_menu")
local Tasks = require("todoist.tasks_menu")
local Popup = require("nui.popup")

local function status_component()
  local popup_options = {
    border = {
      style = "rounded",
    },
    focusable = false,
  }
  local popup = Popup(popup_options)
  return popup
end

local function init_ui(todoist)
  local status = status_component()
  local state = State.init(status)
  local tasks = Tasks.init({ state = state, todoist = todoist })
  local main_menu = MainMenu.init({ state = state, todoist = todoist, tasks = tasks})
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
        Layout.Box(status, { size = "15%" }),
      },
      { dir = "col" }
    )
  )
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
  state.main_window_id = ui.main_menu.ui.winid
  state.task_window_id = ui.tasks.ui.winid
end

return M
