local curl = require("plenary.curl")

local function getApiKey()
  local token = os.getenv("TODOIST_API_KEY")
  if token == nil then
    return nil
  end
  return token
end

local tasksUrl = "https://api.todoist.com/rest/v2/tasks"

--- @class Todoist
Todoist = {
  todayTasks = {},
  overdueTasks = {},
}

function Todoist:_getHeaders(hasJsonBody)
  local headers = {
    ["Authorization "] = "Bearer " .. self.token,
  }
  if hasJsonBody then
    headers["Content-Type"] = "application/json"
  end
  return headers
end

function Todoist:queryTasks(query, callback)
  local headers = self:_getHeaders(false)
  local res = curl.get(tasksUrl, { headers = headers, query = query, callback = callback })
  return res
end

function Todoist:rescheduleTask(taskId, newDate)
  local headers = self:_getHeaders(true)
  local body = vim.fn.json_encode({ due_string = newDate })
  local res = curl.post(tasksUrl .. "/" .. taskId, { headers = headers, body = body })
  return res
end

function Todoist:completeTask(taskId)
  local headers = self:_getHeaders(false)
  local url = tasksUrl .. "/" .. taskId .. "/close"
  local res = curl.post(url, { headers = headers })
  return res
end

local M = {}

M.init = function()
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
