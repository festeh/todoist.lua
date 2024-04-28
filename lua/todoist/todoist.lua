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
}
Todoist.__index = Todoist

function Todoist:queryTodayTasks(callback)
  local headers = {
    ["Authorization "] = "Bearer " .. self.token,
  }
  local params = {
    ["filter"] = "today",
  }
  local res = curl.get(tasksUrl, { headers = headers, query = params, callback = callback })
  return res
end

local M = {}

M.init = function()
  local token = getApiKey()
  if token == nil then
    print("Failed to initialize Todoist - token not set")
    return nil
  end
  -- Return a new instance of Todoist
  local todoist = setmetatable({}, Todoist)
  -- set the token
  todoist.token = token
  return todoist
end

return M
