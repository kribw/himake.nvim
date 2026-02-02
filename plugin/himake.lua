-- Plugin entry point for lazy loading

-- Subcommand dispatch table
local subcommands = {
	build = function()
		require("himake").build()
	end,
	refresh = function()
		require("himake").refresh()
	end,
	config = function()
		require("himake").set_build_config()
	end,
	status = function()
		require("himake").show_status()
	end,
	pick = function()
		require("himake").pick_package()
	end,
}

-- Main HiMake command with subcommand completion
vim.api.nvim_create_user_command("HiMake", function(opts)
	local subcmd = opts.fargs[1]

	if not subcmd then
		vim.notify("Usage: HiMake <subcommand>\nAvailable: build, refresh, config, status, pick", vim.log.levels.WARN)
		return
	end

	local cmd_func = subcommands[subcmd]
	if cmd_func then
		cmd_func()
	else
		vim.notify(
			"Unknown HiMake subcommand: " .. subcmd .. "\nAvailable: build, refresh, config, status, pick",
			vim.log.levels.ERROR
		)
	end
end, {
	nargs = "?",
	complete = function(_, line)
		local cmd = vim.split(line, "%s+")
		if #cmd == 2 then
			return vim.tbl_keys(subcommands)
		end
	end,
	desc = "HiMake commands: build, refresh, config, status, pick",
})

-- Keep the legacy HiMakePicker command for backward compatibility
vim.api.nvim_create_user_command("HiMakePicker", function()
	require("himake").pick_package()
end, { desc = "Pick HiMake package (alias for :HiMake pick)" })
