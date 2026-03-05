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
    lfs.enable = true;
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
}
