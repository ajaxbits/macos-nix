{
  flake.modules.darwin.ebooks =
    {
      ...
    }:
    {
      homebrew = {
        enable = true;
        casks = [ "calibre" ];
      };
    };
}
