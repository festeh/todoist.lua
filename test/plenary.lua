local curl = require("plenary.curl")

local function test_curl()
  local res = curl.get("https://www.google.com")
  print(res.body)
end

local function todays_tasks()
  local url = "https://api.todoist.com/rest/v2/tasks"
  local token = os.getenv("TODOIST_API_KEY")
  if not token then
    print("TODOIST_API_KEY is not set")
    return
  end
  local headers = {
    ["Authorization "] = "Bearer " .. token,
  }
  local params = {
    ["filter"] = "today",
  }
  local res = curl.get(url, { headers = headers, query = params })
  print(res.body, res.status_code)
end

local function get_overdue_tasks()
  local url = "https://api.todoist.com/rest/v2/tasks"
  local token = os.getenv("TODOIST_API_KEY")
  if not token then
    print("TODOIST_API_KEY is not set")
    return
  end
  local headers = {
    ["Authorization "] = "Bearer " .. token,
  }
  local params = {
    ["filter"] = "overdue",
  }
  local res = curl.get(url, { headers = headers, query = params })
  print(res.body, res.status_code)
end

-- todays_tasks()
get_overdue_tasks()
