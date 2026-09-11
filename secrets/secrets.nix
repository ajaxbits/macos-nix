let
  ajax = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILd+8Pi5rRPT8aLaRAd1YPeBba2zEbTST+9YtzHVugBz";
in
{
  "kagi_api_key.age".publicKeys = [ ajax ];
}
