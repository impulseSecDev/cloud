{
  description = "NixOS - Nextcloud & Immich";

  # Build command:
  # nix build .#nixosConfigurations.cloud314.config.system.build.nixosSystem


  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.1.0";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nixos-hardware, disko, lanzaboote, sops-nix, ... }: {
    nixosConfigurations.cloud = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        sops-nix.nixosModules.sops
        disko.nixosModules.disko
        lanzaboote.nixosModules.lanzaboote
        ./disko-config.nix
        ./networking.nix
        ./immich.nix
        ./nginx.nix
        ./fail2ban.nix
        ./wireguard.nix
        ./suricata.nix
        ./fluent-bit.nix
        ./wazuh-agent.nix

        ({ config, pkgs, lib, ... }: {
          boot.kernelPackages = pkgs.linuxPackages; 
          boot.supportedFilesystems = lib.mkForce [ "vfat" "fat32" "exfat" "ext4" "btrfs" ];

          boot.loader.systemd-boot.enable = lib.mkForce false;
          boot.loader.efi.canTouchEfiVariables = true;

          boot.lanzaboote = {
            enable = true;
            pkiBundle = "/var/lib/sbctl";
            autoGenerateKeys.enable = true;
            autoEnrollKeys = {
              enable = true;
              # Automatically reboot to enroll the keys in the firmware
              autoReboot = true;
            };
          };

          swapDevices = [{
            device = "/var/lib/swapfile";
            size = 4*1024;
          }];

          networking.hostName = "cloud";

          time.timeZone = "UTC";

          programs.neovim.enable = true;
          
          services.tailscale = {
            enable = true;
            extraUpFlags = [ "--ssh=true" "--login-server=https://tails.loranjennings.com" ];
          };

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
            settings = {
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
              PermitRootLogin = "no";
            };
          };

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
