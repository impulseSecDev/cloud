{ config, pkgs, lib, ... }:

{
  services.kasmweb = {
    enable = true;
    listenAddress = "127.0.0.1";
    listenPort = 64448;
  };

  nixpkgs.config.allowUnfree = true;
}


