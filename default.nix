{ pkgs, config, ... }:

let
  USER = "raf";

  egpu_pci_id = "05:00.0";
in
{
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
  };

  hardware.nvidia = {
    open = true;
    nvidiaSettings = true;
    modesetting.enable = false;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    forceFullCompositionPipeline = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      sync.enable = true;
      allowExternalGpu = true;
      nvidiaBusId = "PCI:5:0:0";
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
      ${USER} ALL=(ALL) NOPASSWD: ${pkgs.dock}/bin/dock
      ${USER} ALL=(ALL) NOPASSWD: ${pkgs.undock}/bin/undock
    '';
  };

  environment.systemPackages = with pkgs; [
    dock
    undock
  ];
}
