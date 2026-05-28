# ============================================================
# wireguard.nix — WireGuard Module for cloud host (NixOS)
# ============================================================

{ config, lib, pkgs, ... }:

{
  # Make wireguard-tools available for debugging
  environment.systemPackages = [ pkgs.wireguard-tools ];

  sops.secrets = {
    "wg0_private_key" = {};
    "wg0_elk_allowedips" = {};
    #"wg0_elk_endpoint" = {};
    "wg0_wazuh_allowedips" = {};
    #"wg0_wazuh_endpoint" = {};
  };
  sops.templates."wg0.conf" = {
    content = ''
      [Interface]
      PrivateKey = ${config.sops.placeholder."wg0_private_key"}
      Address = 20.20.20.1/24
      ListenPort = 62088

      [Peer]
      # Wazuh VM
      PublicKey = na1tRGq7v+sZyAwPMJrYzI2MFq7z4Y8EKhWaMaB5ZB4=
      AllowedIPs = ${config.sops.placeholder."wg0_wazuh_allowedips"}
      PersistentKeepalive = 25

      [Peer]
      # Elk VM
      PublicKey = wW4FLWFhZGOyzUnnf3cFTNlcmcXgc7E7S6LobwFF3Tc=
      AllowedIPs = ${config.sops.placeholder."wg0_elk_allowedips"}
      PersistentKeepalive = 25
    '';
    path = "/run/secrets/wg0.conf";
    mode = "0400";
  };

  networking.wg-quick.interfaces = {
    wg0.configFile = config.sops.templates."wg0.conf".path;
  };

  networking.firewall = {
    checkReversePath = "loose";
    interfaces = {
      "eno1" = {
        allowedUDPPorts = [ 62088 ];
      };
    };
  };
}
