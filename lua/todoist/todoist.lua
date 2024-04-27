local function getApiKey()
  -- retrieve token from environment variable
  local token = os.getenv("TODOIST_API_KEY")
  if token == nil then
    print("TODOIST_API_KEY environment variable not set")
    return nil
  end
  return token
end

Todoist = {
  todayTasks = {},
}
Todoist.__index = Todoist

function Todoist:queryTodayTasks()
  print("Querying today tasks")
end

local M = {}

M.init = function()
  local token = getApiKey()
  if token == nil then
    return nil
  end
  -- Return a new instance of Todoist
  return setmetatable({}, Todoist)
end

return M
