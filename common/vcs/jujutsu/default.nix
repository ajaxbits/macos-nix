{
  config,
  pkgs,
  lib,
  ...
}:
let
  gitCfg = config.programs.git;
  jj = lib.getExe pkgs.jujutsu;
in
{
  config.programs.jujutsu = {
    inherit (gitCfg) enable;
    settings = {
      user = {
        name = gitCfg.userName;
        email = gitCfg.userEmail;
      };
      ui = {
        command = "log-recent";
        diff-formatter = ":git";
        pager = "${pkgs.delta}/bin/delta --side-by-side";
      };
      aliases.log-recent = [
        "log"
        "-r"
        "default() & recent()"
      ];
      revset-aliases."recent()" = "committer_date(after:\"3 months ago\")";

      aliases = {
        tug = [
          "bookmark"
          "move"
          "--from"
          "closest_bookmark(@-)"
          "--to"
          "@-"
        ];
        push = [
          "git"
          "push"
          "--revisions"
          "closest_bookmark(@-)"
        ];
        c = [ "commit" ];
        ci = [
          "commit"
          "--interactive"
        ];
        e = [ "edit" ];
        i = [
          "git"
          "init"
          "--colocate"
        ];
        nb = [
          "bookmark"
          "create"
          "-r @-"
        ];
        pull = [
          "git"
          "fetch"
        ];
        r = [ "rebase" ];
        s = [ "squash" ];
        si = [
          "squash"
          "--interactive"
        ];
      };
      revset-aliases = {
        "closest_bookmark(to)" = "heads(::to & bookmarks())";
      };
      template-aliases = {
        "format_short_change_id(id)" = "id.shortest()";
        "format_timestamp(timestamp)" = "timestamp.local().format('%Y-%m-%d %I:%M%P')";
      };
    };
  };

  config.programs.fish.functions.js = ''
    ${jj} git fetch
    ${jj} new trunk()
  '';
}
