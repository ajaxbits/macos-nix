let
  ajax = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILd+8Pi5rRPT8aLaRAd1YPeBba2zEbTST+9YtzHVugBz";
  workMac = "age1se1qgzxw74zdzhajat9fhjr2wm6yn68zsu98nfx5dpnkx9dzv6xtacm5rur4cu";
in
{
  "kagi_api_key.age".publicKeys = [
    ajax
    workMac
  ];
  "terraform_cloud_token.age".publicKeys = [
    ajax
    workMac
  ];
  "jfrog_username.age".publicKeys = [ workMac ];
  "jfrog_token.age".publicKeys = [ workMac ];
}
