{ pkgs, config, ... }:

let
  amdgpuBusIdHex = "193:0:0";
  nvidiaBusIdHex = "100:0:0";
in
{
  environment.systemPackages = [
    (pkgs.writeScriptBin "egpu" ''
      #! ${pkgs.bash}/bin/bash
      exec nvidia-offload "$@"
    '')
  ];

  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = false;
    nvidiaSettings = true;
    modesetting.enable = true;
    forceFullCompositionPipeline = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      amdgpuBusId = "PCI:${amdgpuBusIdHex}";
      nvidiaBusId = "PCI:${nvidiaBusIdHex}";
      allowExternalGpu = true;
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
    };
    powerManagement = {
      enable = false;
      finegrained = false;
    };
  };
}
