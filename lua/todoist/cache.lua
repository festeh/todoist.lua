--- @class Cache
--- @field path string
--- @field tasks table<string, Task>
Cache = {
  tasks = {}
}
Cache.__index = Cache

Cache.add = function(self, task, persist)
  self.tasks[task.id] = task
  if persist then
    self:persist()
  end
end

Cache.add_many = function(self, tasks)
  for _, task in ipairs(tasks) do
    self:add(task, false)
  end
end

Cache.clear = function(self)
  self.tasks = {}
end

Cache.persist = function(self)
  --- save values of self.tasks to self.path
  local tasks = vim.tbl_values(self.tasks)
  local data = vim.fn.json_encode(tasks)
  vim.fn.writefile({ data }, self.path)
end

Cache.load = function(self)
  if vim.fn.filereadable(self.path) == 0 then
    return false
  end
  local data = vim.fn.readfile(self.path)
  local tasks = vim.fn.json_decode(data)
  self:clear()
  self:add_many(tasks)
  return true
end

Cache.get_filtered = function(self, filter)
  local tasks = {}
  for _, task in pairs(self.tasks) do
    if filter(task) then
      table.insert(tasks, task)
    end
  end
  return tasks
end

Cache.get_all = function(self)
  --- return values of self.tasks
  return vim.tbl_values(self.tasks)
end

Cache.delete = function(self, id)
  self.tasks[id] = nil
  self:persist()
end

local M = {}

M.init = function(path)
  local self = setmetatable({ path = path }, Cache)
  Cache.__index = Cache
  return self
end

return M
