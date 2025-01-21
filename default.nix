{ pkgs, config, ... }:

let
  USER = "raf";
  amdgpuBusIdHex = "193:0:0";
  nvidiaBusIdHex = "100:0:0";
in
with pkgs;
let
  patchDesktop =
    pkg: appName: from: to:
    lib.hiPrio (
      pkgs.runCommand "$patched-desktop-entry-for-${appName}" { } ''
        ${coreutils}/bin/mkdir -p $out/share/applications
        ${gnused}/bin/sed 's#${from}#${to}#g' < ${pkg}/share/applications/${appName}.desktop > $out/share/applications/${appName}.desktop
      ''
    );
  GPUOffloadApp = pkg: desktopName: patchDesktop pkg desktopName "^Exec=" "Exec=nvidia-offload ";
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
  environment.systemPackages = [
    pkgs.rescan
    (pkgs.writeScriptBin "egpu" ''
      #! ${pkgs.bash}/bin/bash
      sudo ${pkgs.egpu}/bin/egpu
      if [ $# -eq 0 ]; then
        exec nvidia-smi
      else
        exec nvidia-offload "$@"
      fi
    '')
    (GPUOffloadApp steam "steam")
  ];
}
