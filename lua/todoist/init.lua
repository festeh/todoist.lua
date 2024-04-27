local Layout = require("nui.layout")
local Popup = require("nui.popup")

local function get_todoist_token()
  -- retrieve token from environment variable
  local token = os.getenv("TODOIST_API_KEY")
  if token == nil then
    print("TODOIST_API_KEY environment variable not set")
    return nil
  end
  return token
end

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
  local token = get_todoist_token()
  draw()
end


local M = {
  init = init
}


return M
