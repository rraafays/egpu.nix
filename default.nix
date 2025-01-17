{ config, ... }:

let
  amdgpuBusIdHex = "193:0:0";
  nvidiaBusIdHex = "100:0:0";
in
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    open = false;
    nvidiaSettings = true;
    modesetting.enable = true;
    forceFullCompositionPipeline = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload.enable = true;
      allowExternalGpu = true;
      amdgpuBusId = "PCI:${amdgpuBusIdHex}";
      nvidiaBusId = "PCI:${nvidiaBusIdHex}";
    };
    powerManagement = {
      enable = false;
      finegrained = false;
    };
  };
}
