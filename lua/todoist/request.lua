local M = {}

local function is_success(response)
  return response.status >= 200 and response.status < 300
end

M.is_success = is_success

return M
