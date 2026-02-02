local M = {}

-- Output buffer management
local output_bufnr = nil
local output_winnr = nil
local OUTPUT_BUF_NAME = '[HiMake Output]'

-- Find all .hmk files in the current working directory recursively
function M.find_hmk_files()
  local hmk_files = {}
  local cwd = vim.fn.getcwd()
  
  -- Use vim.fn.glob to find all .hmk files recursively
  local files = vim.fn.glob(cwd .. '/**/*.hmk', false, true)
  
  for _, file in ipairs(files) do
    -- Convert to relative path from cwd
    local relative_path = vim.fn.fnamemodify(file, ':.')
    table.insert(hmk_files, relative_path)
  end
  
  return hmk_files
end

-- Get relative path from current working directory
function M.get_relative_path(path)
  return vim.fn.fnamemodify(path, ':.')
end

-- Check if path exists and is a .hmk file
function M.is_valid_hmk_file(path)
  return vim.fn.filereadable(path) == 1 and path:match('%.hmk$')
end

-- Get or create output buffer
function M.get_output_buffer()
  if output_bufnr and vim.api.nvim_buf_is_valid(output_bufnr) then
    return output_bufnr
  end
  
  -- Create new buffer
  output_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(output_bufnr, OUTPUT_BUF_NAME)
  vim.api.nvim_buf_set_option(output_bufnr, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(output_bufnr, 'bufhidden', 'hide')
  vim.api.nvim_buf_set_option(output_bufnr, 'swapfile', false)
  vim.api.nvim_buf_set_option(output_bufnr, 'modifiable', false)
  
  return output_bufnr
end

-- Show output window (horizontal split at bottom)
function M.show_output_window()
  local bufnr = M.get_output_buffer()
  
  -- Check if window already exists
  if output_winnr and vim.api.nvim_win_is_valid(output_winnr) then
    vim.api.nvim_set_current_win(output_winnr)
    return output_winnr
  end
  
  -- Create horizontal split at bottom
  vim.cmd('botright 12split')
  output_winnr = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(output_winnr, bufnr)
  
  -- Set window options
  vim.api.nvim_win_set_option(output_winnr, 'number', false)
  vim.api.nvim_win_set_option(output_winnr, 'relativenumber', false)
  vim.api.nvim_win_set_option(output_winnr, 'wrap', true)
  vim.api.nvim_win_set_option(output_winnr, 'cursorline', false)
  
  return output_winnr
end

-- Hide output window
function M.hide_output_window()
  if output_winnr and vim.api.nvim_win_is_valid(output_winnr) then
    vim.api.nvim_win_close(output_winnr, false)
    output_winnr = nil
  end
end

-- Toggle output window
function M.toggle_output_window()
  if output_winnr and vim.api.nvim_win_is_valid(output_winnr) then
    M.hide_output_window()
  else
    M.show_output_window()
  end
end

-- Append text to output buffer
function M.append_to_output(text)
  local bufnr = M.get_output_buffer()
  local lines = vim.split(text, '\n', { plain = true })
  
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(bufnr, -1, -1, false, lines)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  
  -- Scroll to bottom if window is visible
  if output_winnr and vim.api.nvim_win_is_valid(output_winnr) then
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    vim.api.nvim_win_set_cursor(output_winnr, { line_count, 0 })
  end
end

-- Clear output buffer
function M.clear_output()
  local bufnr = M.get_output_buffer()
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
end

-- Build himake command string
function M.build_himake_command(base_cmd, build_config, active_package)
  if not active_package then
    return nil, "No active HiMake package selected"
  end
  
  if not build_config.platform then
    return nil, "No build platform configured (use :HiMake config or <leader>hc)"
  end
  
  local cmd_parts = {
    'himake',
    '-g', vim.fn.shellescape(active_package),
    '-p', vim.fn.shellescape(build_config.platform),
  }
  
  if build_config.variant and build_config.variant ~= '' then
    table.insert(cmd_parts, '-v')
    table.insert(cmd_parts, vim.fn.shellescape(build_config.variant))
  end
  
  if build_config.platform_variant and build_config.platform_variant ~= '' then
    table.insert(cmd_parts, '-pv')
    table.insert(cmd_parts, vim.fn.shellescape(build_config.platform_variant))
  end
  
  -- Add the base command (e.g., +compilation_db)
  if base_cmd then
    table.insert(cmd_parts, base_cmd)
  end
  
  return table.concat(cmd_parts, ' '), nil
end

return M