{ config, pkgs, lib, ... }:

{
  sops.secrets = {
    "immich_db_password" = {};
    "immich_db_username" = {};
    "immich_db_name" = {};
  };

  sops.templates."immich.env" = {
    content = ''
      DB_DATA_LOCATION=/var/lib/immich/postgres
      DB_PASSWORD=${config.sops.placeholder."immich_db_password"}
      DB_USERNAME=${config.sops.placeholder."immich_db_username"}
      DB_DATABASE_NAME=${config.sops.placeholder."immich_db_name"}
      POSTGRES_USER=${config.sops.placeholder."immich_db_username"}
      POSTGRES_PASSWORD=${config.sops.placeholder."immich_db_password"}
      POSTGRES_DB=${config.sops.placeholder."immich_db_name"}
      IMMICH_VERSION=release
      DB_HOSTNAME=database
      REDIS_HOSTNAME=redis
      TZ=UTC
    '';
    path = "/run/secrets/immich.env";
    mode = "0440";
    owner = "root";
    group = "root";
  };

  virtualisation.docker.enable = true;

  virtualisation.oci-containers = {
    backend = "docker";
    containers = {

      immich-server = {
        image = "ghcr.io/immich-app/immich-server:release";
        environmentFiles = [ config.sops.templates."immich.env".path ];
        volumes = [
          "/var/lib/immich/uploads:/data"
        ];
        ports = [ "127.0.0.1:2283:2283" ];
        dependsOn = [ "immich-redis" "immich-postgres" ];
        extraOptions = [ 
          "--health-cmd=true"
          "--network=immich-internal" 
        ];
      };

      immich-machine-learning = {
        image = "ghcr.io/immich-app/immich-machine-learning:release";
        environmentFiles = [ config.sops.templates."immich.env".path ];
        volumes = [ "model-cache:/cache" ];
        extraOptions = [
          "--health-cmd=true"
          "--network=immich-internal"
          "--network-alias=immich-machine-learning"
        ];
      };

      immich-redis = {
        image = "docker.io/valkey/valkey:9@sha256:3b55fbaa0cd93cf0d9d961f405e4dfcc70efe325e2d84da207a0a8e6d8fde4f9";
        extraOptions = [
          "--health-cmd=redis-cli ping" 
          "--network=immich-internal"
          "--network-alias=redis"
        ];
      };

      immich-postgres = {
        image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
        environmentFiles = [ config.sops.templates."immich.env".path ];
        volumes = [ "/var/lib/immich/postgres:/var/lib/postgresql/data" ];
        extraOptions = [
          "--shm-size=128mb" 
          "--network=immich-internal"
          "--network-alias=database"
        ];
      };
    };
  };

  # Create required directories
  systemd.tmpfiles.rules = [
    "d /var/lib/immich/uploads 0755 root root -"
    "d /var/lib/immich/postgres 0755 root root -"
  ];
}
