local Messages = require('todoist/messages')

--- @class Data
--- @field state State
--- @field todoist Todoist
--- @field projects table
--- @field tasks table
Data = {
  projects = {},
  tasks = {}
}

local function get_cache_file(type)
  local res = nil
  if type == 'projects' then
    res = vim.fn.stdpath('data') .. '/todoist.lua/projects.json'
  elseif type == 'tasks' then
    res = vim.fn.stdpath('data') .. '/todoist.lua/tasks.json'
  end
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

function Data:_template_query(type, message, extract_fn)
  local cache_file = get_cache_file(type)
  local cached_data = nil
  if vim.fn.filereadable(cache_file) == 1 then
    cached_data = vim.fn.json_decode(vim.fn.readfile(cache_file))
    self.state:notify({ type = message, data = cached_data, set_cursor = true })
  end
  self.todoist:query_all(type, vim.schedule_wrap(function(data)
    local body = data.body
    local decoded_data = vim.fn.json_decode(body)
    local saved_data = {}
    for _, item in ipairs(decoded_data) do
      table.insert(saved_data, extract_fn(item))
    end
    self[type] = saved_data
    self.state:notify({ type = message, data = decoded_data })
    if data then
      local changed = false
      if #data ~= #decoded_data then
        changed = true
      else
        for i, item in ipairs(data) do
          if not vim.tbl_isequal(item, decoded_data[i]) then
            changed = true
            break
          end
        end
      end
      if changed then
        vim.fn.writefile({ vim.fn.json_encode(saved_data) }, cache_file)
      end
    end
  end))
end

function Data:query_projects()
  self:_template_query('projects', Messages.PROJECTS_LOADED, function(item)
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
  self:_template_query("tasks", Messages.TASKS_LOADED, function(item)
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
    local shown_tasks = {}
    local filter = self.state:get_task_filter()
    for _, task in ipairs(self.tasks) do
      if filter(task) then
        table.insert(shown_tasks, task)
      end
    end
    self.state:notify({ type = Messages.TASKS_VIEW_LOADED, data = shown_tasks })
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
  return self
end

return M
