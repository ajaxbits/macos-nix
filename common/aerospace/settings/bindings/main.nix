let
  inherit (import ../workspaces.nix) lib workspace;
  mod = "alt";
in
with workspace;
{
  # "main" binding mode must be always presented
  # All possible keys:
  # - Letters.        a, b, c, ..., z
  # - Numbers.        0, 1, 2, ..., 9
  # - Keypad numbers. keypad0, keypad1, keypad2, ..., keypad9
  # - F-keys.         f1, f2, ..., f20
  # - Special keys.   minus, equal, period, comma, slash, backslash, quote, semicolon, backtick,
  #                   leftSquareBracket, rightSquareBracket, space, enter, esc, backspace, tab
  # - Keypad special. keypadClear, keypadDecimalMark, keypadDivide, keypadEnter, keypadEqual,
  #                   keypadMinus, keypadMultiply, keypadPlus
  # - Arrows.         left, down, up, right

  # All possible modifiers: cmd, alt, ctrl, shift

  # See: https://nikitabobko.github.io/AeroSpace/commands#layout
  "${mod}-slash" = "layout tiles horizontal vertical";
  "${mod}-comma" = "layout accordion horizontal vertical";

  cmd-h = [ ]; # Disable "hide application"
  "cmd-${mod}-h" = [ ]; # Disable "hide others"

  # See: https://nikitabobko.github.io/AeroSpace/commands#focus
  "${mod}-h" = "focus left";
  "${mod}-j" = "focus down";
  "${mod}-k" = "focus up";
  "${mod}-l" = "focus right";

  "${mod}-f" = "fullscreen";

  # See: https://nikitabobko.github.io/AeroSpace/commands#move
  "${mod}-shift-h" = "move left";
  "${mod}-shift-j" = "move down";
  "${mod}-shift-k" = "move up";
  "${mod}-shift-l" = "move right";

  # See: https://nikitabobko.github.io/AeroSpace/commands#resize
  "${mod}-shift-minus" = "resize smart -50";
  "${mod}-shift-equal" = "resize smart +50";

  # See: https://nikitabobko.github.io/AeroSpace/commands#workspace
  "${mod}-0" = lib.assignWorkspace "0";
  "${mod}-1" = lib.assignWorkspace "1";
  "${mod}-2" = lib.assignWorkspace "2";
  "${mod}-3" = lib.assignWorkspace "3";
  "${mod}-4" = lib.assignWorkspace "4";
  "${mod}-5" = lib.assignWorkspace "5";
  "${mod}-6" = lib.assignWorkspace "6";
  "${mod}-7" = lib.assignWorkspace "7";
  "${mod}-8" = lib.assignWorkspace "8";
  "${mod}-9" = lib.assignWorkspace "9";
  "${mod}-b" = lib.assignWorkspace browser;
  "${mod}-c" = lib.assignWorkspace calendar;
  "${mod}-d" = lib.assignWorkspace drafts;
  "${mod}-m" = lib.assignWorkspace messages;
  "${mod}-s" = lib.assignWorkspace slack;
  "${mod}-t" = lib.assignWorkspace terminal; # See: https://nikitabobko.github.io/AeroSpace/commands#move-node-to-workspace

  "${mod}-shift-0" = lib.moveToWorkspace "10";
  "${mod}-shift-1" = lib.moveToWorkspace "1";
  "${mod}-shift-2" = lib.moveToWorkspace "2";
  "${mod}-shift-3" = lib.moveToWorkspace "3";
  "${mod}-shift-4" = lib.moveToWorkspace "4";
  "${mod}-shift-5" = lib.moveToWorkspace "5";
  "${mod}-shift-6" = lib.moveToWorkspace "6";
  "${mod}-shift-7" = lib.moveToWorkspace "7";
  "${mod}-shift-8" = lib.moveToWorkspace "8";
  "${mod}-shift-9" = lib.moveToWorkspace "9";
  "${mod}-shift-b" = lib.moveToWorkspace browser;
  "${mod}-shift-c" = lib.moveToWorkspace calendar;
  "${mod}-shift-d" = lib.moveToWorkspace drafts;
  "${mod}-shift-m" = lib.moveToWorkspace messages;
  "${mod}-shift-s" = lib.moveToWorkspace slack;
  "${mod}-shift-t" = lib.moveToWorkspace terminal;

  # See: https://nikitabobko.github.io/AeroSpace/commands#workspace-back-and-forth
  "${mod}-tab" = "workspace-back-and-forth";

  # See: https://nikitabobko.github.io/AeroSpace/commands#move-workspace-to-monitor
  "${mod}-shift-tab" = "move-workspace-to-monitor --wrap-around next";

  # See: https://nikitabobko.github.io/AeroSpace/commands#mode
  "${mod}-shift-semicolon" = "mode service";
}
