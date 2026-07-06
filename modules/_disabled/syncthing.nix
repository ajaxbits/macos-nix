let
  serverDeviceId = "7FFFP2F-KWDYT6S-UPRKYNA-DFVBI7R-Y3PVOC2-CLYFZIL-BI4BTEZ-OEN7UA3";
in
{
  flake.modules.homeManager.syncthing =
    { config, ... }:
    {
      age.secrets."syncthing/cert".file = ../secrets/syncthing/cert.age;
      age.secrets."syncthing/key".file = ../secrets/syncthing/key.age;

      services.syncthing = {
        enable = true;
        overrideDevices = false;
        overrideFolders = false;

        cert = config.age.secrets."syncthing/cert".path;
        key = config.age.secrets."syncthing/key".path;

        settings = {
          options.urAccepted = -1;

          devices.patroclus.id = serverDeviceId;

          folders.insensitive = {
            path = "~/syncthing/insensitive";
            devices = [ "patroclus" ];
            type = "sendreceive";
          };
        };
      };
    };
}
