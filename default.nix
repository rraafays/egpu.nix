{ pkgs, config, ... }:

let
  USER = "raf";

  egpu_pci_id = "05:00.0";
in
{
  boot = {
    kernelParams = [
      "pci=assign-busses,hpbussize=0x33,realloc,hpmemsize=128M,hpmemprefsize=1G"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];
    kernelModules = [
      "nvidia"
      "nvidia-modeset"
      "nvidia-drm"
      "nvidia-uvm"
    ];
  };
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    open = false;
    nvidiaSettings = true;
    modesetting.enable = false;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    forceFullCompositionPipeline = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      sync.enable = true;
      allowExternalGpu = true;
      nvidiaBusId = "PCI:100:0:0";
      amdgpuBusId = "PCI:193:0:0";
    };
  };

  nixpkgs.overlays = [
    (self: super: {
      dock = pkgs.writeScriptBin "dock" ''
        #!${pkgs.stdenv.shell}
        for i in $(seq 1 60); do
          echo 1 | tee /sys/bus/pci/rescan
          sleep 1
        done
      '';
    })
    (self: super: {
      undock = pkgs.writeScriptBin "undock" ''
        #!${pkgs.stdenv.shell}
        echo 1 | tee /sys/bus/pci/devices/0000:${egpu_pci_id}/remove
      '';
    })
  ];

  security.sudo = {
    extraConfig = ''
      ${USER} ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/dock
      ${USER} ALL=(ALL) NOPASSWD: /run/current-system/sw/bin/undock
    '';
  };

  environment.systemPackages = with pkgs; [
    dock
    undock
  ];
}
