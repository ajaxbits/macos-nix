# Version control: git + jujutsu (homeManager aspect)
{ ... }:
let
  profile = "personal";
  identities = {
    personal = {
      name = "Alex Jackson";
      email = "git" + "@" + "ajaxbits" + "." + "com";
    };
    work = {
      name = "FIXME";
      email = "FIXME@work.example.com";
    };
  };
  identity = identities.${profile};
in
{
  flake.modules.homeManager.vcs =
    { config, pkgs, lib, ... }:
    let
      gitCfg = config.programs.git;
      jj = lib.getExe pkgs.jujutsu;
    in
    {
      programs.git = {
        enable = true;
        lfs.enable = true;
        signing.format = null; # because home.stateVersion < 25
        settings = {
          user.name = identity.name;
          user.email = identity.email;
          init.defaultBranch = "main";
          pull.rebase = false;
        };
      };

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          decorations = {
            commit-decoration-style = "bold yellow box ul";
            file-decoration-style = "none";
            file-style = "bold yellow ul";
          };
          features = "decorations";
          whitespace-error-style = "22 reverse";
        };
      };

      programs.jujutsu = {
        inherit (gitCfg) enable;
        settings = {
          user = {
            inherit (gitCfg.settings.user) name;
            inherit (gitCfg.settings.user) email;
          };
          ui = {
            command = "log-recent";
            diff-formatter = ":git";
            pager = "${pkgs.delta}/bin/delta --side-by-side";
          };
          aliases = {
            log-recent = [ "log" "-r" "default() & recent()" ];
            a = [
              "bookmark" "advance" "--to"
              "bookmark-advance-to" # this is the default behavior. Idk why it isn't working.
            ];
            push = [ "git" "push" "--revisions" "closest_bookmark(@-)" ];
            c = [ "commit" ];
            ci = [ "commit" "--interactive" ];
            d = [ "describe" ];
            e = [ "edit" ];
            i = [ "git" "init" "--colocate" ];
            nb = [ "bookmark" "create" "-r @-" ];
            pull = [ "git" "fetch" ];
            r = [ "rebase" ];
            s = [ "squash" ];
            si = [ "squash" "--interactive" ];
          };
          revset-aliases = {
            "recent()" = "committer_date(after:\"3 months ago\")";
            "closest_bookmark(to)" = "heads(::to & bookmarks())";
            "closest_pushable(to)" = ''heads(::to & ~description(exact:"") & (~empty() | merges()))'';
            "bookmark-advance-to" = "closest_pushable(@)"; # this is a special revset that `jj advance` looks at when deciding where to tug to
          };
          templates = {
            draft_commit_description = "builtin_draft_commit_description_with_diff";
            new_description = ''
              if(parents.len() > 1, join(" ",
                "Merge",
                parents.skip(1).map(|p| bookmarks_or_hash(p)).join(", "),
                "into",
                bookmarks_or_hash(parents.first()),
              ))
            '';
          };
          template-aliases = {
            "format_short_change_id(id)" = "id.shortest()";
            "format_timestamp(timestamp)" = "timestamp.local().format('%Y-%m-%d %I:%M%P')";
            "bookmarks_or_hash(c)" = ''
              coalesce(c.bookmarks().map(|b| b.name()).join(", "), c.commit_id().short())
            '';
          };
        };
      };

      programs.fish.functions.js = ''
        ${jj} git fetch
        ${jj} new trunk()
      '';
    };
}
