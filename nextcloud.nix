{ config, pkgs, ... }: {
  sops.secrets."nextcloud_admin_password" = {};

  sops.templates."nextcloud_admin_pass_file.env" = {
    content = ''
      ${config.sops.placeholder."nextcloud_admin_password"}
    '';
    path = "/run/secrets/nextcloud_admin_pass_file.env";
    mode = "0440";
    owner = "nextcloud";
    group = "nextcloud";
  };

  services.nextcloud = {
    enable = true;
    package = pkgs.nextcloud35;
    https = true;
    hostName = "drive.mesh.loranjennings.com";
    database.createLocally = true;
    config = {
      adminuser = "nextcloudadmin";
      adminpassFile = config.sops.templates."nextcloud_admin_pass_file.env".path;
      dbtype = "pgsql";
    };
    settings = {
      maintenance_window_start = 1;
      default_phone_region = "US";
      log_type = "systemd";
      serverid = 0;
    };
  };
}
