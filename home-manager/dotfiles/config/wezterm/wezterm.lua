local wezterm = require 'wezterm'
local config = {}

-- config.front_end = "WebGpu"
config.default_prog = { 'fish' }
-- Matches COSMIC's frosted-glass window opacity: alpha of `base` in
-- ~/.config/cosmic/com.system76.CosmicTheme.Dark/v2/transparent_background (#1B1B1B8D -> 0x8D/255)
config.window_background_opacity = 0x8D / 0xFF
config.wayland_window_background_blur = true
config.window_decorations = "NONE"
config.hide_tab_bar_if_only_one_tab = true
config.color_scheme = 'Gruvbox dark, hard (base16)' -- Optional: Change the color scheme
config.font = wezterm.font("JetBrainsMono Nerd Font", {weight="Regular", stretch="Normal", style="Normal"})

-- For claude, to be able to make newlines with Shift + Enter
config.keys = {
  {key="Enter", mods="SHIFT", action=wezterm.action{SendString="\x1b\r"}},
}

return config
