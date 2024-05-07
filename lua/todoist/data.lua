local Messages = require('todoist/messages')
local Cache = require('todoist/cache')

--- @class Data
--- @field state State
--- @field todoist Todoist
--- @field projects table
--- @field tasks Cache
Data = {
  projects = {},
}
Data.__index = Data

local function is_success(res)
  return res.status >= 200 and res.status < 300
end

local function handle_res(res, callback, context)
  if is_success(res) then
    callback(res.body)
    vim.notify("Success: ")
  else
    vim.notify("Error: " .. context)
  end
end

local function get_cache_file(type)
  local res = nil
  if type == 'projects' then
    res = vim.fn.stdpath('data') .. '/todoist.lua/projects.json'
  elseif type == 'tasks' then
    res = vim.fn.stdpath('data') .. '/todoist.lua/tasks.json'
  end
  -- TODO: make in a cache responsibility
  if res and vim.fn.filereadable(res) == 0 then
    -- create the file if it does not exist
    -- create base directory if it does not exist
    local dir = vim.fn.fnamemodify(res, ':h')
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, 'p')
    end
  end
  return res
end

--- @function _template_query
--- @param cache Cache
function Data:_template_query(type, cache, message, extract_fn)
  if cache:load() then
    self.state:notify({ type = message, data = cache:get_all(), set_cursor = true })
  end
  self.todoist:query_all(type, vim.schedule_wrap(function(data)
    local body = data.body
    local decoded_data = vim.fn.json_decode(body)
    local saved_data = {}
    for _, item in ipairs(decoded_data) do
      table.insert(saved_data, extract_fn(item))
    end
    local cached_data = cache:get_all()
    cache:clear()
    cache:add_many(saved_data)
    self.state:notify({ type = message, data = cache:get_all() })
    local changed = false
    if #cached_data ~= #decoded_data then
      changed = true
    else
      for i, item in ipairs(data) do
        if not vim.tbl_isequal(item, cached_data[i]) then
          changed = true
          break
        end
      end
    end
    if changed then
      cache:persist()
    end
  end))
end

function Data:query_projects()
  self:_template_query("projects", self.projects, Messages.PROJECTS_LOADED, function(item)
    return {
      id = item.id,
      name = item.name,
      color = item.color,
      order = item.order,
      is_favorite = item.is_favorite
    }
  end)
end

function Data:query_tasks()
  self:_template_query("tasks", self.tasks, Messages.TASKS_LOADED, function(item)
    return {
      id = item.id,
      content = item.content,
      project_id = item.project_id,
      due = item.due,
      priority = item.priority,
      order = item.order,
    }
  end
  )
end

function Data:on_notify(message)
  if message.type == Messages.QUERY_PROJECTS then
    self:query_projects()
  end
  if message.type == Messages.QUERY_TASKS then
    self:query_tasks()
  end
  if message.type == Messages.TASKS_VIEW_REQUESTED then
    local filter = self.state:get_task_filter()
    local filtered = self.tasks:get_filtered(filter)
    self.state:notify({ type = Messages.TASKS_VIEW_LOADED, data = filtered })
  end
  if message.type == Messages.NEW_TASK then
    local ctx = self.state:new_task_context()
    local params = vim.tbl_extend('force', ctx, message.params)
    handle_res(self.todoist:new_task(params), function(data)
      local decoded_data = vim.fn.json_decode(data)
      self.tasks:add(decoded_data)
      self.state:notify({ type = Messages.TASKS_VIEW_REQUESTED })
    end, "new task")
  end
  if message.type == Messages.DELETE_TASK then
    handle_res(self.todoist:delete_task(message.id), function(data)
      self.tasks:delete(message.id)
      self.state:notify({ type = Messages.TASKS_VIEW_REQUESTED })
    end, "delete task")
  end
end

local M = {}

--- @class DataParams
--- @field state State
--- @field todoist Todoist

--- @param params DataParams
function M.init(params)
  local self = setmetatable({}, { __index = Data })
  Data.__index = Data
  self.todoist = params.todoist
  self.state = params.state
  self.tasks = Cache.init(get_cache_file('tasks'))
  self.projects = Cache.init(get_cache_file('projects'))
  return self
end

return M
