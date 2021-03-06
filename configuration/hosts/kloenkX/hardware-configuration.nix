# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ehci_pci"
    "ahci"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/fb5e7ad0-67cd-465c-b53a-ed9c6a60f037";
    fsType = "xfs";
  };

  boot.initrd.luks.devices."cryptRoot".device =
    "/dev/disk/by-uuid/685221e0-dbeb-4d1a-bbef-990f0193c0b8";
  boot.initrd.luks.devices."cryptRoot".allowDiscards = true;

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/4de634ad-50c8-4747-b9f6-139335bb95e9";
    fsType = "xfs";
  };

  boot.initrd.luks.devices."cryptNix".device =
    "/dev/disk/by-uuid/1459400b-e15a-4fc0-87a1-d03ae5cbd337";
  boot.initrd.luks.devices."cryptNix".allowDiscards = true;

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/9f05583b-9bc4-4be3-8e1c-9bb1e7dc5240";
    fsType = "ext2";
  };

  swapDevices = [ ];

  nix.maxJobs = lib.mkDefault 4;
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
