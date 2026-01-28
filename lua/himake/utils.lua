local M = {}

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

return M