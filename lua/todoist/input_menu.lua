local Input = require("nui.input")

local M = {}

--- @param prompt string
--- @param on_submit function
M.init = function(prompt, on_submit)
  local popup_options = {
    position = "50%",
    zindex = 1000,
    size = {
      width = 100,
    },
    border = {
      style = "rounded",
      text = {
        top = prompt,
        top_align = "center",
      },
    }
  }
  local input = Input(popup_options, {
    default_value = "",
    on_close = function()
    end,
    on_submit = on_submit,
  })
  return input
end

return M
