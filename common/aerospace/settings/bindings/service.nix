{
  esc = [
    "reload-config"
    "mode main"
  ];
  r = [
    "flatten-workspace-tree"
    "mode main"
  ]; # reset layout
  #s = ["layout sticky tiling", "mode main"] # sticky is not yet supported https://github.com/nikitabobko/AeroSpace/issues/2
  f = [
    "layout floating tiling"
    "mode main"
  ]; # Toggle between floating and tiling layout
  backspace = [
    "close-all-windows-but-current"
    "mode main"
  ];

  alt-shift-h = [
    "join-with left"
    "mode main"
  ];
  alt-shift-j = [
    "join-with down"
    "mode main"
  ];
  alt-shift-k = [
    "join-with up"
    "mode main"
  ];
  alt-shift-l = [
    "join-with right"
    "mode main"
  ];
}
