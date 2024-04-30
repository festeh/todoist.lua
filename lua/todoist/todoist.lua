local curl = require("plenary.curl")

local function getApiKey()
  local token = os.getenv("TODOIST_API_KEY")
  if token == nil then
    return nil
  end
  return token
end

local tasksUrl = "https://api.todoist.com/rest/v2/tasks"


Todoist = {
  todayTasks = {},
  overdueTasks = {},
}

function Todoist:queryTasks(query, callback)
  local headers = {
    ["Authorization "] = "Bearer " .. self.token,
  }
  local res = curl.get(tasksUrl, { headers = headers, query = query, callback = callback })
  return res
end

function Todoist:rescheduleTask(taskId, newDate)
  local headers = {
    ["Authorization "] = "Bearer " .. self.token,
    ["Content-Type"] = "application/json",
  }
  local body = vim.fn.json_encode({ due_string = newDate })
  local res = curl.post(tasksUrl .. "/" .. taskId, { headers = headers, body = body })
  return res
end

local M = {}

M.initTodoist = function()
  local token = getApiKey()
  if token == nil then
    print("Failed to initialize Todoist - TODOIST_API_KEY not set")
    return nil
  end
  Todoist.__index = Todoist
  local self = setmetatable({}, Todoist)
  self.token = token
  return self
end

return M
