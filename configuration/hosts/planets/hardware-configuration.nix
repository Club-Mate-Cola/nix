# Do not modify this file!  It was generated by ‘nixos-generate-config’
# and may be overwritten by future invocations.  Please make changes
# to /etc/nixos/configuration.nix instead.
{ config, lib, pkgs, ... }:

{
  imports =
    [ <nixpkgs/nixos/modules/profiles/qemu-guest.nix>
    ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/a183fcb0-a395-4374-8eff-8fd9c83f2ac6";
      fsType = "xfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/37d713c6-9773-4793-b8b2-70721745b82b";
      fsType = "ext2";
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/582afbe5-74e0-4b9d-9640-c79230a3a1ca"; }
    ];

  nix.maxJobs = lib.mkDefault 8;
}
