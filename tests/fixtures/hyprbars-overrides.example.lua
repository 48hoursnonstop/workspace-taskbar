-- Copy to:
-- ~/.config/workspace-taskbar/hyprbars-overrides.lua
--
-- This rule is disabled by default. Change `enabled` and the class regexp to
-- exclude applications that should not receive an upstream Hyprbars titlebar.

hl.window_rule({
  name = "workspace-taskbar-no-hyprbar-example",
  enabled = false,
  match = { class = "^(example-class)$" },
  ["hyprbars:no_bar"] = true,
})
