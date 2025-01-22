{ pkgs, config, ... }:

let
  USER = "raf";
  amdgpuBusIdHex = "193:0:0";
  nvidiaBusIdHex = "100:0:0";
in
{
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

  nixpkgs.overlays = [
    (self: super: {
      rescan = pkgs.writeScriptBin "rescan" ''
        #!${pkgs.stdenv.shell}
        echo 1 > /sys/bus/pci/rescan
      '';
    })
  ];
  security.sudo.extraConfig = ''
    ${USER} ALL=(ALL) NOPASSWD: ${pkgs.rescan}/bin/rescan
  '';
  environment.systemPackages = with pkgs; [
    rescan
    glxinfo
    (writeScriptBin "egpu" ''
      #! ${pkgs.bash}/bin/bash
      sudo ${pkgs.rescan}/bin/rescan
      if [ $# -eq 0 ]; then
        exec nvidia-smi
      else
        if glxinfo | grep -qi NVIDIA; then
          exec nvidia-offload "$@"
        else
          "$@"
        fi
      fi
    '')
  ];
}
