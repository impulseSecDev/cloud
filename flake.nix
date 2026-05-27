{
  description = "NixOS - Nextcloud & Immich";

  # Build command:
  # nix build .#nixosConfigurations.cloud314.config.system.build.nixosSystem


  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixos-hardware, disko, sops-nix, ... }: {
    nixosConfigurations.cloud = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
        ./disko-config.nix
        ./networking.nix
        ./immich.nix
        ./nginx.nix
        ./fail2ban.nix
        ./wireguard.nix

        ({ config, pkgs, lib, ... }: {
          boot.kernelPackages = pkgs.linuxPackages; 
          boot.supportedFilesystems = lib.mkForce [ "vfat" "fat32" "exfat" "ext4" "btrfs" ];

          boot.loader.systemd-boot.enable = true;
          boot.loader.efi.canTouchEfiVariables = true;

          swapDevices = [{
            device = "/var/lib/swapfile";
            size = 8*1024;
          }];

          networking.hostName = "cloud";

          time.timeZone = "UTC";

          programs.neovim.enable = true;
          
          services.tailscale = {
            enable = true;
            extraUpFlags = [ "--ssh=true" "--login-server=https://tails.loranjennings.com" ];
          };

          # 3. Base Service Placeholders
          # You can add the full configs for these once the Pi is online
          # services.nextcloud = {
          #   enable = true;
          #   hostName = "nextcloud.local";
          # };

          users.users.tim = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            packages = with pkgs; [
              age
              btop
              tmux
            ];
          };

          services.openssh = {
            enable = false;
            ports = [ 22 ];
            settings = {
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
              PermitRootLogin = "no";
            };
          };

          boot.initrd.network = {
            enable = true;
            ssh = {
              enable = true;
              port = 2222; # Use 2222 to distinguish from the main OS SSH
              authorizedKeys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINw1yOJY+eSj4TWgNUbM2QNR49PWyRp+6QkT3LNboWvM raspberry pi-cloud-key" # Your public key
              ];
              hostKeys = [ "/etc/secrets/initrd_ssh_host_ed25519_key" ];
              shell = "/bin/cryptsetup-askpass";
            };
          };

          # Add network drivers for the initrd to "see" the internet/LAN
          boot.initrd.availableKernelModules = [ 
            "e1000e" 
          ];

          boot.kernelParams = [ 
            # Format: ip=<client-ip>:<server-ip>:<gateway-ip>:<netmask>:<hostname>:<device>:<autoconf>
            # leave server-ip and hostname blank (::) and let the kernel pick the first interface (::::)
            "ip=192.168.1.209::192.168.1.1:255.255.255.0::::none" 
          ];

          nix.settings.trusted-users = [ "root" "tim" ];

          nix.settings.experimental-features = [ "nix-command" "flakes" ];

          sops = {
            defaultSopsFile = ./secrets/secrets.yaml;
            age.keyFile = "/var/lib/sops-nix/keys.txt";
          }; 

          system.stateVersion = "25.11";
        })
      ];
    };
  };
}
