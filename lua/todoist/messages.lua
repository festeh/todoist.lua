
--- @class Messages
Messages = {
  -- Task operations
  NEW_TASK = 1,
  RENAME_TASK = 2,
  DELETE_TASK = 3,
  COMPLETE_TASK = 4,
  RESCHEDULE_TASK = 5,
  -- UI operations
  TASKS_VIEW_REQUESTED = 10,
  TASKS_VIEW_LOADED = 11,
  UPDATE_STATUS = 12,
  TASKS_FOCUSED = 13,
  MAIN_MENU_FOCUSED = 14,
  -- "Global" operations
  QUERY_PROJECTS = 20,
  QUERY_TASKS = 21,
  PROJECTS_LOADED = 22,
  TASKS_LOADED = 23,
  -- Project operations
  NEW_PROJECT = 33,
}

return Messages
