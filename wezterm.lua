local wezterm = require("wezterm")
local config = wezterm.config_builder()
config:set_strict_mode(true)

require("appearance").apply(config)
require("graphics").apply(config)
require("status").register()

return config
