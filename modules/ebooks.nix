{
  flake.aspects.ebooks-personal.darwin =
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
