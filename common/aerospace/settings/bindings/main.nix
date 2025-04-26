{ mod, ... }:
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


  # See: https://nikitabobko.github.io/AeroSpace/commands#layout
  "${mod}-slash" = "layout tiles horizontal vertical";
  "${mod}-comma" = "layout accordion horizontal vertical";

  cmd-h = [ ]; # Disable "hide application"
  cmd-alt-h = [ ]; # Disable "hide others"

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

  # See: https://nikitabobko.github.io/AeroSpace/commands#workspace-back-and-forth
  "${mod}-tab" = "workspace-back-and-forth";

  # See: https://nikitabobko.github.io/AeroSpace/commands#move-workspace-to-monitor
  "${mod}-shift-tab" = "move-workspace-to-monitor --wrap-around next";

  # See: https://nikitabobko.github.io/AeroSpace/commands#mode
  "${mod}-shift-semicolon" = "mode service";
}
