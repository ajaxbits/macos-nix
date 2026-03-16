let
  ajax = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILd+8Pi5rRPT8aLaRAd1YPeBba2zEbTST+9YtzHVugBz";
  workLaptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7omQh72mDWAsnJlXmcNaQOhGKfSj1xpjUVGjAQ5AdB";
in
{
  "kagi_api_key.age".publicKeys = [ ajax workLaptop ];
}
