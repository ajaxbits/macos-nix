{
  flake.aspects.ebooks-personal.darwin = _: {
    homebrew = {
      enable = true;
      casks = [ "calibre" ];
    };
  };
}
