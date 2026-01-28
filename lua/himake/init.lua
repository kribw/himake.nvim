local config = require("himake.config")
local utils = require("himake.utils")

local M = {}

-- Initialize the plugin
function M.setup(opts)
	config.setup(opts)
	
	-- Setup keybinding if specified and not already set
	local cfg = config.get_config()
	if cfg.keybind and not vim.g.himake_keybind_set then
		vim.keymap.set('n', cfg.keybind, M.pick_package, 
			{ desc = 'Pick HiMake package', silent = true })
		vim.g.himake_keybind_set = true
	end
end

-- Get current configuration (for use in plugin entry point)
function M.get_config()
	return config.get_config()
end

-- Open file picker to select .hmk package
function M.pick_package()
	-- Check if snacks.nvim is available
	local ok, snacks = pcall(require, "snacks")
	if not ok then
		vim.notify("himake.nvim requires snacks.nvim to be installed", vim.log.levels.ERROR)
		return
	end

	-- Find all .hmk files
	local hmk_files = utils.find_hmk_files()

	if #hmk_files == 0 then
		vim.notify("No .hmk files found in current working directory", vim.log.levels.WARN)
		return
	end

	-- Convert file paths to proper item format for snacks.picker
	local items = {}
	for _, file_path in ipairs(hmk_files) do
		table.insert(items, {
			text = file_path,
			file = file_path,
			path = vim.fn.fnamemodify(file_path, ":p"), -- absolute path
		})
	end

	-- Create the picker with custom items
	snacks.picker.pick({
		title = "Select HiMake Package",
		items = items,
		confirm = function(picker, item)
			if item and item.file then
				local selected_path = item.path or item.file

				-- Validate the file
				if not utils.is_valid_hmk_file(selected_path) then
					vim.notify("Invalid .hmk file: " .. selected_path, vim.log.levels.ERROR)
					return
				end

				-- Set as active package
				config.set_active_package(selected_path)

				-- Close picker
				picker:close()

				-- Show success message with relative path from cwd
				local relative_path = utils.get_relative_path(selected_path)
				vim.notify("Active HiMake package set to: " .. relative_path, vim.log.levels.INFO)
			end
		end,
		layout = {
			width = 0.8,
			height = 0.6,
			min_width = 60,
			min_height = 10,
		},
	})
end

-- Get the currently active package
function M.get_active_package()
	local package_path = config.get_active_package()

	if package_path then
		-- Return as relative path from cwd for display
		return utils.get_relative_path(package_path)
	end

	return nil
end

-- Get the absolute path of the active package
function M.get_active_package_absolute()
	return config.get_active_package()
end

-- Set active package directly (for programmatic use)
function M.set_active_package(path)
	local abs_path = vim.fn.fnamemodify(path, ":p")

	if not utils.is_valid_hmk_file(abs_path) then
		vim.notify("Invalid .hmk file: " .. path, vim.log.levels.ERROR)
		return false
	end

	config.set_active_package(abs_path)
	local relative_path = utils.get_relative_path(abs_path)
	vim.notify("Active HiMake package set to: " .. relative_path, vim.log.levels.INFO)
	return true
end

-- Clear the active package
function M.clear_active_package()
	config.clear_active_package()
	vim.notify("Active HiMake package cleared", vim.log.levels.INFO)
end

return M
