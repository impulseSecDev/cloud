#Networking
{ config, lib, pkgs, ... }:

{
  
   networking.networkmanager.enable = true;
   networking = {
     interfaces.eno1 = {
       useDHCP = true;
     };
   };

  systemd.services.init-immich-network = {
    description = "Create Docker network for Immich isolation";
    after = [ "network.target" "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.docker}/bin/docker network inspect immich-internal >/dev/null 2>&1 || \
      ${pkgs.docker}/bin/docker network create immich-internal
    '';
  };
}
