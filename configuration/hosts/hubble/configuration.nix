{ config, pkgs, lib, ... }:

# backupdirs:
#  - /var/vmail
#  - /var/dkim

let
  #secrets = import /etc/nixos/secrets.nix;
  netFace = "eth0";
in {
  imports = [
    ./hardware-configuration.nix
    ./wireguard.nix # TODO

    #./sshguard.nix
    ./dns.nix
    ./gitea.nix
    ./mail.nix
    ./monitoring
    ./postgres.nix
    ./quassel.nix
    ./deluge.nix
    ./engelsystem.nix
    #./netbox.nix
    #./redis.nix

    ../../default.nix
    ../../common
    ../../bgp

    # fallback for detection
    <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
  ];

  # vm connection
  services.qemuGuest.enable = true;

  # patches for systemd
  systemd.package = pkgs.systemd.overrideAttrs (old: {
  patches = old.patches or [] ++ [
    (pkgs.fetchpatch {
      url = "https://github.com/petabyteboy/systemd/commit/c9476b836d647b470e6ff4d1bf843c9cec81748a.diff";
      sha256 = "1vrkykwg05bhvk1q1k5dbxgblgvx6pci19k06npfdblsf7aycfsz";
    })
  ];
});

  environment.etc."systemd/networkd.conf".source = pkgs.writeText "networkd.conf" ''
    [Network]
    DropForeignRoutes=yes
  '';

  boot.initrd.network.enable = true;
  boot.initrd.network.ssh = {
    enable = true;
    authorizedKeys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC9fXR2sAD3q5hHURKg2of2OoZiKz9Nr2Z7qx6nfLLMwK1nie1rFhbwSRK8/6QUC+jnpTvUmItUo+etRB1XwEOc3rabDUYQ4dQ+PMtQNIc4IuKfQLHvD7ug9ebJkKYaunq6+LFn8C2Tz4vbiLcPFSVpVlLb1+yaREUrN9Yk+J48M3qvySJt9+fa6PZbTxOAgKsuurRb8tYCaQ9TzefKJvZXIVd+W2tzYV381sSBKRyAJLu/8tA+niSJ8VwHntAHzaKzv6ozP5yBW2SB7R7owGd1cnP7znEPxB9jeDBBWLonsocwFalP1RGt1WsOiIGEPhytp5RDXWgZM5sIS42iL61hMB9Yz3PaQYLuR+1XNzdGRLIKPUDh58lGdk2P5HUqPnvE/FqfzU3jkv6ebJmcGfZiEN1TPc5ar8sQkpn56hB2DnJYWICuryTm0XpzSizf9fGyLGBw3GVBlnZjzTaBf7iokGFIu+ade5AqEjX6FxlNja1ESFNKhDAdLAHFnaKJ3u0= kloenk@kloenkX"
    ];
    port = 62954;
  };
  # setup network
  boot.initrd.preLVMCommands = lib.mkBefore (''
    ip li set ens18 up
    ip addr add 51.254.249.187/32 dev ens18
    ip route add 164.132.202.254/32 dev ens18
    ip route add default via 164.132.202.254 dev ens18 && hasNetwork=1 
  '');

  networking.firewall.allowedTCPPorts = [ 9092 ];

  networking.hostName = "hubble";
  networking.dhcpcd.enable = false;
  networking.useDHCP = false;
  networking.nameservers = [ "8.8.8.8" ];
  networking.interfaces.ens18.ipv4.addresses = [ { address = "51.254.249.187"; prefixLength = 32; } ];
  networking.interfaces.ens18.ipv4.routes = [ { address = "164.132.202.254"; prefixLength = 32; } ];
  #networking.defaultGateway = { address = "164.132.202.254"; interface = "enp0s18"; };
  networking.interfaces.ens18.ipv6.addresses = [ { address = "2001:41d0:1004:1629:1337:0187::"; prefixLength = 112; } ];
  networking.interfaces.ens18.ipv6.routes = [ { address = "2001:41d0:1004:16ff:ff:ff:ff:ff"; prefixLength = 128; } ];
  #networking.defaultGateway6 = { address = "2001:41d0:1004:16ff:ff:ff:ff:ff"; interface = "ens18"; };
  networking.extraHosts = ''
    172.0.0.1 hubble.kloenk.de
  '';
  services.resolved.enable = false; # running bind

  #systemd.network.networks."ens18".name = "ens18";
  systemd.network.networks."40-ens18".routes = [
    {
      routeConfig.Gateway = "164.132.202.254";
      routeConfig.GatewayOnLink = true;
    }
  ];

  # make sure dirs exists
  system.activationScripts = {
    data-http = {
      text = ''mkdir -p /data/http/kloenk /data/http/schule;
      chown -R nginx:nginx /data/http/'';
      deps = [];
    };
  };

  services.nginx.virtualHosts."kloenk.de" = {
    enableACME = true;
    forceSSL = true;
    root = "/data/http/kloenk";
    locations."/PL".extraConfig = "return 301 https://www.dropbox.com/sh/gn1thweryxofoh3/AAC3ZW_vstHieX-9JIYIBP_ra;";
    locations."/pl".extraConfig = "return 301 https://www.dropbox.com/sh/gn1thweryxofoh3/AAC3ZW_vstHieX-9JIYIBP_ra;";
  };

  services.nginx.virtualHosts."llgcompanion.kloenk.de" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:3004/";
  };


  services.nginx.virtualHosts."schule.kloenk.de" = {
    enableACME = true;
    forceSSL = true;
    root = "/data/http/schule";
    locations."/".extraConfig = "autoindex on;";
  };

  services.nginx.virtualHosts."politics.kloenk.de" = {
    enableACME = true;
    forceSSL = true;
    root = "/data/http/schule/sw/information/";
    locations."/".extraConfig = "autoindex on;";
  };

  services.nginx.virtualHosts."fwd.kloenk.de" = {
    enableACME = true;
    forceSSL = true;
    locations = {
      "/status/lycus".extraConfig = "return 301 http://grafana.llg/d/OVH6Hfliz/lycus?refresh=10s&orgId=1;";
      "/status/pluto".extraConfig = "return 301 https://munin.kloenk.de/llg/pluto/index.html;";
      "/status/yg-adminpc".extraConfig = "return 301 http://grafana.llg/d/6cyIlJlmk/yg-adminpc?refresh=5s&orgId=1;";
      "/status/hubble".extraConfig = "return 301 https://grafana.kloenk.de;";
      "/video".extraConfig = "return 301 https://media.ccc.de/v/jh-berlin-2018-27-config_foo;";
    };
  };

  services.nginx.virtualHosts."buenentechnik.kloenk.de" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:3005/";
  };

  services.nginx.virtualHosts."buehnentechnik.kloenk.de" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:3305/";
  };

  services.nginx.virtualHosts."punkte.kloenk.de" = {
    enableACME = true;
    forceSSL = true;
  };
  
  services.nginx.virtualHosts."punkte.landratlucas.de" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:3306/";
  };

  # mosh
  programs.mosh.enable = true;
  programs.mosh.withUtempter = true;
  

  services.vnstat.enable = true;

  # enable docker
  #networking.firewall.interfaces."docker0" = {
  #  allowedTCPPortRanges = [ { from = 1; to = 65534; } ];
  #  allowedUDPPortRanges = [ { from = 1; to = 65534; } ];
  #};

  #virtualisation.docker.enable = true;
  #users.users.kloenk.extraGroups = [ "docker" ];
  #users.users.kloenk.packages = [ pkgs.docker ];

  # auto update/garbage collector
  #system.autoUpgrade.enable = true;
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 14d";

  # fix tar gz error in autoupdate
  systemd.services.nixos-upgrade.path = with pkgs; [  gnutar xz.bin gzip config.nix.package.out ];


  services.bgp = {
    enable = true;
    localAS = 65249;
    primaryIP = "2a0f:4ac0:f199::1";
    primaryIP4 = "195.39.246.49";
    default = true;
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "20.03";
}
