let
  inherit (import ../workspaces.nix) lib;
  inherit (import ../workspaces.nix) workspace;
in
[
  {
    "if".app-id = "com.tinyspeck.slackmacgap";
    run = [
      (lib.moveToWorkspace workspace.slack)
    ];
  }
  {
    "if".app-id = "com.flexibits.fantastical2.mac";
    run = [ (lib.moveToWorkspace workspace.calendar) ];
  }
  {
    "if" = {
      app-id = "org.mozilla.firefox";
      window-title-regex-substring = "Picture-in-Picture";
    };
    run = [ "layout floating" ];
  }
]
