{ config, ... }:

{
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
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
}
