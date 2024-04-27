local Layout = require("nui.layout")
local Popup = require("nui.popup")

local Todoist = require("todoist.todoist")


local function draw()
  local popup = Popup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        top = "Todoist",
        top_align = "center",
      },
    },
    -- position = "50%",
    size = {
      width = "100%",
      height = "100%",
    },
  })
  local layout = Layout(
    {
      position = "0%",
      size = {
        width = "98%",
        height = "98%",
      },
    },
    Layout.Box({ Layout.Box(popup, { size = "100%" }) })
  )
  layout:mount()
end

local function init()
  local todoist = Todoist.init()
  if todoist == nil then
    return
  end
  todoist:queryTodayTasks()
  -- draw()
end


local M = {
  init = init
}


return M
