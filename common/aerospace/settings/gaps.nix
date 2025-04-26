{
  # Gaps between windows (inner-*) and between monitor edges (outer-*).
  # Possible values:
  # - Constant:     gaps.outer.top = 8
  # - Per monitor:  gaps.outer.top = [{ monitor.main = 16 }, { monitor."some-pattern" = 32 }, 24]
  #                 In this example, 24 is a default value when there is no match.
  #                 Monitor pattern is the same as for "workspace-to-monitor-force-assignment".
  #                 See: https://nikitabobko.github.io/AeroSpace/guide#assign-workspaces-to-monitors
  inner = {
    horizontal = 0;
    vertical = 0;
  };
  outer = {
    left = 0;
    bottom = 0;
    top = 0;
    right = 0;
  };
}
