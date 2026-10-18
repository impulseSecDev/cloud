{ config, pkgs, lib, ... }:

{

  sops.secrets = {
    "nextcloud_admin_password" = {};
    "nextcloud_db_password" = {};
  };

  sops.templates."nextcloud_admin_pass_file.env" = {
    content = ''
      DB_PASSWORD=${config.sops.placeholder."nextcloud_admin_password"}
    '';
    path = "/run/secrets/nextcloud_admin_pass_file.env";
    mode = "0440";
    owner = "root";
    group = "root";
  };

  sops.templates."nextcloud_db_pass_file.env" = {
    content = ''
      DB_PASSWORD=${config.sops.placeholder."nextcloud_db_password"}
    '';
    path = "/run/secrets/nextcloud_admin_pass_file.env";
    mode = "0440";
    owner = "root";
    group = "root";
  };

  services.nextcloud = {
    enable = true;
    https = true;
    secrets = 
    config = {
      adminuser = "nextcloudadmin";
      adminpassFile = ;
      dbtype = "pgsql";
      dbuser = "nextcloud";
      dbpassFile =
  };
}


