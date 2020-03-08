{ config, pkgs, lib, ... }:

let
  secrets = import /etc/nixos/secrets.nix;
in {
  imports = [
    ./hardware-configuration.nix
    ./wireguard.nix

    ../../default.nix
    
    ../../common
    ../../desktop
    ../../desktop/sway.nix

    # fallback for detection
    <nixpkgs/nixos/modules/installer/scan/not-detected.nix>
  ];

  environment.variables.NIX_PATH = lib.mkForce "/var/src";

  nixpkgs.config.allowUnfree = true;
  nix.gc.automatic = false;

  networking.useDHCP = false;
  networking.interfaces.enp4s0.useDHCP = true;
  networking.hostName = "titan";
  networking.extraHosts = ''
    172.16.0.1 airlink.local unit.local
    192.168.178.248	atom.fritz.box
  '';
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  networking.search = [ "fritz.box" "kloenk.de" ];

  # disable firewall
  networking.firewall.enable = false;


  # make autoupdates
  #system.autoUpgrade.enable = true;

  users.users.kloenk.packages = with pkgs; [
    lm_sensors
    wine                   # can we ditch it?
    spotifywm              # spotify fixed for wms
    python                 # includes python2 as dependency for vscode
    platformio             # pio command
    openocd                # pio upload for stlink
    stlink                 # stlink software
    #teamspeak_client       # team speak

    # steam
    steam
    steamcontroller    

    barrier

    minecraft
    multimc
    #ftb

    # docker controller
    docker
    virtmanager
  ];


  # docker fo
  virtualisation.docker.enable = true;

  boot.kernelParams = [ "intel_iommu=on" ];

  virtualisation.libvirtd = {
    enable = true;
    onShutdown = "shutdown";
  };

  users.users.kloenk.extraGroups = [
    "dialout"  # allowes serial connections
    "plugdev"  # allowes stlink connection
    "docker"   # docker controll group
    "libvirt"
  ];

  services.udev.packages = [ pkgs.openocd ];

  services.pcscd.enable = true;

  hardware.bluetooth.enable = true;

  # add bluetooth sink
  hardware.bluetooth.extraConfig = "
    [General]
    Enable=Source,Sink,Media,Socket
  ";
  hardware.pulseaudio.zeroconf.discovery.enable = true;

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03";
}
