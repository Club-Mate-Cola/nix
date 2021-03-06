{ lib, ... }:

{

  fileSystems."/var/lib/gitea" = {
    device = "/persist/data/gitea";
    fsType = "none";
    options = [ "bind" ];
  };

  networking.firewall.allowedTCPPorts = [
    2222 # ssh
  ];

  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
    ip6tables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
  '';

  services.gitea = {
    enable = true;
    stateDir = "/var/lib/gitea";
    log.level = "Warn";
    appName = "Kloenk's Gitea";
    domain = "gitea.kloenk.de";
    rootUrl = "https://gitea.kloenk.de";
    httpAddress = "127.0.0.1";
    httpPort = 3000;
    cookieSecure = true;
    dump.enable = true;

    database = {
      type = "postgres";
      name = "gitea";
      user = "gitea";
      createDatabase = true;
    };

    extraConfig = ''
      [repository]
      PREFERRED_LICENSES = AGPL-3.0,GPL-3.0,GPL-2.0,LGPL-3.0,LGPL-2.1

      [server]
      START_SSH_SERVER = true
      BUILTIN_SSH_SERVER_USER = git
      SSH_LISTEN_HOST = 
      SSH_PORT = 2222
      DISABLE_ROUTER_LOG = true

      [mailer]
      ENABLED = true
      SUBJECT = %(APP_NAME)s
      HOST = localhost:587
      USER = git@kloenk.de
      SEND_AS_PLAIN_TEXT = true
      USE_SENDMAIL = false
      FROM = "Kloenks's Gitea" <gitea@kloenk.de>


      [attachment]
      ALLOWED_TYPES = */*

      [service]
      SKIP_VERIFY = true
      REGISTER_EMAIL_CONFIRM = true
      ENABLE_NOTIFY_MAIL = true
      ENABLE_CAPTCHA = false
      NO_REPLY_ADDRESS = kloenk.de
      DISABLE_REGISTRATION = true
    ''; # mailer.PASSWD = "${secrets.gitea.mailpassword}"
  };

  services.nginx.virtualHosts."gitea.kloenk.de" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:3000";
  };

  services.ferm2.extraConfig = ''
    table nat {
      chain PREROUTING {
        mod addrtype dst-type LOCAL proto tcp dport 22 REDIRECT to-ports 2222;
      }
    }
  '';

  #systemd.services.gitea.serviceConfig.AmbientCapabilities = "cap_net_bind_service";
  systemd.services.gitea.serviceConfig.SystemCallFilter = lib.mkForce
    "~@clock @cpu-emulation @debug @keyring @memlock @module @obsolete @raw-io @reboot @resources @setuid @swap";
}
