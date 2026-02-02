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

	-- Setup additional keybindings
	if not vim.g.himake_keybinds_set then
		-- Build: <leader>hb
		vim.keymap.set('n', '<leader>hb', M.build,
			{ desc = 'HiMake build', silent = true })
		-- Refresh: <leader>hr
		vim.keymap.set('n', '<leader>hr', M.refresh,
			{ desc = 'HiMake refresh compilation DB', silent = true })
		-- Config: <leader>hc
		vim.keymap.set('n', '<leader>hc', M.set_build_config,
			{ desc = 'HiMake configure build options', silent = true })
		-- Status: <leader>hs
		vim.keymap.set('n', '<leader>hs', M.show_status,
			{ desc = 'HiMake show status', silent = true })
		-- Output toggle: <leader>ho
		vim.keymap.set('n', '<leader>ho', utils.toggle_output_window,
			{ desc = 'Toggle HiMake output window', silent = true })

		vim.g.himake_keybinds_set = true
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

-- Set build configuration interactively
function M.set_build_config()
	local ok, snacks = pcall(require, "snacks")
	if not ok then
		vim.notify("himake.nvim requires snacks.nvim to be installed", vim.log.levels.ERROR)
		return
	end

	local platform_val = config.get_build_platform() or '(not set)'
	local variant_val = config.get_build_variant() or '(not set)'
	local platform_variant_val = config.get_build_platform_variant() or '(not set)'
	local active_pkg = config.get_active_package()
	local package_val = active_pkg and utils.get_relative_path(active_pkg) or '(not set)'

	-- Create labels with separate flag, key, and value for triple alignment
	local labels = {
		{ id = 'package', flag = '(-g)', key = 'Active Package:', value = package_val, is_picker = true },
		{ id = 'platform', flag = '(-p)', key = 'Platform (required):', value = platform_val },
		{ id = 'platform_variant', flag = '(-pv)', key = 'Platform Variant (optional):', value = platform_variant_val },
		{ id = 'variant', flag = '(-v)', key = 'Variant (optional):', value = variant_val },
	}

	-- Find max lengths for each column
	local max_flag_len = 0
	local max_key_len = 0
	for _, item in ipairs(labels) do
		max_flag_len = math.max(max_flag_len, #item.flag)
		max_key_len = math.max(max_key_len, #item.key)
	end

	-- Build aligned options with three columns: flag, key, value
	local build_opts = {}
	for _, item in ipairs(labels) do
		local flag_padding = string.rep(' ', max_flag_len - #item.flag)
		local key_padding = string.rep(' ', max_key_len - #item.key + 2) -- +2 for visual spacing
		table.insert(build_opts, {
			id = item.id,
			text = item.flag .. flag_padding .. ' ' .. item.key .. key_padding .. item.value,
			value = item.value,
			label = item.flag .. ' ' .. item.key:gsub(':$', ''), -- Keep flag and key for input prompt
			is_picker = item.is_picker,
		})
	end

	snacks.picker.pick({
		title = "HiMake Build Configuration",
		items = build_opts,
		preview = false,
		format = function(item)
			return { { item.text } }
		end,
		confirm = function(picker, item)
			picker:close()

			-- If it's the package picker option, open the package picker
			if item.is_picker then
				M.pick_package()
				return
			end

			-- Open input for the selected option
			vim.ui.input({
				prompt = item.label .. ': ',
				default = item.value ~= '(not set)' and item.value or '',
			}, function(input)
				if input ~= nil then
					if item.id == 'platform' then
						config.set_build_platform(input ~= '' and input or nil)
					elseif item.id == 'variant' then
						config.set_build_variant(input ~= '' and input or nil)
					elseif item.id == 'platform_variant' then
						config.set_build_platform_variant(input ~= '' and input or nil)
					end

					local display_value = input ~= '' and input or '(not set)'
					vim.notify(item.label .. " set to: " .. display_value, vim.log.levels.INFO)
				end
			end)
		end,
		layout = {
			preset = 'select',
		},
	})
end

-- Show current status (active package and build configuration)
-- Opens a floating window that stays until user presses q or <Esc>
function M.show_status()
	local active_package = config.get_active_package()
	local build_cfg = config.get_build_config()

	local content = {
		"HiMake Status",
		string.rep("=", 40),
		"",
		"Active Package:     " .. (active_package and utils.get_relative_path(active_package) or "(not set)"),
		"Platform (-p):      " .. (build_cfg.platform or "(not set)"),
		"Platform Var (-pv): " .. (build_cfg.platform_variant or "(not set)"),
		"Variant (-v):       " .. (build_cfg.variant or "(not set)"),
		"",
		"Press q or <Esc> to close",
	}

	-- Calculate window size
	local width = 0
	for _, line in ipairs(content) do
		width = math.max(width, #line)
	end
	width = math.min(width + 4, 60) -- Add padding, max 60
	local height = #content + 2 -- Add padding

	-- Create buffer
	local bufnr = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)
	vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
	vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
	vim.api.nvim_buf_set_option(bufnr, 'bufhidden', 'wipe')

	-- Calculate position (center of screen)
	local win_width = vim.api.nvim_get_option('columns')
	local win_height = vim.api.nvim_get_option('lines')
	local row = math.floor((win_height - height) / 2)
	local col = math.floor((win_width - width) / 2)

	-- Open floating window
	local winid = vim.api.nvim_open_win(bufnr, true, {
		relative = 'editor',
		row = row,
		col = col,
		width = width,
		height = height,
		style = 'minimal',
		border = 'rounded',
		title = ' HiMake Status ',
		title_pos = 'center',
	})

	-- Set keymaps to close window
	local opts = { buffer = bufnr, silent = true }
	vim.keymap.set('n', 'q', function() vim.api.nvim_win_close(winid, true) end, opts)
	vim.keymap.set('n', '<Esc>', function() vim.api.nvim_win_close(winid, true) end, opts)
	vim.keymap.set('n', '<CR>', function() vim.api.nvim_win_close(winid, true) end, opts)

	-- Also close on any other key press
	vim.api.nvim_create_autocmd('BufLeave', {
		buffer = bufnr,
		callback = function()
			if vim.api.nvim_win_is_valid(winid) then
				vim.api.nvim_win_close(winid, true)
			end
		end,
		once = true,
	})
end

-- Helper function to run himake command
local function run_himake_command(cmd_desc, extra_args)
	local active_package = config.get_active_package()
	local build_cfg = config.get_build_config()

	local cmd, err = utils.build_himake_command(extra_args, build_cfg, active_package)
	if not cmd then
		vim.notify(err, vim.log.levels.ERROR)
		return
	end

	-- Clear and show output window
	utils.clear_output()
	utils.show_output_window()

	-- Add header
	utils.append_to_output("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] Running: " .. cmd_desc)
	utils.append_to_output("Command: " .. cmd)
	utils.append_to_output(string.rep("-", 50))
	utils.append_to_output("")

	-- Run command asynchronously using jobstart
	local job_id = vim.fn.jobstart(cmd, {
		on_stdout = function(_, data, _)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						utils.append_to_output(line)
					end
				end
			end
		end,
		on_stderr = function(_, data, _)
			if data then
				for _, line in ipairs(data) do
					if line ~= "" then
						utils.append_to_output("[ERROR] " .. line)
					end
				end
			end
		end,
		on_exit = function(_, exit_code, _)
			utils.append_to_output("")
			utils.append_to_output(string.rep("-", 50))
			if exit_code == 0 then
				utils.append_to_output("[SUCCESS] " .. cmd_desc .. " completed")
				vim.notify(cmd_desc .. " completed successfully", vim.log.levels.INFO)
			else
				utils.append_to_output("[FAILED] " .. cmd_desc .. " exited with code " .. exit_code)
				vim.notify(cmd_desc .. " failed with exit code " .. exit_code, vim.log.levels.ERROR)
			end
		end,
		stdout_buffered = false,
		stderr_buffered = false,
	})

	if job_id <= 0 then
		utils.append_to_output("[ERROR] Failed to start job")
		vim.notify("Failed to start " .. cmd_desc, vim.log.levels.ERROR)
	end
end

-- Build command: himake -g <pkg> -p <platform>
function M.build()
	run_himake_command("Build", nil)
end

-- Refresh command: himake -g <pkg> -p <platform> +compilation_db
function M.refresh()
	run_himake_command("Refresh compilation DB", "+compilation_db")
end

return M
