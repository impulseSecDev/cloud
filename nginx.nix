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
      # Default Fallback for HTTP (Port 80)
      "default-http-fallback" = {
        default = true; # Catches all traffic not matched by other virtual hosts
        listen = [ { addr = "100.64.0.15"; port = 80; } ];
        extraConfig = ''
          server_name _;
          error_page 400 401 402 403 404 405 429 497 500 =444 /;
          return 444;
        '';
      };

      # Default Fallback for HTTPS (Port 443)
      "default-https-fallback" = {
        default = true; # Catches all traffic not matched by other virtual hosts
        listen = [ { addr = "100.64.0.15"; port = 443; ssl = true; } ];
        extraConfig = ''
          server_name _;
          ssl_reject_handshake on; # Reject non-SSL attempts
          error_page 400 401 402 403 404 405 429 497 500 =444 /;
          return 444;
        '';
      };

      "cloud.mesh.loranjennings.com" = {
        useACMEHost = "mesh.loranjennings.com";
        forceSSL = true;

        listen = [ { addr = "100.64.0.15"; port = 443; ssl = true; } ];

        locations."/" = {
          proxyPass = "http://127.0.0.1:2283";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_connect_timeout 60s;   # Time to establish connection
            proxy_send_timeout 60s;     # Time waiting for client upload chunk
            proxy_read_timeout 60s;     # Time waiting for Immich response/stream data
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
          '';
        };
        locations."/.well-known/immich" = {
          proxyPass = "http://127.0.0.1:2283";
          proxyWebsockets = true;
        };
      };

      "drive.mesh.loranjennings.com" = {
        useACMEHost = "mesh.loranjennings.com";
        forceSSL = true;
        listen = [ 
          { addr = "100.64.0.15"; port = 443; ssl = true; }
          { addr = "127.0.0.1"; port = 443; ssl = true; }
        ];
      };

      "nextcloud-internal" = {
        serverName = "172.17.0.1";
        listen = [ { addr = "172.17.0.1"; port = 80; } ];
        forceSSL = false;
        enableACME = false;

        root = config.services.nginx.virtualHosts."drive.mesh.loranjennings.com".root;
        locations = config.services.nginx.virtualHosts."drive.mesh.loranjennings.com".locations;
        extraConfig = config.services.nginx.virtualHosts."drive.mesh.loranjennings.com".extraConfig;
      };

      "office.mesh.loranjennings.com" = {
        useACMEHost = "mesh.loranjennings.com";
        forceSSL = true;
        listen = [ 
          { addr = "100.64.0.15"; port = 443; ssl = true; }
          { addr = "127.0.0.1"; port = 443; ssl = true; }
        ];
        locations."/" = {
          proxyPass = "http://127.0.0.1:42995";
          proxyWebsockets = true; 
          extraConfig = ''
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Host $http_host;
          '';
        };
      };
    };
  };

  # Open the port specifically on the Tailscale interface
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 443 ];
  networking.firewall.interfaces."lo".allowedTCPPorts = [ 443 ];
  networking.firewall.interfaces."docker0".allowedTCPPorts = [ 80 ];
}
