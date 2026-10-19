{ config, pkgs, ... }: {

  sops.secrets."nextcloud_admin_password" = {
    owner = "nextcloud";
    group = "nextcloud";
    mode = "0400";
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud35;
    https = true;
    hostName = "drive.mesh.loranjennings.com";

    # Enables PostgreSQL and creates the database and role over the unix socket
    database.createLocally = true;

    config = {
      adminuser = "nextcloudadmin";
      adminpassFile = config.sops.secrets."nextcloud_admin_password".path;
      dbtype = "pgsql";
    };
  };
}
