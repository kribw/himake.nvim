-- Plugin entry point for lazy loading
vim.api.nvim_create_user_command('HiMakePicker', function()
  require('himake').pick_package()
end, { desc = 'Pick HiMake package' })