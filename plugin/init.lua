vim.api.nvim_create_user_command('Todoist',
  function(opts)
    for pack, _ in pairs(package.loaded) do
      if pack:match("^todoist") then
        package.loaded[pack] = nil
      end
    end
    require('todoist').main()
  end,
  { desc = "Launch Todoist app", force = true })
