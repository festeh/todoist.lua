--- @class Cache
--- @field path string
--- @field tasks table<string, Task>
Cache = {
  tasks = {}
}
Cache.__index = Cache

Cache.add = function(self, task)
  self.tasks[task.id] = task
end

Cache.add_many = function(self, tasks)
  for _, task in ipairs(tasks) do
    self:add(task)
  end
end

Cache.clear = function(self)
  self.tasks = {}
end

Cache.persist = function(self)
  vim.fn.writefile(vim.fn.json_encode(self.tasks), self.path)
end

Cache.load = function(self)
  if vim.fn.filereadable(self.path) == 0 then
    return false
  end
  local data = vim.fn.readfile(self.path)
  self.tasks = vim.fn.json_decode(data)
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
  return self.tasks
end

local M = {}

M.init = function(path)
  local self = setmetatable({path=path}, Cache)
  Cache.__index = Cache
  return self
end

return M
