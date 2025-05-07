{
  programs.git = {
    enable = true;
    userName = "Alex Jackson";
    userEmail = "git" + "@" + "ajaxbits" + "." + "com";
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
