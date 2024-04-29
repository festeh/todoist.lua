local curl = require("plenary.curl")

local function getApiKey()
  -- retrieve token from environment variable
  local token = os.getenv("TODOIST_API_KEY")
  if token == nil then
    print("TODOIST_API_KEY environment variable not set")
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
  print("Token: " .. self.token)
  local headers = {
    ["Authorization "] = "Bearer " .. self.token,
  }
  local res = curl.get(tasksUrl, { headers = headers, query = query, callback = callback })
  return res
end

local M = {}

M.initTodoist = function()
  local token = getApiKey()
  if token == nil then
    print("Failed to initialize Todoist - token not set")
    return nil
  end
  -- Return a new instance of Todoist
  Todoist.__index = Todoist
  local self = setmetatable({}, Todoist)
  self.token = token

  return self
end

return M
