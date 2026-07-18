-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = 'deep'
config.window_background_opacity = 0.93
config.font_size = 17.0
config.font = wezterm.font 'Iosevka Nerd Font'

-- borders
config.window_frame = {
  border_left_width = '0.5cell',
  border_right_width = '0.5cell',
  border_bottom_height = '0.25cell',
  border_top_height = '0.25cell',
  border_left_color = 'gray',
  border_right_color = 'gray',
  border_bottom_color = 'gray',
  border_top_color = 'gray',
}

-- Use WebGpu frontend for better mouse coordinate mapping
config.front_end = 'WebGpu'


-- and finally, return the configuration to wezterm
return config

