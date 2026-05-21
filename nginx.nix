{ config, pkgs, ... }:

{
  sops.secrets = {
    "cloudflare_api_token" = {
      owner = config.users.users.acme.name;
    };
    "acme_email" = {
      owner = config.users.users.acme.name;
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "placeholder@mesh.com";
      # environmentFile is no longer strictly needed if using credentialFiles
    };
    certs = {
      "mesh.loranjennings.com" = {
        domain = "*.mesh.loranjennings.com";
        dnsProvider = "cloudflare";

        credentialFiles = {
          "CLOUDFLARE_DNS_API_TOKEN_FILE" = config.sops.secrets."cloudflare_api_token".path;
        };

        group = "nginx";
      };
    };
  };

  services.nginx = {
    enable = true;
    virtualHosts = {
      "cloud.mesh.loranjennings.com" = {
        # Must match the string key in security.acme.certs above
        useACMEHost = "mesh.loranjennings.com";
        forceSSL = true;

        listen = [ { addr = "100.64.0.15"; port = 443; ssl = true; } ];

        locations."/" = {
          proxyPass = "http://127.0.0.1:2283";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host cloud.mesh.loranjennings.com;
            proxy_set_header X-Real-IP $remote_addr;
          '';
        };
      };
    };
  };

  # Open the port specifically on the Tailscale interface
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 443 ];
}
