local M = {}

-- Default configuration
M.defaults = {
  keybind = '<leader>hp',
  state_key = 'himake_active_package',
  -- Build configuration state keys
  platform_key = 'himake_build_platform',
  variant_key = 'himake_build_variant',
  platform_variant_key = 'himake_build_platform_variant',
  -- Default build values
  build_defaults = {
    platform = 'this',
    variant = 'dbc3,debug,deprecated,strict_ng',
    platform_variant = nil,
  },
}

-- Global config state
M.config = M.defaults

-- Merge user config with defaults
function M.setup(user_config)
  M.config = vim.tbl_deep_extend('force', M.defaults, user_config or {})
end

-- Get current configuration
function M.get_config()
  return M.config
end

-- Set active package in persistent storage
function M.set_active_package(path)
  vim.g[M.config.state_key] = path
end

-- Get active package from persistent storage
function M.get_active_package()
  return vim.g[M.config.state_key]
end

-- Clear active package
function M.clear_active_package()
  vim.g[M.config.state_key] = nil
end

-- Build Configuration Management
-- All stored in vim.g for persistence across sessions

function M.set_build_platform(platform)
  vim.g[M.config.platform_key] = platform
end

function M.get_build_platform()
  return vim.g[M.config.platform_key] or M.config.build_defaults.platform
end

function M.set_build_variant(variant)
  vim.g[M.config.variant_key] = variant
end

function M.get_build_variant()
  return vim.g[M.config.variant_key] or M.config.build_defaults.variant
end

function M.set_build_platform_variant(platform_variant)
  vim.g[M.config.platform_variant_key] = platform_variant
end

function M.get_build_platform_variant()
  return vim.g[M.config.platform_variant_key]
end

function M.get_build_config()
  return {
    platform = M.get_build_platform(),
    variant = M.get_build_variant(),
    platform_variant = M.get_build_platform_variant(),
  }
end

function M.clear_build_config()
  vim.g[M.config.platform_key] = nil
  vim.g[M.config.variant_key] = nil
  vim.g[M.config.platform_variant_key] = nil
end

return M