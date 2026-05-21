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
        useACMEHost = "mesh.loranjennings.com";
        forceSSL = true;

        listen = [ { addr = "100.64.0.15"; port = 443; ssl = true; } ];

        locations."/" = {
          proxyPass = "http://127.0.0.1:2283";
          proxyWebsockets = true;
          extraConfig = ''
            # allow large file uploads
            client_max_body_size 50000M;
            
           # disable buffering uploads to prevent OOM on reverse proxy server and make uploads twice as fast (no pause)
           proxy_request_buffering off;

            #increase body buffer size to preent limited upload speed
            client_body_buffer_size 1024k;

            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;

            location = /.well-known/immich {
              proxy_pass http://127.0.0.1:2283;
            }  
          '';
        };
      };
    };
  };

  # Open the port specifically on the Tailscale interface
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 443 ];
}
