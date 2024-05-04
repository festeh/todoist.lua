local Popup = require("nui.popup")
local Messages = require("todoist.messages")

--- @class Status
--- @field ui NuiPopup
Status = {}

local M = {}

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

function Status:on_notify(message)
  if message.type == Messages.UPDATE_STATUS then
    vim.api.nvim_buf_set_lines(self.ui.bufnr, 0, -1, false, { message.status })
  end
end

function M.init()
  local self = setmetatable({}, { __index = Status })
  Status.__index = Status
  self.ui = status_component()
  return self
end

return M
