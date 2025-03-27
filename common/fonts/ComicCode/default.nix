{ lib, pkgs, ... }:

let
  fs = lib.fileset;
  fileSet = fs.fileFilter (file: file.ext == "otf") ./.;
  src = fs.toSource fileSet;
in
pkgs.stdenv.mkDerivation {
  inherit src;

  pname = "Comic Code";
  version = "1.0";

  buildInputs = [ pkgs.fontconfig ];

  installPhase = ''
    mkdir -p $out/share/fonts
    cp -r $src/* $out/share/fonts/
    fc-cache -f $out/share/fonts
  '';

  meta = with lib; {
    description = "Comic Code font";
    license = licenses.unfree;
    platforms = platforms.all;
  };
}

