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

-- Flat, focus-aware chrome (no faux-3D -- bevels didn't read on this display).
-- Uniform lighter-gray border on all four sides; focus is signalled 4Dwm-style
-- by the whole frame going bright when active and dull when unfocused.
local FRAME = {
  active = {            -- focused: light gray border, clearly present
    border = '#8a857a',
    titlebar = '#413d36',
    fg = '#e2ddd0',
  },
  inactive = {          -- unfocused: border dulls toward the desktop
    border = '#4a463f',
    titlebar = '#2b2824',
    fg = '#8a857a',
  },
}

local function frame_for(state)
  local c = FRAME[state]
  return {
    border_left_width = '0.75cell',
    border_right_width = '0.75cell',
    border_top_height = '0.4cell',
    border_bottom_height = '0.4cell',
    border_top_color = c.border,
    border_left_color = c.border,
    border_bottom_color = c.border,
    border_right_color = c.border,
    active_titlebar_bg = c.titlebar,
    inactive_titlebar_bg = c.titlebar,
    active_titlebar_fg = c.fg,
    inactive_titlebar_fg = c.fg,
    font = wezterm.font { family = 'Iosevka Nerd Font', weight = 'Bold' },
    font_size = 13.0,
  }
end

-- default (used at startup, before the first focus event)
config.window_frame = frame_for('active')

-- Recolor the frame when focus changes: bright when active, dull when not.
wezterm.on('window-focus-changed', function(window)
  local overrides = window:get_config_overrides() or {}
  overrides.window_frame = frame_for(window:is_focused() and 'active' or 'inactive')
  window:set_config_overrides(overrides)
end)

-- Tab chips: the active tab must be clearly bounded. Dark bar background so
-- inactive tabs recede; active tab is distinctly lighter with high-contrast
-- text, giving it a visible edge against the bar.
config.colors = {
  tab_bar = {
    background = '#1e1b17',                                    -- darker than any tab
    active_tab   = { bg_color = '#6e6a60', fg_color = '#f4f1e8', intensity = 'Bold' },
    inactive_tab = { bg_color = '#2b2824', fg_color = '#8a857a' },
    inactive_tab_hover = { bg_color = '#3a3630', fg_color = '#e2ddd0' },
    new_tab       = { bg_color = '#1e1b17', fg_color = '#8a857a' },
    new_tab_hover = { bg_color = '#3a3630', fg_color = '#f4f1e8' },
  },
}
-- Gap between tabs so each chip's edges are unmistakable.
config.tab_max_width = 28
config.use_fancy_tab_bar = true

-- Keep BOTH the native titlebar and the wezterm frame -- all grabbable, no
-- minimalism. (Default is TITLE|RESIZE; stated explicitly so it's not lost.)
config.window_decorations = 'TITLE|RESIZE'

-- Use WebGpu frontend for better mouse coordinate mapping
config.front_end = 'WebGpu'


-- and finally, return the configuration to wezterm
return config

