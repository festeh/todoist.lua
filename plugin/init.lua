vim.api.nvim_create_user_command('Todoist',
  function(opts)
    require('todoist').main()
  end,
  { desc = "Launch Todoist app", force = true })
