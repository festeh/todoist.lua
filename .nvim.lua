require("overseer").register_template({
  name = "main",
  params = {},
  condition = {
    -- This makes the template only available in the current directory
    -- In case you :cd out later
    dir = vim.fn.getcwd(),
  },
  builder = function()
    return {
      cmd = {"echo"},
      args = {"Hello", "world"},
    }
  end,
})
