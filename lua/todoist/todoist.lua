local curl = require("plenary.curl")

--- @class Todoist
--- @field token string
Todoist = {
  todayTasks = {},
  overdueTasks = {},
}

local function get_api_key()
  local token = os.getenv("TODOIST_API_KEY")
  if token == nil then
    return nil
  end
  return token
end

local TASKS_URL = "https://api.todoist.com/rest/v2/tasks"
local PROJECTS_URL = "https://api.todoist.com/rest/v2/projects"


function Todoist:_get_headers(hasJsonBody)
  local headers = {
    ["Authorization "] = "Bearer " .. self.token,
  }
  if hasJsonBody then
    headers["Content-Type"] = "application/json"
  end
  return headers
end

--- @class TaskQueryParams
--- @field project_id string | nil
--- @field filter string | nil


--- @param query TaskQueryParams
function Todoist:query_tasks(query, callback)
  local headers = self:_get_headers(false)
  local res = curl.get(TASKS_URL, { headers = headers, query = query, callback = callback })
  return res
end

--- @param id string
function Todoist:complete(id)
  local headers = self:_get_headers(false)
  local url = TASKS_URL .. "/" .. id .. "/close"
  local res = curl.post(url, { headers = headers })
  return res
end

function Todoist:new_task(params)
  local headers = self:_get_headers(true)
  local body = vim.fn.json_encode(params)
  local res = curl.post(TASKS_URL, { headers = headers, body = body })
  return res
end

--- @param id string
--- @param params table
function Todoist:update(id, params)
  local headers = self:_get_headers(true)
  local body = vim.fn.json_encode(params)
  local res = curl.post(TASKS_URL .. "/" .. id, { headers = headers, body = body })
  return res
end

function Todoist:query_projects(callback)
  local headers = self:_get_headers(false)
  local res = curl.get(PROJECTS_URL, { headers = headers, callback = callback })
  return res
end

function Todoist:delete_task(id)
  local headers = self:_get_headers(false)
  local res = curl.delete(TASKS_URL .. "/" .. id, { headers = headers })
  return res
end

local M = {}

M.init = function()
  local token = get_api_key()
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
