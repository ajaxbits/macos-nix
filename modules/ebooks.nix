{
  flake.modules.darwin.ebooks-personal =
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
