{ profile, ... }:
let
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
  programs.git = {
    enable = true;
    userName = identity.name;
    userEmail = identity.email;
    lfs.enable = true;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
    delta = {
      enable = true;
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
  };
}
