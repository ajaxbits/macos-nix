-- Mirrors the Ghostty keybinds in modules/terminal.nix; keep the two in sync.
rex.bind("shift+cmd+\\", "pane.split", { direction = "right" })
rex.bind("shift+cmd+-", "pane.split", { direction = "down" })

rex.bind("shift+cmd+l", "pane.focus", { direction = "right" })
rex.bind("shift+cmd+h", "pane.focus", { direction = "left" })
rex.bind("shift+cmd+k", "pane.focus", { direction = "up" })
rex.bind("shift+cmd+j", "pane.focus", { direction = "down" })

rex.bind("cmd+ctrl+l", "pane.resize", { direction = "right" })
rex.bind("cmd+ctrl+h", "pane.resize", { direction = "left" })
rex.bind("cmd+ctrl+k", "pane.resize", { direction = "up" })
rex.bind("cmd+ctrl+j", "pane.resize", { direction = "down" })
