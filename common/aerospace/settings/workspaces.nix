{
  workspace = {
    "0" = "10";
    "1" = "1";
    "2" = "2";
    "3" = "3";
    "4" = "4";
    "5" = "5";
    "6" = "6";
    "7" = "7";
    "8" = "8";
    "9" = "9";
    browser = "[B]rowser";
    calendar = "[C]alendar";
    drafts = "[D]rafts";
    messages = "[M]essages";
    slack = "[S]lack";
    terminal = "[T]erminal";
  };
  lib = {
    assignWorkspace = workspace: "workspace ${workspace}";
    moveToWorkspace = workspace: "move-node-to-workspace ${workspace}";
  };
}
