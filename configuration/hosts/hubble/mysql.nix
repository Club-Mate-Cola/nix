{ pkgs, config, ... }:

{

  fileSystems."/var/lib/mysql" = {
    device = "/persist/data/mysql";
    options = [ "bind" ];
  };

  services.mysql = {
    enable = true;
    package = pkgs.mariadb;
  };

  services.mysqlBackup = { enable = true; };
}
