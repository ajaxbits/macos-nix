{
  lib,
  mod,
  ...
}:
let
  workspaces = {
    "0".name = "10";
    "1".name = "1";
    "2".name = "2";
    "3".name = "3";
    "4".name = "4";
    "5".name = "5";
    "6".name = "6";
    "7".name = "7";
    "8".name = "8";
    "9".name = "9";
    browser = {
      apps = [ "org.mozilla.firefox" ];
      binding = "b";
      name = "[B]rowser";
    };
    calendar = {
      name = "[C]alendar";
      binding = "c";
      apps = [ "com.flexibits.fantastical2.mac" ];
    };
    drafts = {
      name = "[D]rafts";
      binding = "d";
      apps = [ "com.agiletortoise.Drafts-OSX" ];
    };
    messages = {
      name = "[M]essages";
      binding = "m";
      apps = [ "com.apple.MobileSMS" ];
    };
    notes = {
      apps = [ "com.roam-research.desktop-app" ];
      binding = "n";
      name = "[N]otes";
    };
    slack = {
      name = "[S]lack";
      binding = "s";
      apps = [ "com.tinyspeck.slackmacgap" ];
    };
    terminal = {
      name = "[T]erminal";
      binding = "t";
      apps = [ "com.mitchellh.ghostty" ];
    };
  };

  # computations
  workspacesWithDefaultValues = builtins.mapAttrs (
    name: value: value // { binding = value.binding or name; }
  ) workspaces;

  assignWorkspace = ws: "workspace ${ws.name}";
  moveToWorkspace = ws: "move-node-to-workspace ${ws.name}";

  wsAssignments =
    with builtins;
    listToAttrs (
      map (ws: {
        name = "${mod}-${ws.binding}";
        value = assignWorkspace ws;
      }) (attrValues workspacesWithDefaultValues)
    );
  wsMoves =
    with builtins;
    listToAttrs (
      map (ws: {
        name = "${mod}-shift-${ws.binding}";
        value = moveToWorkspace ws;
      }) (attrValues workspacesWithDefaultValues)
    );

  _workspacesWithApps =
    with builtins;
    filter (name: (hasAttr "apps" workspacesWithDefaultValues.${name})) (
      attrNames workspacesWithDefaultValues
    );
  workspaceWindowDetectedCallbacks =
    ws:
    (map (app: {
      "if".app-id = app;
      run = [
        (moveToWorkspace ws)
      ];
    }) ws.apps);
in
{
  bindings = wsMoves // wsAssignments;
  onWindowDetected = lib.flatten (
    map (
      attrName: (workspaceWindowDetectedCallbacks workspacesWithDefaultValues.${attrName})
    ) _workspacesWithApps
  );
  workspace = workspacesWithDefaultValues;
}
