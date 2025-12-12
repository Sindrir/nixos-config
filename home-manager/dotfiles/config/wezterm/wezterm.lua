local wezterm = require 'wezterm'
local config = {}

-- config.front_end = "WebGpu"
config.default_prog = { 'fish' }
config.window_background_opacity = 0.8
config.window_decorations = "NONE"
config.hide_tab_bar_if_only_one_tab = true
config.color_scheme = 'Gruvbox dark, hard (base16)' -- Optional: Change the color scheme
config.font = wezterm.font("JetBrainsMono Nerd Font", {weight="Regular", stretch="Normal", style="Normal"})

-- For claude, to be able to make newlines with Shift + Enter
config.keys = {
  {key="Enter", mods="SHIFT", action=wezterm.action{SendString="\x1b\r"}},
}

return config
