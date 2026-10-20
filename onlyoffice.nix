{ config, pkgs, lib, ... }:

{
  sops.secrets = {
    "jwt_secret" = {};
  };

  sops.templates."onlyoffice.env" = {
    content = ''
      JWT_ENABLED=true
      JWT_SECRET=${config.sops.placeholder."jwt_secret"}
      JWT_HEADER=Authorization
      JWT_IN_BODY=true
    '';
    path = "/run/secrets/onlyoffice.env";
    mode = "0600";
    owner = "root";
    group = "root";
  };

  virtualisation.docker.enable = true;

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {

      onlyoffice = {
        image = "onlyoffice/documentserver:latest";
        environmentFiles = [ config.sops.templates."onlyoffice.env".path ];
        volumes = [
          "/var/www/onlyoffice/Data"
          "/var/log/onlyoffice"
          "/var/lib/onlyoffice/documentserver/App_Data/cache/files"
          "/var/www/onlyoffice/documentserver-example/public/files"
          "/usr/share/fonts"
        ];
        ports = [ "127.0.0.1:42995:80" ];
      };
    };
  };
}
